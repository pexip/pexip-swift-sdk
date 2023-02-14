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

import Foundation

/// A splash screen.
public struct SplashScreen: Hashable, Decodable {
    private enum CodingKeys: String, CodingKey {
        case layoutType = "layout_type"
        case background
        case elements
    }

    /// The layout type.
    public let layoutType: String?

    /// The background object.
    public internal(set) var background: Background

    /// A list of splash screen elements (text, etc.)
    public let elements: [Element]

    // MARK: - Init

    /// Creates a new instance of ``SplashScreen``
    ///
    /// - Parameters:
    ///   - layoutType: The layout type
    ///   - background: The background
    ///   - elements: A list of splash screen elements (text, etc.)
    public init(
        layoutType: String,
        background: SplashScreen.Background,
        elements: [SplashScreen.Element]
    ) {
        self.layoutType = layoutType
        self.background = background
        self.elements = elements
    }
}

// MARK: - Nested types

public extension SplashScreen {
    /// A splash screen background.
    struct Background: Hashable, Decodable {
        /// The background path.
        public let path: String

        /// The background url.
        public internal(set) var url: URL?

        /// Creates a new instance of ``SplashScreen.Background``
        ///
        /// - Parameters:
        ///   - path: The background path.
        public init(path: String) {
            self.path = path
        }
    }

    /// A splash screen element.
    struct Element: Hashable, Decodable {
        /// The element type.
        public let type: String

        /// The color code.
        public let color: Int

        /// The element text.
        public let text: String

        /// Checks if the element is of "text" type.
        public var isTextType: Bool {
            type == "text"
        }

        /// Creates a new instance of ``SplashScreen.Element``
        ///
        /// - Parameters:
        ///   - type: The element type
        ///   - color: The color code
        ///   - text: The element text
        public init(type: String, color: Int, text: String) {
            self.type = type
            self.color = color
            self.text = text
        }
    }
}
