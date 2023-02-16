//
// Copyright 2022 Pexip AS
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import SwiftUI

final class Settings: ObservableObject {
    @Published var cameraFilter: CameraVideoFilter? {
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
    var cameraFilter: CameraVideoFilter? {
        get {
            string(forKey: "cameraFilter")
                .flatMap(CameraVideoFilter.init(rawValue:))
        }
        set {
            if let newValue {
                set(newValue.rawValue, forKey: "cameraFilter")
            } else {
                removeObject(forKey: "cameraFilter")
            }
        }
    }

    var showLiveCaptions: Bool {
        get { bool(forKey: "showLiveCaptions") }
        set { set(newValue, forKey: "showLiveCaptions") }
    }
}
