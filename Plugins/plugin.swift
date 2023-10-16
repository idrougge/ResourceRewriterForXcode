//
//  plugin.swift
//  ResourceRewriterForXcode
//
//  Created by Iggy Drougge on 2023-10-16.
//

import PackagePlugin
import XcodeProjectPlugin
import Foundation

@main
struct ResourceRewriterPlugin: CommandPlugin, XcodeCommandPlugin {
    func performCommand(context: PluginContext, arguments: [String]) async throws {
        var argumentExtractor = ArgumentExtractor(arguments)
        let targetNames = argumentExtractor.extractOption(named: "target")
        let sourceModules = try context.package.targets(named: targetNames).compactMap(\.sourceModule)
        let files = sourceModules.flatMap { $0.sourceFiles(withSuffix: "swift") }
        let tool = try context.tool(named: "ResourceRewriterForXcode")
        let process = Process()
        process.executableURL = URL(fileURLWithPath: tool.path.string)
        process.arguments = files.map(\.path.string)
        try process.run()
        process.waitUntilExit()
        
        switch (process.terminationReason, process.terminationStatus) {
        case (.exit, EXIT_SUCCESS):
            print("String literals were successfully rewritten as resources.")
        case (let reason, let status):
            Diagnostics.error("Process terminated with error: \(reason) (\(status))")
        }
    }
    
    func performCommand(context: XcodePluginContext, arguments: [String]) throws {
        let sourceFiles = context.xcodeProject.filePaths.filter { file in
            file.extension == "swift"
        }
        let tool = try context.tool(named: "ResourceRewriterForXcode")
        let process = Process()
        process.executableURL = URL(fileURLWithPath: tool.path.string)
        process.arguments = sourceFiles.map(\.string)
        try process.run()
        process.waitUntilExit()
        
        switch (process.terminationReason, process.terminationStatus) {
        case (.exit, EXIT_SUCCESS):
            print("String literals were successfully rewritten as resources.")
        case (let reason, let status):
            Diagnostics.error("Process terminated with error: \(reason) (\(status))")
        }
    }
}
