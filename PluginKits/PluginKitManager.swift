//
//  PluginKitManager.swift
//  PluginKits
//
//  Created by Almahdi Morris Quet on 09/18/25.
//
import SwiftUI


class PluginKitManager: ObservableObject {
  @Published var allExtensions: [PluginExtension] = []
  @Published var quickLookExtensions: [PluginExtension] = []
  @Published var isLoading = false
  @Published var error: String?
  @Published var showingFilePicker = false
  @Published var advancedExtensions: [AdvancedPluginExtension] = []
  @Published var selectedPluginDetails: AdvancedPluginExtension?
  @Published var showingPluginDetails = false
  @Published var utiExtensions: [String: String] = [:]
  @Published var selectedUTIInfo: UTIInfo?
  @Published var showingUTIInfo = false
  @Published var cachedUTIInfo: [String: UTIInfo] = [:]
@State private var detailsWindow = NSWindow()
    // Simple session-based undo - just store paths, it's for 'undo deregiter'
    @Published var lastDeregisteredPath: [String] = []
    @Published var showingManualAddPicker = false
    
// Update the showInFinder method in PluginKitManager
func showInFinder(path: String) {
    guard !path.isEmpty else { 
        self.error = "No path available"
        return 
    }
    
    let url = URL(fileURLWithPath: path)
    
    // Check if file exists first
    guard FileManager.default.fileExists(atPath: path) else {
        self.error = "File not found at path: \(path)"
        return
    }
    
    // Use the more reliable activateFileViewerSelecting method
    NSWorkspace.shared.activateFileViewerSelecting([url])
}

  func getFileExtension(for uti: String) -> String? {
    return utiExtensions[uti]
  }
  
  func loadUTIExtension(for uti: String) {
    // Return cached if available
    if utiExtensions[uti] != nil {
      return
    }
    
    DispatchQueue.global(qos: .userInitiated).async {
      do {
        let output = try self.executeUTType(arguments: ["--verbose", uti])
        let extension = self.parseUTTypeExtension(output)
        
        DispatchQueue.main.async {
          self.utiExtensions[uti] = extension
        }
      } catch {
        DispatchQueue.main.async {
          self.utiExtensions[uti] = "" // Mark as attempted but failed
        }
      }
    }
  }
  
  private func parseUTTypeExtension(_ output: String) -> String {
    let lines = output.components(separatedBy: .newlines)
    
    for line in lines {
      let trimmed = line.trimmingCharacters(in: .whitespaces)
      if trimmed.hasPrefix("public.filename-extension:") {
        let ext = trimmed.replacingOccurrences(of: "public.filename-extension:", with: "")
          .trimmingCharacters(in: .whitespaces)
        if !ext.isEmpty {
          return ext
        }
      }
    }
    
    return "unknown"
  }
  
    func executeUTType(arguments: [String]) throws -> String {
    let process = Process()
     process.executableURL = URL(fileURLWithPath: "/usr/bin/uttype")
    process.arguments = arguments
    
    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = pipe
    
    try process.run()
    //process.waitUntilExit()
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8) ?? ""
    
    if process.isRunning  {
      process.terminate()
    }
    
    return output
  }
  
  func loadPluginDetails(for identifier: String) {
    DispatchQueue.global(qos: .userInitiated).async {
      do {
        let output = try self.executePluginKit(arguments: ["-m", "-i", identifier, "-v", "-v", "--raw"])
        if let plugin = self.parseRawPluginKitOutput(output).first {
          DispatchQueue.main.async {
            self.selectedPluginDetails = plugin
            self.showingPluginDetails = true


          }
        }
      } catch {
        DispatchQueue.main.async {
          self.error = "Failed to load plugin details: \(error.localizedDescription)"
        }
      }
    }
  }
  
  func loadExtensions() {
    isLoading = true
    error = nil
    
    DispatchQueue.global(qos: .userInitiated).async{
      do {
        // Use basic -m for speed (no paths needed for general list)
        let output = try self.executePluginKit(arguments: ["-m", "-v", "-v"])
                    let extensions = self.parseVerbosePluginKitOutput(output)
        
        DispatchQueue.main.async {
          self.allExtensions = extensions
          self.isLoading = false
        }
      } catch {
        DispatchQueue.main.async {
          self.error = error.localizedDescription
          self.isLoading = false
        }
      }
    }
  }
  func loadAdvancedAnalysis() {
    isLoading = true
    error = nil
    
    DispatchQueue.global(qos: .userInitiated).async {
      do {
        let output = try self.executePluginKit(arguments: ["-m", "-D", "-p", "com.apple.quicklook.preview", "-v", "-v", "--raw"])
        let extensions = self.parseRawPluginKitOutput(output)
        
        DispatchQueue.main.async {
          self.advancedExtensions = extensions
          self.isLoading = false
        }
      } catch {
        DispatchQueue.main.async {
          self.error = error.localizedDescription
          self.isLoading = false
        }
      }
    }
  }
  private func parseRawPluginKitOutput(_ output: String) -> [AdvancedPluginExtension] {
    // Find the first opening parenthesis (start of plist) and last closing parenthesis
    guard let plistStart = output.firstIndex(of: "("),
          let plistEnd = output.lastIndex(of: ")") else { 
      return [] 
    }
    
    // Extract the plist content including the parentheses
    let plistString = String(output[plistStart...plistEnd])
    
    do {
      // Parse as OpenStep/text property list format
      guard let plistData = plistString.data(using: .utf8) else {
        return []
      }
      
      var format: PropertyListSerialization.PropertyListFormat = .xml
      let plist = try PropertyListSerialization.propertyList(from: plistData, 
                                                             options: [], 
                                                             format: &format)
      
      guard let pluginArray = plist as? [[String: Any]] else {
        print("Failed to cast plist to array of dictionaries")
        return []
      }
      
      var extensions: [AdvancedPluginExtension] = []
      
      for item in pluginArray {
        guard let bundleInfo = item["bundleInfo"] as? [String: Any],
              let identifier = item["identifier"] as? String,
              let uuid = item["uuid"] as? String,
              let version = item["version"] as? String,
              let path = item["path"] as? String else {
          continue
        }
        
        let displayName = bundleInfo["CFBundleDisplayName"] as? String ?? 
        bundleInfo["CFBundleName"] as? String ?? 
        identifier.components(separatedBy: ".").last ?? identifier
        
        // Extract NSExtension info
        var supportedContentTypes: [String] = []
        if let nsExtension = bundleInfo["NSExtension"] as? [String: Any],
           let attributes = nsExtension["NSExtensionAttributes"] as? [String: Any],
           let contentTypes = attributes["QLSupportedContentTypes"] as? [String] {
          supportedContentTypes = contentTypes
        }
        
//        let isApple = path.hasPrefix("/System")
        let isApple = identifier.hasPrefix("com.apple")
        // Parse election state from annotations
//        var isActive = false
//        if let annotations = item["annotations"] as? [String: Any] {
//            if let electionNumber = annotations["election"] as? Int {
//                // election = 1: active, election = 2: deactivated, election = 257: debug
//                isActive = (electionNumber == 1 || electionNumber == 257)
//            } else if let electionString = annotations["election"] as? String,
//                      let electionNumber = Int(electionString) {
//                isActive = (electionNumber == 1 || electionNumber == 257)
//            }
//        }
        // Parse election state from annotations
        var electionValue = 0
        if let annotations = item["annotations"] as? [String: Any] {
          if let election = annotations["election"] as? Int {
            electionValue = election
          } else if let electionString = annotations["election"] as? String,
                    let election = Int(electionString) {
            electionValue = election
          }
        }

        let ext = AdvancedPluginExtension(
          identifier: identifier,
          displayName: displayName,
          version: version,
          path: path,
          uuid: uuid,
          supportedContentTypes: supportedContentTypes,
          bundleInfo: bundleInfo,
          isApple: isApple, 
              electionValue: electionValue
//          isActive: isActive
        )
        
        extensions.append(ext)
      }
      
      return extensions.sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
      
    } catch {
      print("Failed to parse OpenStep plist: \(error)")
      return []
    }
  }


  
  
  func loadQuickLookExtensions() {
    isLoading = true
    error = nil
    
    DispatchQueue.global(qos: .userInitiated).async {
      do {
        // Use the specific command for QuickLook duplicates with detailed info
        let output = try self.executePluginKit(arguments: ["-m", "-D", "-p", "com.apple.quicklook.preview", "-v", "-v"])
        let extensions = self.parseDetailedPluginKitOutput(output)
        
        DispatchQueue.main.async {
          self.quickLookExtensions = extensions
          self.isLoading = false
        }
      } catch {
        DispatchQueue.main.async {
          self.error = error.localizedDescription
          self.isLoading = false
        }
      }
    }
  }
  
  func refresh() {
  self.allExtensions = []
      loadExtensions()

  self.advancedExtensions = []
  self.quickLookExtensions = []
  
  
//              DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
              loadQuickLookExtensions()
     loadAdvancedAnalysis()
  }
  
  func setElection(_ ext: PluginExtension, to election: String) {
    DispatchQueue.global(qos: .userInitiated).async {
      do {
        _ = try self.executePluginKit(arguments: ["-e", election, "-i", ext.identifier])
        DispatchQueue.main.async {
          self.refresh()
        }
      } catch {
        DispatchQueue.main.async {
          self.error = "Failed to set election: \(error.localizedDescription)"
        }
      }
    }
  }
  
  func removePlugin1111(_ ext: PluginExtension) {
    DispatchQueue.global(qos: .userInitiated).async {
      do {
        // Use path if available, otherwise identifier
        let target = ext.path.isEmpty ? ext.identifier : ext.path
        _ = try self.executePluginKit(arguments: ["-r", target])
        DispatchQueue.main.async {
          self.refresh()
        }
      } catch {
        DispatchQueue.main.async {
          self.error = "Failed to remove plugin: \(error.localizedDescription)"
        }
      }
    }
  }
  // Modified removePlugin method with undo capability
    func removePlugin(_ ext: PluginExtension) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // Store path for potential undo (only if we have a valid path)
                if !ext.path.isEmpty {
                    DispatchQueue.main.async {
                        self.lastDeregisteredPath.append(ext.path)
                        
                    }
                }
                
                let target = ext.path.isEmpty ? ext.identifier : ext.path
                _ = try self.executePluginKit(arguments: ["-r", target])
                
                DispatchQueue.main.async {
                    self.refresh()
                }
            } catch {
                DispatchQueue.main.async {
                    // Clear undo if deregistration failed
//                    self.lastDeregisteredPath = nil
                    self.error = "Failed to remove plugin: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // Simple re-register using stored path
    func undoLastDeregistration() {
    guard  self.lastDeregisteredPath.last != nil else { return }

        let path = lastDeregisteredPath.removeLast() //eelse { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                _ = try self.executePluginKit(arguments: ["-a", path])
                
                DispatchQueue.main.async {
//                    self.lastDeregisteredPath = nil
                    self.refresh()
                }
            } catch {
                DispatchQueue.main.async {
                    self.error = "Failed to re-register plugin: \(error.localizedDescription)"
                }
            }
        }
    }
    
    
  func addPlugin(at path: String) {
    DispatchQueue.global(qos: .userInitiated).async {
      do {
        _ = try self.executePluginKit(arguments: ["-a", path])
        DispatchQueue.main.async {
          self.refresh()
        }
      } catch {
        DispatchQueue.main.async {
          self.error = "Failed to add plugin: \(error.localizedDescription)"
        }
      }
    }
  }
  
   func executePluginKit(arguments: [String]) throws -> String {
    let process = Process()
    
    process.executableURL = URL(fileURLWithPath: "/usr/bin/pluginkit")
    process.arguments = arguments
    
    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = pipe
    
    try process.run()
    //process.waitUntilExit()
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8) ?? ""
    //    guard process.terminationStatus == 0 else { 
    //      throw NSError( // This self-inflicted crash we never, God willing, ever do again.
    //        domain: "PluginKitError",
    //        code: Int(process.terminationStatus),
    //        userInfo: [output]
    //      )
    //    }
    process.terminate()



    return output
  }
  // MARK: - arser for verbose pluginkit output (-v -v)
    private func parseVerbosePluginKitOutput(_ output: String) -> [PluginExtension] {
        // Split by double newlines to separate plugin blocks
        let pluginBlocks = output.components(separatedBy: "\n\n").filter { 
            !$0.trimmingCharacters(in: .whitespaces).isEmpty 
        }
        
        var extensions: [PluginExtension] = []
        
        for block in pluginBlocks {
            let lines = block.components(separatedBy: .newlines).filter { 
                !$0.trimmingCharacters(in: .whitespaces).isEmpty 
            }
            
            guard !lines.isEmpty else { continue }
            
            // Parse the header line: [election]    identifier(version)
            let headerLine = lines[0]
            
            // Extract election state (first character)
            let electionState: ElectionState
            let identifierLine: String
            
            if headerLine.hasPrefix("+") {
                electionState = .use
                identifierLine = String(headerLine.dropFirst()).trimmingCharacters(in: .whitespaces)
            } else if headerLine.hasPrefix("-") {
                electionState = .ignore
                identifierLine = String(headerLine.dropFirst()).trimmingCharacters(in: .whitespaces)
            } else if headerLine.hasPrefix("!") {
                electionState = .debug
                identifierLine = String(headerLine.dropFirst()).trimmingCharacters(in: .whitespaces)
            } else if headerLine.hasPrefix("=") {
                electionState = .superseded
                identifierLine = String(headerLine.dropFirst()).trimmingCharacters(in: .whitespaces)
            } else if headerLine.hasPrefix("?") {
                electionState = .unknown
                identifierLine = String(headerLine.dropFirst()).trimmingCharacters(in: .whitespaces)
            } else {
                electionState = .none
                identifierLine = headerLine.trimmingCharacters(in: .whitespaces)
            }
            
            // Extract identifier and version from: identifier(version)
            guard let openParen = identifierLine.lastIndex(of: "("),
                  let closeParen = identifierLine.lastIndex(of: ")") else {
                continue
            }
            
            let identifier = String(identifierLine[..<openParen]).trimmingCharacters(in: .whitespaces)
            let versionStart = identifierLine.index(after: openParen)
            let version = String(identifierLine[versionStart..<closeParen])
            
            // Parse properties from subsequent lines
            var properties: [String: String] = [:]
            
            for line in lines.dropFirst() {
                // Each property line: \t<spaces>Property = Value
                if line.contains(" = ") {
                    let components = line.split(separator: "=", maxSplits: 1)
                    if components.count == 2 {
                        let key = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
                        let value = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
                        properties[key] = value
                    }
                }
            }
            
            // Extract required fields with fallbacks
            let path = properties["Path"] ?? ""
            let displayName = properties["Display Name"] ?? 
                              properties["Short Name"] ?? 
                              identifier.components(separatedBy: ".").last ?? 
                              identifier
            let uuid = properties["UUID"] ?? identifier
            let sdk = properties["SDK"] ?? ""
            
            // We have ome redundancy with all those logics
            let isApple = identifier.hasPrefix("com.apple") //|| path.hasPrefix("/System")
            let isQuickLook = sdk.lowercased().contains("quicklook") ||                             identifier.lowercased().contains("quicklook") //||                              identifier.lowercased().contains("ql")
            
            let ext = PluginExtension(
                identifier: identifier,
                displayName: displayName,
                version: version == "null" ? "" : version,
                path: path,
                id: uuid,
                electionState: electionState,
                isQuickLook: isQuickLook,
                isApple: isApple,
                sdk: sdk
            )
            
            extensions.append(ext)
        }
        
        return extensions.sorted { 
            $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending 
        }
    }  
  
  
  
  // Detailed parsing for -v -v output with patha
  private func parseDetailedPluginKitOutput(_ output: String) -> [PluginExtension] {
    let pluginBlocks = output.components(separatedBy: "\n\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    var extensions: [PluginExtension] = []
    
    for block in pluginBlocks {
      let lines = block.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
      guard !lines.isEmpty else { continue }
      
      // First line: election state + identifier(version)
      let headerLine = lines[0].trimmingCharacters(in: .whitespaces)
      
      // Parse election state
      let electionState: ElectionState
      let cleanLine: String
      
      if headerLine.hasPrefix("+") {
        electionState = .use
        cleanLine = String(headerLine.dropFirst()).trimmingCharacters(in: .whitespaces)
      } else if headerLine.hasPrefix("-") {
        electionState = .ignore
        cleanLine = String(headerLine.dropFirst()).trimmingCharacters(in: .whitespaces)
      } else if headerLine.hasPrefix("!") {
        electionState = .debug
        cleanLine = String(headerLine.dropFirst()).trimmingCharacters(in: .whitespaces)
      } else if headerLine.hasPrefix("=") {
        electionState = .superseded
        cleanLine = String(headerLine.dropFirst()).trimmingCharacters(in: .whitespaces)
      } else if headerLine.hasPrefix("?") {
        electionState = .unknown
        cleanLine = String(headerLine.dropFirst()).trimmingCharacters(in: .whitespaces)
      } else {
        electionState = .none
        cleanLine = headerLine
      }
      
      // Extract identifier and version
      guard let openParen = cleanLine.lastIndex(of: "("),
            let closeParen = cleanLine.lastIndex(of: ")") else {
        continue
      }
      
      let identifier = String(cleanLine[..<openParen])
      let versionStart = cleanLine.index(after: openParen)
      let version = String(cleanLine[versionStart..<closeParen])
      
      // Parse all detail lines into dictionary
      var details: [String: String] = [:]
      for line in lines.dropFirst() {
        if line.contains(" = ") {
          let components = line.split(separator: "=", maxSplits: 1)
          if components.count == 2 {
            let key = components[0].trimmingCharacters(in: .whitespaces)
            let value = components[1].trimmingCharacters(in: .whitespaces)
            details[key] = value
          }
        }
      }
      
      // Extract required fields
      let path = details["Path"] ?? ""
      let displayName = details["Display Name"] ?? identifier.components(separatedBy: ".").last ?? identifier
      let uuid = details["UUID"] ?? identifier  // Bette we use UUID as unique identifier
      let sdk = details["SDK"] ?? ""
      
      // Strqightforard quickLook detection via SDKs
      let isQuickLook = sdk == "com.apple.quicklook.preview"
      
    let isApple = identifier.hasPrefix("com.apple") 
    //      let isApple = path.hasPrefix("/System")
      
      let ext = PluginExtension(
        identifier: identifier,
        displayName: displayName,
        version: version.isEmpty || version == "(null)" ? "" : version,
        path: path,
        id: uuid,
        electionState: electionState,
        isQuickLook: isQuickLook,
        isApple: isApple,
         sdk: sdk
      )
      
      extensions.append(ext)
    }
    
    return extensions.sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
  }
  
  func detectConflicts(for extensions: [PluginExtension]) -> [String: ConflictType] {
    var conflicts: [String: ConflictType] = [:]
    // Group plugins by identifier to compare and see conflicts //UUID
  let groupedByIdentifier = Dictionary(grouping: extensions) { $0.identifier }

for (_, versions) in groupedByIdentifier { //versions as in different extension, not versioning version.

          // If it's not in /Applications it's not in the recommended location. Doesn't concern Apple/system stutff
      let userApplicationsPath = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications").path
      for version in versions {
        if version.isQuickLook && version.electionState == .use {
          let path = version.path

if !path.hasPrefix("/System/") && 
   !path.hasPrefix("/Applications/") && 
   !path.hasPrefix(userApplicationsPath + "/") {   
            conflicts[version.id] = .locationWarning
          }
        }
      }
      
     if versions.count > 1 {
        // Mark all extensions with duplicate identifiers
        for version in versions {
            conflicts[version.id] = .duplicatee
        }
    }   
     }
    return conflicts
  } 
  
  func moveAppToTrash(path: String) {
   // DispatchQueue.global(qos: .userInitiated).async {
   //   do {
        let url = URL(fileURLWithPath: path)
        try! FileManager.default.trashItem(at: url, resultingItemURL: nil)
        
        DispatchQueue.main.async {
          self.refresh() 
//        }
//      } catch {
//        DispatchQueue.main.async {
//          self.error = "Failed to move to trash: \(error.localizedDescription)"
        }
      }
    
  }
