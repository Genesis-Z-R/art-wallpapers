# Art Wallpapers for macOS

I wanted to make a native macOS app that automatically downloads and curates classical, historical wallpapers for my laptop. Art Wallpapers lives unobtrusively in your macOS menu bar, sourcing classical master paintings across premier world museum collections and applying them directly to your desktop.

Designed natively for modern macOS and Apple Silicon using Swift, SwiftUI, and MenuBarExtra.

---

## Features

### 1. Multi-Museum Classical Collections
* Automatically queries and shuffles across open-access collections from three world-renowned institutions:
  * **The Art Institute of Chicago:** Impressionist, Post-Impressionist, and American masterworks.
  * **The Metropolitan Museum of Art (The Met):** Renaissance, Dutch Golden Age, and European classical art.
  * **The Cleveland Museum of Art:** Exceptional European, Asian, and classical fine arts.
* Configurable museum rotation in Settings: enable or disable individual museums according to personal preference.
* Automatic API fallback: if any museum endpoint encounters a timeout, the app automatically fails over to another enabled museum.

### 2. Active Space Sync Daemon (Multi-Space & Full-Screen Support)
* **The Problem:** On macOS Sonoma and Sequoia, setting a desktop wallpaper programmatically only applies to the currently visible Mission Control Space. Other Desktops and full-screen application spaces remain stuck on old wallpapers, and external changes break the system "Show on all Spaces" setting.
* **The Solution:** Art Wallpapers runs a lightweight Active Space Sync Daemon listening to `NSWorkspace.activeSpaceDidChangeNotification`. The moment you swipe to another Desktop or enter/exit a full-screen app, the daemon instantly binds the active wallpaper to that space. Every space and full-screen window stays unified and synchronized with zero lag.

### 3. Desktop Museum Plaque (Illuminated Manuscript Widget)
* Displays a classical placard on your desktop showcasing the painting title, artist, date, and museum.
* **Illuminated Medieval Aesthetics:** Designed in a landscape cartouche inspired by medieval illuminated manuscripts and choir books, featuring:
  * A historiated miniature with gold-leaf borders and a gilded Fleur-de-lis on a deep lapis lazuli ground.
  * Cinnabar red rubrication headers and classical Roman serif typography.
  * Sheer translucent parchment glass with corner fleurons and delicate gold foil rules.
* **Desktop Widget Behavior:** Pinned to the desktop canvas layer (`desktopIconWindow + 1`) rather than floating over active apps. Normal windows sit over it when placed in that area, and it stays on the main desktop without following you to other spaces.
* Fully configurable: position (Bottom Right, Bottom Left, Top Right, Top Left), duration (5s, 10s, 15s, 30s, or Permanent), and toggleable fields.

### 4. Menu Bar Experience
* **Lives in your Menu Bar:** Sits quietly in the macOS menu bar with a custom monochrome gallery icon.
* **Instant Popover:** Dark-mode popover matching native macOS design guidelines.
* **Current Artwork Preview:** Displays a high-resolution preview of the active painting with title, artist, date, museum badge, and historical tags.
* **Favorites System:** Heart button on the card to favorite or unfavorite any artwork instantly.
* **Global Hotkey:** Press Control-Option-Command-W (Ctrl+Opt+Cmd+W) from anywhere on your Mac to skip to the next wallpaper immediately.
* **Direct Web Link:** Quick link opens the official museum collection page for in-depth artwork provenance and curatorial essays.
* **Live Status & Countdown:** Shows status and time remaining until the next scheduled wallpaper change.
* **Instant Actions:**
  * Next Wallpaper Now: Immediately discovers, downloads, and applies a fresh painting.
  * Browse Collection: Opens the local gallery browser.
  * Settings: Opens the configuration window.
  * Pause / Resume: Freezes automatic rotation when you want to keep the current painting.
  * Quit: Gracefully terminates the background agent.

### 5. Collection Browser & Favorites
* Filter between all downloaded artworks and your favorited collection.
* In-app search across titles, artists, styles, and museums.
* Re-apply any previous painting as your desktop wallpaper with a single click.
* Reveal local files in Finder or visit the museum web page.
* "Rotate only between favorites" mode in Settings to cycle exclusively through paintings you have favorited.

### 6. Intelligent Resolution & Storage Safety
* **Smart Resolution Matching:** Checks your Mac's screen resolution and backing scale to download optimal image widths (1080p, Display Resolution, 4K, or Best Available).
* **Non-Repeating Discovery:** Maintains a recent history exclusion set to avoid frequent repeats.
* **Zero-Interruption Fallback:** Never touches your desktop until the new painting has downloaded and passed image validation. If Wi-Fi drops, your existing wallpaper remains untouched.
* **Storage Quota & Safe Pruning:** Stored in `~/Pictures/Art Wallpapers` with configurable cache limits (e.g. keep last 1,000 images). Favorited paintings are permanently protected from cache pruning.

### 7. Custom Settings & Filters
* **Change Interval:** 15 minutes, 30 minutes, 1 hour, 3 hours, 6 hours, 12 hours, or Daily.
* **Image Fit:** Fill screen, Fit to screen, Stretch to fill, or Center.
* **Art Periods:** All periods, Renaissance (1400-1600), Baroque & Rococo (1600-1750), 18th Century, 19th Century, Impressionism & Post-Impressionism, Modern (1900-1950), or Contemporary.
* **Subjects:** Landscapes, Portraits, Mythology & Religion, Battles & History, Animals & Nature, Cityscapes, or Still Life.
* **Artist Filter:** Optional search filter for specific artists (e.g. Rembrandt, Monet, Turner, Van Gogh).
* **Public Domain Filter:** Restrict to public domain artworks (default ON).
* **Auto-Start at Login:** Toggle automatic startup using `SMAppService`.
* **System Notifications:** Optional notification when a new wallpaper is applied.

---

## Building & Running

### Option A: Build and Run
Clone the repository and build the native app bundle:
```bash
# Clone the repository
git clone https://github.com/Genesis-Z-R/art-wallpapers.git
cd art-wallpapers

# Build the release app bundle
./scripts/build_app.sh

# Launch the app directly
open "Art Wallpapers.app"
```

To install into your macOS Applications folder:
```bash
cp -R "Art Wallpapers.app" /Applications/
open "/Applications/Art Wallpapers.app"
```

### Option B: Development & Testing
```bash
# Run the verification test suite:
swift scripts/run_verification.swift

# Run Swift Package Manager tests:
swift test
```

---

## Technology Stack
* **Language & Frameworks:** Swift 6 / 5 mode, SwiftUI, AppKit (`NSWorkspace`, `NSScreen`, `NSApplication`, `NSPanel`)
* **Menu Bar:** SwiftUI `MenuBarExtra` with `.window` style
* **Data Sources:**
  * Art Institute of Chicago API (Elasticsearch + IIIF 2.0)
  * The Metropolitan Museum of Art Collection API
  * Cleveland Museum of Art Open Access API
* **Persistence:** JSON-backed local storage under `~/Library/Application Support/ArtWallpapers/` and image cache in `~/Pictures/Art Wallpapers/`
