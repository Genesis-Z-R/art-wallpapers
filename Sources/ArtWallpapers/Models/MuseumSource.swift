import Foundation

public enum MuseumSource: String, CaseIterable, Identifiable, Codable, Sendable {
    case aic = "Art Institute of Chicago"
    case met = "The Metropolitan Museum of Art"
    case cma = "Cleveland Museum of Art"

    public var id: String { rawValue }

    public var shortName: String {
        switch self {
        case .aic: return "Art Institute"
        case .met: return "The Met"
        case .cma: return "Cleveland Art"
        }
    }

    public var location: String {
        switch self {
        case .aic: return "Chicago, Illinois"
        case .met: return "New York City, NY"
        case .cma: return "Cleveland, Ohio"
        }
    }

    public var museumDescription: String {
        switch self {
        case .aic:
            return "Home to one of the world's premier collections of Impressionist, Post-Impressionist, and American masterworks."
        case .met:
            return "Over 5,000 years of global culture, featuring Dutch Golden Age masterpieces, Renaissance classics, and European fine art."
        case .cma:
            return "Celebrated internationally for its exceptional Asian and European painting collections with pristine open-access scans."
        }
    }

    public var websiteURL: URL {
        switch self {
        case .aic: return URL(string: "https://www.artic.edu")!
        case .met: return URL(string: "https://www.metmuseum.org")!
        case .cma: return URL(string: "https://www.clevelandart.org")!
        }
    }
}
