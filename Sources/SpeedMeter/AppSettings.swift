import Foundation

enum DisplayUnit: Int, CaseIterable {
    case automatic = 0
    case megabytes = 1
    case kilobytes = 2
    case megabits = 3
    case kilobits = 4
    
    var description: String {
        switch self {
        case .automatic:
            return "Otomatik"
        case .megabytes:
            return "MB/s"
        case .kilobytes:
            return "KB/s"
        case .megabits:
            return "Mbps"
        case .kilobits:
            return "Kbps"
        }
    }
}

struct AppSettings {
    var displayUnit: DisplayUnit
    var updateInterval: TimeInterval
    var showUnits: Bool
    var autoStart: Bool
    
    static var `default`: AppSettings {
        return AppSettings(
            displayUnit: .automatic,
            updateInterval: 1.0,
            showUnits: true,
            autoStart: false
        )
    }
}
