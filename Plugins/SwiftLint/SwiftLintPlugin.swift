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

import PackagePlugin
import Foundation

@main
struct SwiftLintPlugin: BuildToolPlugin {
    func createBuildCommands(
        context: PluginContext,
        target: Target
    ) async throws -> [Command] {
        let tool = try context.tool(named: "swiftlint")

        return [
            Command.prebuildCommand(
                displayName: "Formats the source code",
                executable: tool.path,
                arguments: [
                    "lint",
                    "--quiet",
                    "--cache-path",
                    context.pluginWorkDirectory,
                    "--config",
                    "\(context.package.directory.string)/.swiftlint.yml",
                    target.directory.string
                ],
                outputFilesDirectory: context.pluginWorkDirectory.appending("Output")
            )
        ]
    }
}
