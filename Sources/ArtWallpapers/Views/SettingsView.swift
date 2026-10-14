import SwiftUI
import AppKit

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var settings: AppSettings
    @Published var keepLastString: String
    private weak var manager: WallpaperManager?

    init(manager: WallpaperManager) {
        self.manager = manager
        self.settings = manager.settings
        self.keepLastString = "\(manager.settings.keepLastCount)"
    }

    func syncToManager() {
        if let count = Int(keepLastString), count > 0 {
            settings.keepLastCount = count
        }
        manager?.updateSettings(settings)
    }

    func toggleMuseum(_ museum: MuseumSource) {
        var museums = settings.enabledMuseums
        if museums.contains(museum) {
            // Ensure at least one museum remains active
            if museums.count > 1 {
                museums.removeAll { $0 == museum }
            }
        } else {
            museums.append(museum)
        }
        settings.enabledMuseums = museums
        syncToManager()
    }

    func isMuseumEnabled(_ museum: MuseumSource) -> Bool {
        settings.enabledMuseums.contains(museum)
    }

    func chooseStorageFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose"

        if panel.runModal() == .OK, let selectedURL = panel.url {
            settings.storageLocationPath = selectedURL.path
            syncToManager()
        }
    }
}

@MainActor
public struct SettingsView: View {
    @ObservedObject var manager: WallpaperManager
    @StateObject private var viewModel: SettingsViewModel

    @MainActor
    public init(manager: WallpaperManager) {
        self.manager = manager
        _viewModel = StateObject(wrappedValue: SettingsViewModel(manager: manager))
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                // MARK: - Wallpaper Settings
                VStack(alignment: .leading, spacing: 12) {
                    Text("Wallpaper Settings")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.primary)

                    VStack(spacing: 10) {
                        HStack {
                            Text("Change interval")
                                .font(.system(size: 12))
                            Spacer()
                            Picker("", selection: $viewModel.settings.interval) {
                                ForEach(ChangeInterval.allCases) { interval in
                                    Text(interval.rawValue).tag(interval)
                                }
                            }
                            .frame(width: 160)
                        }

                        HStack {
                            Text("Image fit")
                                .font(.system(size: 12))
                            Spacer()
                            Picker("", selection: $viewModel.settings.imageFit) {
                                ForEach(ImageFitOption.allCases) { fit in
                                    Text(fit.rawValue).tag(fit)
                                }
                            }
                            .frame(width: 160)
                        }

                        Toggle("Rotate only between favorites", isOn: $viewModel.settings.cycleOnlyFavorites)
                            .font(.system(size: 12))
                            .toggleStyle(.switch)
                            .onChange(of: viewModel.settings.cycleOnlyFavorites) { _ in
                                viewModel.syncToManager()
                            }

                        Toggle("Global hotkey (⌃⌥⌘W) to skip wallpaper", isOn: $viewModel.settings.enableGlobalHotkey)
                            .font(.system(size: 12))
                            .toggleStyle(.switch)
                            .onChange(of: viewModel.settings.enableGlobalHotkey) { _ in
                                viewModel.syncToManager()
                            }

                        Toggle("Auto-start at login", isOn: $viewModel.settings.autoStartAtLogin)
                            .font(.system(size: 12))
                            .toggleStyle(.switch)
                            .onChange(of: viewModel.settings.autoStartAtLogin) { newValue in
                                LaunchAtLoginService.shared.setEnabled(newValue)
                                viewModel.syncToManager()
                            }

                        Toggle("Show notifications", isOn: $viewModel.settings.showNotifications)
                            .font(.system(size: 12))
                            .toggleStyle(.switch)
                            .onChange(of: viewModel.settings.showNotifications) { newValue in
                                if newValue {
                                    NotificationService.shared.requestAuthorization()
                                }
                                viewModel.syncToManager()
                            }
                    }
                }

                Divider()

                // MARK: - Museum Collections
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Museum Collections")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.primary)

                        Text("Select the museums you want in your rotation. The app shuffles randomly between them.")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }

                    VStack(spacing: 8) {
                        ForEach(MuseumSource.allCases) { museum in
                            MuseumCardRow(
                                museum: museum,
                                isEnabled: viewModel.isMuseumEnabled(museum),
                                onToggle: {
                                    viewModel.toggleMuseum(museum)
                                }
                            )
                        }
                    }
                }

                Divider()

                // MARK: - Desktop Museum Plaque
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Desktop Museum Plaque")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.primary)

                        Text("A subtle frosted glass placard on your desktop displaying artwork information.")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }

                    VStack(spacing: 10) {
                        Toggle("Show plaque on desktop", isOn: $viewModel.settings.plaqueSettings.isEnabled)
                            .font(.system(size: 12))
                            .toggleStyle(.switch)
                            .onChange(of: viewModel.settings.plaqueSettings.isEnabled) { _ in
                                viewModel.syncToManager()
                            }

                        if viewModel.settings.plaqueSettings.isEnabled {
                            Toggle("Pin to main desktop as a widget", isOn: $viewModel.settings.plaqueSettings.stayOnMainDesktopOnly)
                                .font(.system(size: 12))
                                .toggleStyle(.switch)
                                .onChange(of: viewModel.settings.plaqueSettings.stayOnMainDesktopOnly) { _ in
                                    viewModel.syncToManager()
                                }
                            HStack {
                                Text("Plaque position")
                                    .font(.system(size: 12))
                            Spacer()
                            Picker("", selection: $viewModel.settings.plaqueSettings.position) {
                                ForEach(PlaquePosition.allCases) { pos in
                                    Text(pos.rawValue).tag(pos)
                                }
                            }
                            .frame(width: 160)
                            .onChange(of: viewModel.settings.plaqueSettings.position) { _ in
                                viewModel.syncToManager()
                            }
                        }

                        HStack {
                            Text("Display duration")
                                .font(.system(size: 12))
                            Spacer()
                            Picker("", selection: $viewModel.settings.plaqueSettings.duration) {
                                ForEach(PlaqueDuration.allCases) { dur in
                                    Text(dur.rawValue).tag(dur)
                                }
                            }
                            .frame(width: 160)
                            .onChange(of: viewModel.settings.plaqueSettings.duration) { _ in
                                viewModel.syncToManager()
                            }
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Information to show:")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.secondary)

                            HStack(spacing: 14) {
                                Toggle("Title", isOn: $viewModel.settings.plaqueSettings.showTitle)
                                    .font(.system(size: 11))
                                    .onChange(of: viewModel.settings.plaqueSettings.showTitle) { _ in viewModel.syncToManager() }

                                Toggle("Artist", isOn: $viewModel.settings.plaqueSettings.showArtist)
                                    .font(.system(size: 11))
                                    .onChange(of: viewModel.settings.plaqueSettings.showArtist) { _ in viewModel.syncToManager() }

                                Toggle("Year", isOn: $viewModel.settings.plaqueSettings.showYear)
                                    .font(.system(size: 11))
                                    .onChange(of: viewModel.settings.plaqueSettings.showYear) { _ in viewModel.syncToManager() }

                                Toggle("Museum", isOn: $viewModel.settings.plaqueSettings.showMuseum)
                                    .font(.system(size: 11))
                                    .onChange(of: viewModel.settings.plaqueSettings.showMuseum) { _ in viewModel.syncToManager() }
                            }
                        }
                        .padding(.top, 4)
                        }
                    }
                }

                Divider()

                // MARK: - Collection Filters
                VStack(alignment: .leading, spacing: 12) {
                    Text("Collection Filters")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.primary)

                    VStack(spacing: 10) {
                        HStack {
                            Text("Art periods")
                                .font(.system(size: 12))
                            Spacer()
                            Picker("", selection: $viewModel.settings.artPeriod) {
                                ForEach(ArtPeriodOption.allCases) { period in
                                    Text(period.rawValue).tag(period)
                                }
                            }
                            .frame(width: 180)
                        }

                        HStack {
                            Text("Subjects")
                                .font(.system(size: 12))
                            Spacer()
                            Picker("", selection: $viewModel.settings.subject) {
                                ForEach(SubjectOption.allCases) { subject in
                                    Text(subject.rawValue).tag(subject)
                                }
                            }
                            .frame(width: 180)
                        }

                        HStack {
                            Text("Orientation")
                                .font(.system(size: 12))
                            Spacer()
                            Picker("", selection: $viewModel.settings.orientation) {
                                ForEach(OrientationOption.allCases) { o in
                                    Text(o.rawValue).tag(o)
                                }
                            }
                            .frame(width: 180)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Artists (optional)")
                                .font(.system(size: 12))
                            TextField("e.g. Monet, Rembrandt, Turner, Van Gogh", text: $viewModel.settings.artistQuery)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 12))
                        }

                        Toggle("Only public domain artworks", isOn: $viewModel.settings.onlyPublicDomain)
                            .font(.system(size: 12))
                            .toggleStyle(.switch)
                    }
                }

                Divider()

                // MARK: - Storage & Download
                VStack(alignment: .leading, spacing: 12) {
                    Text("Storage & Download")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.primary)

                    VStack(spacing: 10) {
                        HStack {
                            Text("Max image resolution")
                                .font(.system(size: 12))
                            Spacer()
                            Picker("", selection: $viewModel.settings.maxResolution) {
                                ForEach(ResolutionOption.allCases) { res in
                                    Text(res.rawValue).tag(res)
                                }
                            }
                            .frame(width: 180)
                        }

                        HStack {
                            Text("Keep last")
                                .font(.system(size: 12))
                            Spacer()
                            HStack(spacing: 6) {
                                TextField("1000", text: $viewModel.keepLastString)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 70)
                                    .multilineTextAlignment(.center)
                                    .onChange(of: viewModel.keepLastString) { _ in
                                        viewModel.syncToManager()
                                    }
                                Text("images")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Storage location")
                                .font(.system(size: 12))

                            HStack {
                                HStack(spacing: 6) {
                                    Image(systemName: "folder")
                                        .foregroundColor(.secondary)
                                    Text(shortenedPath(viewModel.settings.storageLocationPath))
                                        .font(.system(size: 11))
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color(nsColor: .controlBackgroundColor))
                                    )

                                Button("Change...") {
                                    viewModel.chooseStorageFolder()
                                }
                                .font(.system(size: 11))
                            }
                        }
                    }
                }

                Divider()

                // MARK: - About
                VStack(alignment: .leading, spacing: 6) {
                    Text("About")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.primary)

                    Text("Art Wallpapers v1.1")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    Text("Curated masterpieces from the world's greatest open access museum collections.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            .padding(20)
        }
        .frame(width: 410, height: 620)
        .onChange(of: viewModel.settings.interval) { _ in viewModel.syncToManager() }
        .onChange(of: viewModel.settings.imageFit) { _ in viewModel.syncToManager() }
        .onChange(of: viewModel.settings.artPeriod) { _ in viewModel.syncToManager() }
        .onChange(of: viewModel.settings.subject) { _ in viewModel.syncToManager() }
        .onChange(of: viewModel.settings.orientation) { _ in viewModel.syncToManager() }
        .onChange(of: viewModel.settings.artistQuery) { _ in viewModel.syncToManager() }
        .onChange(of: viewModel.settings.onlyPublicDomain) { _ in viewModel.syncToManager() }
        .onChange(of: viewModel.settings.maxResolution) { _ in viewModel.syncToManager() }
        .background(VisualEffectView(material: .windowBackground, blendingMode: .behindWindow))
    }

    private func shortenedPath(_ fullPath: String) -> String {
        let home = NSHomeDirectory()
        if fullPath.hasPrefix(home) {
            return fullPath.replacingOccurrences(of: home, with: "~")
        }
        return fullPath
    }
}

// MARK: - Museum Card Row

private struct MuseumCardRow: View {
    let museum: MuseumSource
    let isEnabled: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: isEnabled ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16))
                    .foregroundColor(isEnabled ? .accentColor : .secondary.opacity(0.6))
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(museum.rawValue)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.primary)

                        Text("• \(museum.location)")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }

                    Text(museum.museumDescription)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(nsColor: .controlBackgroundColor).opacity(isEnabled ? 0.7 : 0.3))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isEnabled ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
