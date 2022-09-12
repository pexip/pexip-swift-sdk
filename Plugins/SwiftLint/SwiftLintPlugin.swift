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
            Command.buildCommand(
                displayName: "Formats the source code",
                executable: tool.path,
                arguments: [
                    "lint",
                    "--in-process-sourcekit",
                    "--config",
                    "\(context.package.directory.string)/.swiftlint.yml",
                    context.package.directory.string
                ]
            )
        ]
    }
}
