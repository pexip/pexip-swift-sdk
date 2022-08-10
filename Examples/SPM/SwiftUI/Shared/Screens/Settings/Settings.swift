import SwiftUI

final class Settings: ObservableObject {
    @Published var cameraFilter: CameraVideoFilter.Kind = .none {
        didSet {
            userDefaults?.cameraFilter = cameraFilter
        }
    }

    @Published var showLiveCaptions: Bool {
        didSet {
            userDefaults?.showLiveCaptions = showLiveCaptions
        }
    }

    @Published var isLiveCaptionsAvailable = false

    var isLiveCaptionsOn: Bool {
        showLiveCaptions && isLiveCaptionsAvailable
    }

    private var userDefaults: UserDefaults?

    // MARK: - Init

    init(userDefaults: UserDefaults = .standard) {
        cameraFilter = userDefaults.cameraFilter
        showLiveCaptions = userDefaults.showLiveCaptions
        self.userDefaults = userDefaults
    }
}

// MARK: - Storage

private extension UserDefaults {
    var cameraFilter: CameraVideoFilter.Kind {
        get {
            string(forKey: "cameraFilter")
                .flatMap(CameraVideoFilter.Kind.init(rawValue:)) ?? .none
        }
        set { set(newValue.rawValue, forKey: "cameraFilter") }
    }

    var showLiveCaptions: Bool {
        get { bool(forKey: "showLiveCaptions") }
        set { set(newValue, forKey: "showLiveCaptions") }
    }
}
