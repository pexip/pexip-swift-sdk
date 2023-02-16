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

import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = false
    }

    func applicationDidUpdate(_ notification: Notification) {
        guard NSApplication.shared.mainWindow == nil else {
            return
        }

        guard NSApplication.shared.currentEvent?.type == .systemDefined else {
            return
        }

        guard NSEvent.pressedMouseButtons == 1 else {
            return
        }

        if !NSApp.windows.contains(where: { $0.isVisible }) {
            NSApp.windows.first?.makeKeyAndOrderFront(self)
        }
    }
}
