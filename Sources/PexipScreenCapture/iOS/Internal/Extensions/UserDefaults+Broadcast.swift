//
// Copyright 2022-2023 Pexip AS
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

#if os(iOS)

import Foundation

extension UserDefaults {
    private enum Key {
        static let broadcastFps = "com.pexip.PexipScreenCapture.broadcastFps"
        static let broadcastKeepAliveDate = "com.pexip.PexipScreenCapture.broadcastKeepAliveDate"
    }

    var broadcastFps: UInt? {
        get {
            let value = UInt(integer(forKey: Key.broadcastFps))
            return value > 0 ? value : nil
        }
        set {
            if let newValue {
                setValue(Int(newValue), forKey: Key.broadcastFps)
            } else {
                removeObject(forKey: Key.broadcastFps)
            }
        }
    }

    var broadcastKeepAliveDate: Date? {
        get { object(forKey: Key.broadcastKeepAliveDate) as? Date }
        set {
            if let newValue {
                setValue(newValue, forKey: Key.broadcastKeepAliveDate)
            } else {
                removeObject(forKey: Key.broadcastKeepAliveDate)
            }
        }
    }
}

#endif
