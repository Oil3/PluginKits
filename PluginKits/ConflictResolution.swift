import SwiftUI
import Foundation

// MARK: - Conflict Resolution Data Models

struct ExtensionConflict: Identifiable {
    let id = UUID()
    let identifier: String
    let displayName: String
    let extensions: [AdvancedPluginExtension]
    let conflictType: ExtensionConflictType
    
    var hasActiveOlderVersion: Bool {
        let sortedExtensions = extensions.sorted { ext1, ext2 in
            return ext1.version.compare(ext2.version, options: .numeric) == .orderedDescending
        }
        
        let newestVersion = sortedExtensions.first!
        let activeExtensions = extensions.filter { $0.isActive }
        
        return activeExtensions.contains { activeExt in
            activeExt.version.compare(newestVersion.version, options: .numeric) == .orderedAscending
        }
    }
}

enum ExtensionConflictType {
    case versionMismatch
    case duplicates
    
    var description: String {
        switch self {
        case .versionMismatch: return "Version Mismatch"
        case .duplicates: return "Duplicated Extensions"
        }
    }
    
    var color: Color {
        switch self {
        case .versionMismatch: return .red
        case .duplicates: return .orange
        }
    }
}

struct UTIConflictGroup: Identifiable {
    let id = UUID()
    let utis: [String]
    let extensions: [AdvancedPluginExtension]
    
    var displayUTIs: String {
        utis.joined(separator: ", ")
    }
}

// MARK: - Resolution Progress

struct ResolutionStep: Identifiable {
    let id = UUID()
    let description: String
    let status: StepStatus
    let error: String?
    
    enum StepStatus {
        case pending, inProgress, completed, failed
        
        var color: Color {
            switch self {
            case .pending: return .secondary
            case .inProgress: return .blue
            case .completed: return .green
            case .failed: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .pending: return "circle"
            case .inProgress: return "arrow.clockwise"
            case .completed: return "checkmark.circle.fill"
            case .failed: return "xmark.circle.fill"
            }
        }
    }
}

// MARK: - Conflict Resolution Manager

class ConflictResolutionManager: ObservableObject {
    @Published var isResolving = false
    @Published var resolutionSteps: [ResolutionStep] = []
    @Published var error: String?
    
    let pluginManager: PluginKitManager
    private let fileManager = FileManager.default
    private let backupDirectory: URL
    
    init(pluginManager: PluginKitManager) {
        self.pluginManager = pluginManager
      //Where the h did it go
        self.backupDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("PluginManager_Backups")
            .appendingPathComponent(DateFormatter.backupFormatter.string(from: Date()))
    }
    
    // MARK: - Extension Conflict Resolution (Type A)
    /// Resolving duplicated extensions issues with a step-by-step procedure,
  /// Akin to a clean reinstall, here we don't fix, rather we unregiste, remove, recreate, re-register and finaly enforce plugin's eletion
  /// This should handle every case
    func resolveExtensionConflict(_ conflict: ExtensionConflict) async {
        await MainActor.run {
            isResolving = true
            resolutionSteps = []
            error = nil
        }
        
        do {
            // Step 1: Create backup directory
            await addStep("Creating backup directory...")
            try? createBackupDirectory()
            await updateStepStatus(completed: true)
            
          // Step 2: Determine which extension to keep FIRST
            await addStep("Analyzing extensions...")
            let extensionToKeep = determineExtensionToKeep(conflict.extensions)
            await updateStepStatus(completed: true)
            
            guard let keepExtension = extensionToKeep else {
//                throw NSError(domain: "ResolutionError", code: 1, userInfo: [
                    NSLog("No suitable extension found to keep")
                    return
                    
//                ])
            }
            
            // Step 3: Deregister the extension we're keeping (we'll re-register it from /Applications)
            await addStep("Deregistering extension to be moved...")
            try await deregisterExtensions([keepExtension])
            await updateStepStatus(completed: true)
            
            // Step 4: Get extensions to remove (everything except the one we're keeping)
            let extensionsToRemove = conflict.extensions.filter { $0.uuid != keepExtension.uuid }
            
            // Step 5: Zip=Backup and remove competing extensions // We zip to prevent a new conflict
            if !extensionsToRemove.isEmpty {
                await addStep("Backing up competing extensions...")
                try await backupExtensions(extensionsToRemove)
                await updateStepStatus(completed: true)
                
                await addStep("Deregistering competing extensions...")
                try await deregisterExtensions(extensionsToRemove)
                await updateStepStatus(completed: true)
                
                await addStep("Moving competing apps to trash...")
                try await trashContainerApps(extensionsToRemove)
                await updateStepStatus(completed: true)
            }
            
            // Step 6: Move the kept extension to /Applications (unless it was originally there)
            let newContainerPath = try await moveExtensionToApplications(keepExtension)
            await addStep("Moved app to /Applications")
            await updateStepStatus(completed: true)
            
            // Step 7: Re-register the extension from its new location
            await addStep("Re-registering extension from /Applications...")
            let newAppexPath = getNewAppexPath(originalPath: keepExtension.path, newContainerPath: newContainerPath)
            _ = try pluginManager.executePluginKit(arguments: ["-a", newAppexPath])
            await updateStepStatus(completed: true)
            
            // Step 8: Enforce election to 'use' using the now uniqueidentifier
            await addStep("Setting extension to active...")
            _ = try pluginManager.executePluginKit(arguments: ["-e", "use", "-i", keepExtension.identifier])
            await updateStepStatus(completed: true)
            
            await addStep("Conflict resolved - extension active in /Applications")
            await updateStepStatus(completed: true)
            
        } catch {
            await updateStepStatus(completed: false, error: error.localizedDescription)
        }
        
        await MainActor.run {
            isResolving = false
            pluginManager.refresh()
        }
    }
    
    // MARK: - UTI Conflict Resolution (Type B)
    
    func resolveUTIConflict(_ conflict: UTIConflictGroup, masterExtension: AdvancedPluginExtension, enforce: Bool) async {
        await MainActor.run {
            isResolving = true
            resolutionSteps = []
            error = nil
        }
        
        do {
            let yieldingExtensions = conflict.extensions.filter { $0.uuid != masterExtension.uuid }
                
            // Step 1: Set yielding extensions to "ignore"
            await addStep("Setting yielding extensions to 'ignore'...")
            for ext in yieldingExtensions {
                _ = try pluginManager.executePluginKit(arguments: ["-e", "ignore", "-i", ext.identifier])
            }
            await updateStepStatus(completed: true)           
            
             // Step 2: Set master extension to "use"
            await addStep("Setting master extension to 'use'...")
            _ = try pluginManager.executePluginKit(arguments: ["-e", "use", "-i", masterExtension.identifier])
            await updateStepStatus(completed: true)
        
            
            if enforce {
                // Step 3: Create backup directory for enforcement 
                await addStep("Creating backup directory for enforcement...")
                try createBackupDirectory()
                await updateStepStatus(completed: true)
                
                // Step 4: Zip-Backup yielding extensions // We zip to prevent a new conflict
                await addStep("Backing up yielding extensions...")
                try await backupExtensions(yieldingExtensions)
                await updateStepStatus(completed: true)
                
                // Step 5: Deregister yielding extensions
                await addStep("Deregistering yielding extensions...")
                try await deregisterExtensions(yieldingExtensions)
                await updateStepStatus(completed: true)
                
                // Step 6: Delete yielding extensions (container apps)
                await addStep("Moving yielding apps to trash...")
                try await trashContainerApps(yieldingExtensions)
                await updateStepStatus(completed: true)
            }
            
            await addStep("UTI conflict resolved successfully")
            await updateStepStatus(completed: true)
            
        } catch {
            await updateStepStatus(completed: false, error: error.localizedDescription)
        }
        
        await MainActor.run {
            isResolving = false
            pluginManager.refresh()
        }
    }
    
    // MARK: - Helper Methods
    
    private func createBackupDirectory() throws {
        if !fileManager.fileExists(atPath: backupDirectory.path) {
            try fileManager.createDirectory(at: backupDirectory, withIntermediateDirectories: true)
        }
    }
    
    private func backupExtensions(_ extensions: [AdvancedPluginExtension]) async throws {
        for ext in extensions {
            let containerAppPath = getContainerAppPath(from: ext.path)
            let sourcePath = URL(fileURLWithPath: containerAppPath)
            let backupPath = backupDirectory
                .appendingPathComponent("\(ext.identifier)-\(ext.version)")
                .appendingPathExtension("zip")
            
            try await zipDirectory(source: sourcePath, destination: backupPath)
        }
    }
    
    private func zipDirectory(source: URL, destination: URL) async throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
        process.arguments = ["-r", "-0", "-q", destination.path, source.lastPathComponent]
        process.currentDirectoryURL = source.deletingLastPathComponent()
      
        try process.run()
        process.waitUntilExit()
        
//        guard process.terminationStatus == 0 else {
      }
    
    private func deregisterExtensions(_ extensions: [AdvancedPluginExtension]) async throws {
        for ext in extensions {
             _ = try pluginManager.executePluginKit(arguments: ["-r", ext.path])
        }
    }
    
    // We keep exactly 1 extension
    private func determineExtensionToKeep(_ extensions: [AdvancedPluginExtension]) -> AdvancedPluginExtension? {
        // Priority 1: Currently active extension in /Applications with highest version
        let applicationsActive = extensions.filter { 
            $0.path.hasPrefix("/Applications/") && $0.isActive
        }.sorted { ext1, ext2 in
            ext1.version.compare(ext2.version, options: .numeric) == .orderedDescending
        }
        
        if let bestActive = applicationsActive.first {
            return bestActive
        }
        
        // Priority 2: Any extension in /Applications with highest version
        let applicationsExtensions = extensions.filter { 
            $0.path.hasPrefix("/Applications/")
        }.sorted { ext1, ext2 in
            ext1.version.compare(ext2.version, options: .numeric) == .orderedDescending
        }
        
        if let bestInApps = applicationsExtensions.first {
            return bestInApps
        }
        
        // Priority 3: Highest version anywhere (fallback)
        return extensions.max { ext1, ext2 in
            ext1.version.compare(ext2.version, options: .numeric) == .orderedAscending
        }
    }
    
    // NEW: Trash instead of deleete
    private func trashContainerApps(_ extensions: [AdvancedPluginExtension]) async throws {
        var trashedApps = Set<String>() // Avoid trashing the same app twice
        
        for ext in extensions {
            let containerAppPath = getContainerAppPath(from: ext.path)
            
            // Skip if we already trashed this app
            if trashedApps.contains(containerAppPath) {
                continue
            }
            
            let url = URL(fileURLWithPath: containerAppPath)
            if fileManager.fileExists(atPath: containerAppPath) {
                try fileManager.trashItem(at: url, resultingItemURL: nil)
                trashedApps.insert(containerAppPath)
            }
        }
    }
    
    //  We Move extension to /Applications, the recommended folder, to ensure e have o single source of truth
        private func moveExtensionToApplications(_ extension: AdvancedPluginExtension) async throws -> String {
        let currentContainerPath = getContainerAppPath(from: extension.path)
        let currentContainerURL = URL(fileURLWithPath: currentContainerPath)
        let appName = currentContainerURL.lastPathComponent
        let applicationsURL = URL(fileURLWithPath: "/Applications")
        let destinationURL = applicationsURL.appendingPathComponent(appName)
        
        // If already in /Applications, just return the current path
        if currentContainerPath.hasPrefix("/Applications/") {
            return currentContainerPath
        }
        
        // Check if destination already exists and remove it
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.trashItem(at: destinationURL, resultingItemURL: nil)
        }
        
        // Move the app to /Applications
        try fileManager.moveItem(at: currentContainerURL, to: destinationURL)
        
        return destinationURL.path
    }
    
    // Update appex path with new container location
    private func getNewAppexPath(originalPath: String, newContainerPath: String) -> String {
        let originalURL = URL(fileURLWithPath: originalPath)
        let newContainerURL = URL(fileURLWithPath: newContainerPath)
        
        // Get the relative path from container to .appex
        // Original: /old/path/MyApp.app/Contents/PlugIns/Extension.appex
        // Result:   /Applications/MyApp.app/Contents/PlugIns/Extension.appex
        let relativeComponents = ["Contents", "PlugIns", originalURL.lastPathComponent]
        
        return relativeComponents.reduce(newContainerURL) { url, component in
            url.appendingPathComponent(component)
        }.path
    }
    
    // NEW: Get container app path from .appex path
    private func getContainerAppPath(from appexPath: String) -> String {
        // From: /Applications/MyApp.app/Contents/PlugIns/Extension.appex
        // To:   /Applications/MyApp.app
        let url = URL(fileURLWithPath: appexPath)
        return url.deletingLastPathComponent()  // Remove Extension.appex
                 .deletingLastPathComponent()   // Remove PlugIns
                 .deletingLastPathComponent()   // Remove Contents
                 .path                          // Get /Applications/MyApp.app
    }
    
    private func registerExtension(_ extension: AdvancedPluginExtension) async throws {
        // Use .appex path for registration
        _ = try pluginManager.executePluginKit(arguments: ["-a", extension.path])
    }
    
    // MARK: - Step Management
    
    @MainActor
    private func addStep(_ description: String) {
        resolutionSteps.append(ResolutionStep(
            description: description,
            status: .inProgress,
            error: nil
        ))
    }
    
    @MainActor
    private func updateStepStatus(completed: Bool, error: String? = nil) {
        guard !resolutionSteps.isEmpty else { return }
        let lastIndex = resolutionSteps.count - 1
        resolutionSteps[lastIndex] = ResolutionStep(
            description: resolutionSteps[lastIndex].description,
            status: completed ? .completed : .failed,
            error: error
        )
    }
}

// MARK: - Extensions

extension DateFormatter {
    static let backupFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter
    }()
}
