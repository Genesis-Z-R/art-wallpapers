import SwiftUI
import AppKit

public struct DesktopPlaqueView: View {
    let item: WallpaperItem
    let settings: PlaqueSettings

    public init(item: WallpaperItem, settings: PlaqueSettings) {
        self.item = item
        self.settings = settings
    }

    // Medieval Illuminated Manuscript Palette
    private let goldLight = Color(red: 0.95, green: 0.85, blue: 0.50)
    private let goldDeep = Color(red: 0.72, green: 0.55, blue: 0.22)
    private let cinnabarRed = Color(red: 0.76, green: 0.18, blue: 0.16)
    private let lapisBlue = Color(red: 0.08, green: 0.17, blue: 0.32)

    private var goldGradient: LinearGradient {
        LinearGradient(
            colors: [goldLight, goldDeep, goldLight.opacity(0.8), goldDeep],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    public var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // MARK: - Illuminated Historiated Miniature (Left)
            ZStack {
                // Miniature background: Deep Lapis Lazuli
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [lapisBlue, Color(red: 0.05, green: 0.10, blue: 0.22)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 44, height: 44)

                // Gold leaf border around the miniature
                RoundedRectangle(cornerRadius: 4)
                    .stroke(goldGradient, lineWidth: 1.5)
                    .frame(width: 44, height: 44)

                // Tiny illuminated corner dots
                VStack {
                    HStack {
                        Circle().fill(goldLight).frame(width: 2.5, height: 2.5)
                        Spacer()
                        Circle().fill(goldLight).frame(width: 2.5, height: 2.5)
                    }
                    Spacer()
                    HStack {
                        Circle().fill(goldLight).frame(width: 2.5, height: 2.5)
                        Spacer()
                        Circle().fill(goldLight).frame(width: 2.5, height: 2.5)
                    }
                }
                .frame(width: 40, height: 40)

                // Illuminated Gothic Emblem (Fleur-de-lis / Crest)
                Text("⚜")
                    .font(.system(size: 22, weight: .regular, design: .serif))
                    .foregroundStyle(goldGradient)
                    .shadow(color: goldDeep.opacity(0.6), radius: 2, x: 0, y: 1)
            }

            // MARK: - Inscription & Rubrication (Center/Right)
            VStack(alignment: .leading, spacing: 3) {
                // 1. Rubrication Header: Museum Name with Cross Flourishes
                if settings.showMuseum {
                    HStack(spacing: 5) {
                        Text("☩")
                            .font(.system(size: 9))
                            .foregroundColor(cinnabarRed)

                        Text(item.museum.rawValue.uppercased())
                            .font(.system(size: 8.5, weight: .bold, design: .serif))
                            .tracking(1.2)
                            .foregroundColor(cinnabarRed)
                            .lineLimit(1)

                        Text("☩")
                            .font(.system(size: 9))
                            .foregroundColor(cinnabarRed)

                        if item.isFavorite {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 8))
                                .foregroundColor(cinnabarRed)
                        }
                    }
                }

                // 2. Painting Title (Gothic / Classical Serif Inscription)
                if settings.showTitle {
                    Text(item.title)
                        .font(.system(size: 13, weight: .semibold, design: .serif))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .shadow(color: Color.black.opacity(0.35), radius: 2, x: 0, y: 1)
                }

                // 3. Artist & Date Line (Italicized Script)
                HStack(spacing: 6) {
                    if settings.showArtist {
                        Text(item.artist)
                            .font(.system(size: 11, weight: .medium, design: .serif))
                            .italic()
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    if settings.showYear && !item.dateDisplay.isEmpty {
                        Text("•")
                            .font(.system(size: 9, design: .serif))
                            .foregroundColor(goldDeep)

                        Text(item.dateDisplay)
                            .font(.system(size: 10.5, weight: .regular, design: .serif))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        // Snug padding — eliminates clunky card margins
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            ZStack {
                // Ethereal translucent glass vellum
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .opacity(0.85)

                // Subtle warm antique parchment wash
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color(red: 0.98, green: 0.96, blue: 0.91).opacity(0.12))

                // Outer Illuminated Gilded Rule
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(goldGradient, lineWidth: 1.0)

                // Inner Cinnabar Inset Rule
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .stroke(cinnabarRed.opacity(0.6), lineWidth: 0.6)
                    .padding(2.5)

                // Corner Medieval Fleurons / Quatrefoils (✦)
                VStack {
                    HStack {
                        Text("✦")
                            .font(.system(size: 7))
                            .foregroundColor(goldLight)
                        Spacer()
                        Text("✦")
                            .font(.system(size: 7))
                            .foregroundColor(goldLight)
                    }
                    Spacer()
                    HStack {
                        Text("✦")
                            .font(.system(size: 7))
                            .foregroundColor(goldLight)
                        Spacer()
                        Text("✦")
                            .font(.system(size: 7))
                            .foregroundColor(goldLight)
                    }
                }
                .padding(4)
            }
        )
        .shadow(color: Color.black.opacity(0.35), radius: 10, x: 0, y: 4)
        .frame(minWidth: 260, maxWidth: 440)
    }
}
