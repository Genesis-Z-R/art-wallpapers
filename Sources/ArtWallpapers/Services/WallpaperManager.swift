import Foundation
import SwiftUI
import AppKit

@MainActor
public final class WallpaperManager: ObservableObject {
    public static let shared = WallpaperManager()

    @Published public private(set) var currentWallpaper: WallpaperItem?
    @Published public private(set) var history: [WallpaperItem] = []
    @Published public var settings: AppSettings = .defaultSettings
    @Published public private(set) var isUpdating: Bool = false
    @Published public private(set) var isPaused: Bool = false
    @Published public private(set) var nextChangeDate: Date?
    @Published public private(set) var statusText: String = "Ready"
    @Published public private(set) var errorMessage: String?

    private let multiMuseumService = MultiMuseumService()
    private let downloader = IIIFImageDownloader()
    private let storage = StorageService()
    private var timerTask: Task<Void, Never>?
    private var countdownTask: Task<Void, Never>?
    private var spaceChangeObserver: (any NSObjectProtocol)?

    private init() {}

    public func start() {
        Task { [self] in
            let loadedSettings = await storage.loadSettings()
            let loadedHistory = await storage.loadHistory()

            self.settings = loadedSettings
            self.history = loadedHistory
            self.isPaused = loadedSettings.isPaused

            if let mostRecent = loadedHistory.sorted(by: { $0.lastAppliedDate > $1.lastAppliedDate }).first {
                self.currentWallpaper = mostRecent
                if loadedSettings.plaqueSettings.isEnabled && loadedSettings.plaqueSettings.duration.isPermanent {
                    DesktopPlaqueController.shared.showPlaque(for: mostRecent, settings: loadedSettings.plaqueSettings)
                }
            }

            // Setup global hotkey (⌃⌥⌘W)
            HotkeyService.shared.setup { [weak self] in
                self?.nextWallpaperNow()
            }
            HotkeyService.shared.setEnabled(loadedSettings.enableGlobalHotkey)

            // Start Active Space Sync Daemon (syncs Mission Control spaces & fullscreen apps)
            self.startSpaceSyncDaemon()

            // Request notifications authorization if enabled
            if loadedSettings.showNotifications {
                NotificationService.shared.requestAuthorization()
            }

            // If no wallpaper exists yet, fetch initial artwork
            if self.currentWallpaper == nil {
                await self.fetchAndApplyNextWallpaper(userInitiated: true)
            } else {
                self.scheduleNextChange()
            }

            self.startCountdownLoop()
        }
    }

    // MARK: - Space Sync Daemon

    private func startSpaceSyncDaemon() {
        spaceChangeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.syncActiveSpaceWallpaper()
            }
        }
    }

    public func syncActiveSpaceWallpaper() {
        guard let current = currentWallpaper else { return }
        Task {
            let fileURL = await storage.fileURL(for: current, in: settings.storageLocationPath)
            guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
            do {
                try DesktopService.shared.setDesktopWallpaper(fileURL: fileURL, fit: settings.imageFit)
            } catch {
                // Silently ignore background space sync failures
            }
        }
    }

    // MARK: - Actions

    public func nextWallpaperNow() {
        Task {
            await fetchAndApplyNextWallpaper(userInitiated: true)
        }
    }

    public func toggleFavorite(item: WallpaperItem) {
        let updated = item.togglingFavorite()
        if let index = history.firstIndex(where: { $0.id == item.id }) {
            history[index] = updated
        }
        if currentWallpaper?.id == item.id {
            currentWallpaper = updated
        }
        Task {
            await storage.saveHistory(self.history)
        }

        if settings.plaqueSettings.isEnabled {
            DesktopPlaqueController.shared.showPlaque(for: updated, settings: settings.plaqueSettings)
        }
    }

    public func togglePause() {
        isPaused.toggle()
        settings.isPaused = isPaused
        Task {
            await storage.saveSettings(settings)
        }

        if isPaused {
            timerTask?.cancel()
            timerTask = nil
            nextChangeDate = nil
            statusText = "Paused"
        } else {
            scheduleNextChange()
            updateCountdownText()
        }
    }

    public func applyExistingWallpaper(_ item: WallpaperItem) {
        Task {
            let fileURL = await storage.fileURL(for: item, in: settings.storageLocationPath)
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                self.errorMessage = "File no longer exists on disk."
                return
            }

            do {
                try DesktopService.shared.setDesktopWallpaper(fileURL: fileURL, fit: settings.imageFit)
                let updated = item.updatingLastApplied(date: Date())
                self.currentWallpaper = updated

                // Update history
                if let index = self.history.firstIndex(where: { $0.id == item.id }) {
                    self.history[index] = updated
                }
                await self.storage.saveHistory(self.history)

                // Show plaque on desktop
                DesktopPlaqueController.shared.showPlaque(for: updated, settings: self.settings.plaqueSettings)

                if self.settings.showNotifications {
                    NotificationService.shared.sendWallpaperChangedNotification(item: updated)
                }

                self.scheduleNextChange()
                self.errorMessage = nil
            } catch {
                self.errorMessage = "Failed to apply wallpaper: \(error.localizedDescription)"
            }
        }
    }

    public func deleteHistoryItem(_ item: WallpaperItem) {
        Task {
            await storage.deleteItem(item: item, storagePath: settings.storageLocationPath)
            self.history.removeAll { $0.id == item.id }
            await storage.saveHistory(self.history)
            if self.currentWallpaper?.id == item.id {
                self.currentWallpaper = self.history.first
            }
        }
    }

    public func updateSettings(_ newSettings: AppSettings) {
        let intervalChanged = self.settings.interval != newSettings.interval
        let hotkeyChanged = self.settings.enableGlobalHotkey != newSettings.enableGlobalHotkey
        let plaqueChanged = self.settings.plaqueSettings != newSettings.plaqueSettings

        self.settings = newSettings
        self.isPaused = newSettings.isPaused

        Task {
            await storage.saveSettings(newSettings)
        }

        if hotkeyChanged {
            HotkeyService.shared.setEnabled(newSettings.enableGlobalHotkey)
        }

        if plaqueChanged {
            if !newSettings.plaqueSettings.isEnabled {
                DesktopPlaqueController.shared.hidePlaque()
            } else if let current = currentWallpaper {
                DesktopPlaqueController.shared.showPlaque(for: current, settings: newSettings.plaqueSettings)
            }
        }

        if intervalChanged && !isPaused {
            scheduleNextChange()
        }
    }

    // MARK: - Core Wallpaper Engine

    public func fetchAndApplyNextWallpaper(userInitiated: Bool) async {
        guard !isUpdating else { return }
        isUpdating = true
        errorMessage = nil
        statusText = "Finding artwork..."

        defer {
            isUpdating = false
            if !isPaused {
                updateCountdownText()
            }
        }

        // Check if user enabled "Cycle only favorites"
        if settings.cycleOnlyFavorites {
            let favorites = history.filter { $0.isFavorite }
            if !favorites.isEmpty {
                let candidates = favorites.filter { $0.id != self.currentWallpaper?.id }
                let nextItem = (candidates.isEmpty ? favorites : candidates).randomElement() ?? favorites[0]
                applyExistingWallpaper(nextItem)
                return
            }
        }

        do {
            // Determine resolution target
            let mainScreen = NSScreen.main ?? NSScreen.screens.first
            let screenWidth = Int(mainScreen?.frame.width ?? 2560)
            let screenHeight = Int(mainScreen?.frame.height ?? 1664)
            let backingScale = mainScreen?.backingScaleFactor ?? 2.0

            let targetWidth = settings.maxResolution.targetWidth(
                for: screenWidth,
                screenHeight: screenHeight,
                backingScale: backingScale
            )

            // 1. Query candidate artwork from enabled museums
            statusText = "Discovering classical artwork..."
            let candidateArtwork = try await multiMuseumService.fetchRandomArtwork(
                settings: settings,
                excludingIds: Set(settings.recentlySeenIds)
            )

            // 2. Download image
            statusText = "Downloading image from \(candidateArtwork.museum.shortName)..."
            let (imageData, actualW, actualH) = try await downloader.downloadImage(
                for: candidateArtwork,
                targetWidth: targetWidth
            )

            // 3. Save to local storage
            let savedItem = try await storage.saveWallpaperImage(
                data: imageData,
                artwork: candidateArtwork,
                storagePath: settings.storageLocationPath,
                actualWidth: actualW,
                actualHeight: actualH
            )

            let localFileURL = await storage.fileURL(for: savedItem, in: settings.storageLocationPath)

            // Cache image in memory so preview renders instantly
            if let img = NSImage(data: imageData) {
                ImageCache.shared.setImage(img, for: localFileURL)
            }

            // 4. Apply to desktop
            statusText = "Applying to desktop..."
            try DesktopService.shared.setDesktopWallpaper(fileURL: localFileURL, fit: settings.imageFit)

            // 5. Update state atomically on success
            self.currentWallpaper = savedItem
            self.history.insert(savedItem, at: 0)

            // 6. Show desktop museum plaque
            DesktopPlaqueController.shared.showPlaque(for: savedItem, settings: settings.plaqueSettings)

            // Update recently seen IDs (capped to 80 items)
            var recent = settings.recentlySeenIds
            recent.append(candidateArtwork.id)
            if recent.count > 80 {
                recent.removeFirst(recent.count - 80)
            }
            settings.recentlySeenIds = recent

            // Cache pruning
            let pruned = await storage.pruneCache(
                items: self.history,
                keepLast: settings.keepLastCount,
                storagePath: settings.storageLocationPath
            )
            self.history = pruned

            // Save state
            await storage.saveHistory(self.history)
            await storage.saveSettings(settings)

            // Notify user
            if settings.showNotifications {
                NotificationService.shared.sendWallpaperChangedNotification(item: savedItem)
            }

            self.errorMessage = nil
            self.scheduleNextChange()
        } catch {
            // Keep current wallpaper untouched!
            self.errorMessage = error.localizedDescription
            self.statusText = "Update failed. Retrying soon."

            // Retry after 5 minutes
            let retryDate = Date().addingTimeInterval(5 * 60)
            self.nextChangeDate = retryDate
            self.scheduleTimer(at: retryDate)
        }
    }

    // MARK: - Scheduling & Countdown

    private func scheduleNextChange() {
        guard !isPaused else {
            nextChangeDate = nil
            statusText = "Paused"
            return
        }

        let intervalSeconds = settings.interval.seconds
        let targetDate = Date().addingTimeInterval(intervalSeconds)
        self.nextChangeDate = targetDate
        scheduleTimer(at: targetDate)
        updateCountdownText()
    }

    private func scheduleTimer(at targetDate: Date) {
        timerTask?.cancel()
        timerTask = Task { [weak self] in
            let delay = max(1, targetDate.timeIntervalSinceNow)
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard !Task.isCancelled else { return }
            await self?.fetchAndApplyNextWallpaper(userInitiated: false)
        }
    }

    private func startCountdownLoop() {
        countdownTask?.cancel()
        countdownTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 30_000_000_000) // Update countdown every 30 seconds
                self?.updateCountdownText()
            }
        }
    }

    private func updateCountdownText() {
        guard !isPaused else {
            statusText = "Paused"
            return
        }
        guard !isUpdating else { return }

        guard let next = nextChangeDate else {
            statusText = "Ready"
            return
        }

        let diff = next.timeIntervalSinceNow
        if diff <= 0 {
            statusText = "Updating soon..."
        } else {
            let minutes = Int(ceil(diff / 60))
            if minutes < 60 {
                statusText = "Next change in \(minutes) minute\(minutes == 1 ? "" : "s")"
            } else {
                let hours = Int(minutes / 60)
                let remMinutes = minutes % 60
                if remMinutes == 0 {
                    statusText = "Next change in \(hours) hour\(hours == 1 ? "" : "s")"
                } else {
                    statusText = "Next change in \(hours)h \(remMinutes)m"
                }
            }
        }
    }

    public func localImageURL(for item: WallpaperItem) async -> URL {
        await storage.fileURL(for: item, in: settings.storageLocationPath)
    }
}
