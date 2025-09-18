import SwiftUI
import UniformTypeIdentifiers
 
struct SimplePluginRowView: View {
  let ext: PluginExtension
   @ObservedObject var manager: PluginKitManager
  @State private var showingRemoveConfirmation = false
  @State private var showingTrashConfirmation = false
    @State private var hoverShowingPath = false
var conflicts: [String: ConflictType]? = [:]

private var conflict: ConflictType? {
  conflicts?[ext.id]
    }
  
  private var parentAppPath: String {
    // Extract parent app path for trashing
    let components = ext.path.components(separatedBy: "/")
    if let appIndex = components.firstIndex(where: { $0.hasSuffix(".app") }) {
      return Array(components[0...appIndex]).joined(separator: "/")
  }
       return ext.path
 } 
  var body: some View {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        HStack {
        
          Circle()
            .fill(conflict?.color ?? ext.electionState.color)
            .frame(width: 10, height: 10)
          
          Text(ext.displayName)
            .font(.headline)
                      .foregroundColor(.primary)   

          Text("\(ext.version)")
            .font(.caption)
            .foregroundColor(.secondary)   
    Text(ext.identifier)
          .font(.caption)
          .foregroundColor(.secondary)
          //.textSelection(.enabled)
          
         //  if !ext.identifier.hasPrefix("com.apple") && ext.isQuickLook {
             Text(!ext.isEnabled ? "Deactivated" : "Active")
              .font(.caption)
              .padding(.horizontal, 6)
              .padding(.vertical, 2)
               .foregroundColor(ext.isEnabled ? .primary : .secondary)
              .cornerRadius(4)
              .opacity(ext.isEnabled ? 1.0 : 0.6)
//}                    
          
          if let conflict = conflict {
            Text(conflict.description)
              .font(.caption)
              .padding(.horizontal, 6)
              .padding(.vertical, 2)
              .background(conflict.color)
              .foregroundColor(.white)
              .cornerRadius(4)
          }
//          if !ext.path.localizedStandardContains("Applications") && !ext.path.localizedStandardContains("System") {
//    Text("Possible conflict")
//        .font(.caption)
//        .padding(.horizontal, 6)
//        .padding(.vertical, 2)
//        .background(Color.orange.opacity(0.2))
//        .foregroundColor(.orange)
//        .cornerRadius(4)

//          if ext.isQuickLook {
//            Text("QuickLook")
//              .font(.caption)
//              .padding(.horizontal, 6)
//              .padding(.vertical, 2)
//              .background(Color.blue.opacity(0.2))
//              .foregroundColor(.blue)
//              .cornerRadius(4)
Spacer()
//          if ext.isApple {
//            Text("")
////            Text("Apple")
//              .font(.caption)
//              .padding(.horizontal, 6)
//              .padding(.vertical, 2)
//              .background(Color.gray.opacity(0.2))
//              .foregroundColor(.gray)
//              .cornerRadius(4)
//          }
                    if !ext.sdk.isEmpty {
                        Text(ext.pluginType)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(pluginTypeColor(ext.pluginType).opacity(0.2))
                            .foregroundColor(pluginTypeColor(ext.pluginType))
                            .cornerRadius(4)
                            .offset(y: 8
                            )
                    }
                    

        }
        
//        Text(ext.identifier)
//          .font(.caption)
//          .foregroundColor(.secondary)
//          //.textSelection(.enabled)
      VStack{ 
       // if !ext.path.isEmpty {
          Text(ext.path)
                    .opacity(hoverShowingPath ? 1.0 : 0)

            .font(.caption)
            .foregroundColor(.secondary)
            //.textSelection(.enabled)
            .lineLimit(1)
            .truncationMode(.middle)
     //   }
      }
     } 
      Spacer()
      
      HStack(spacing: 8, ) {

        Button(action: {
          manager.loadPluginDetails(for: ext.identifier)
        }) {
          Image(systemName: "info.circle")
            .foregroundColor(.accentColor)
        }
        .buttonStyle(PlainButtonStyle())
        
        Menu {
          Button("Use") {
            manager.setElection(ext, to: "use")
          }
          Button("Deactivate") {
            manager.setElection(ext, to: "ignore")
          }
          
          Divider()
          
          Button("Show Details") {
            manager.loadPluginDetails(for: ext.identifier)
          }
          Button("Copy Identifier") {
            NSPasteboard.general.setString(ext.identifier, forType: .string)
          }
          if !ext.path.isEmpty {
            Button("Copy Path") {
              NSPasteboard.general.setString(ext.path, forType: .string)
            }
          }
          
          Divider()
          
          Button("Deregister Plugin") {
            showingRemoveConfirmation = true
          }
          
            Button("Move App to Trash", role: .destructive) {
              showingTrashConfirmation = true
           }
        //   .opacity(ext.isApple ? 0.3: 1.0)
           .disabled(ext.isApple ? true : false)
        } label: {
          Text(ext.electionState.displayName)
            .font(.caption)
            .foregroundColor(conflict?.color ?? ext.electionState.color)
        }
        .menuStyle(BorderlessButtonMenuStyle())
        .frame(maxWidth: 10)
        
        Button(action: {
    manager.showInFinder(path: ext.path.isEmpty ? parentAppPath : ext.path)
}) {
    Image(systemName: "folder")
        .foregroundColor(.secondary)
}
.buttonStyle(PlainButtonStyle())

        Button(action: { showingRemoveConfirmation = true }) {
          Image(systemName: "minus.circle")
            .foregroundColor(.secondary)
        }
        .buttonStyle(PlainButtonStyle())
        
//        if !ext.isApple && !parentAppPath.hasPrefix("/System") {
          Button(action: { showingTrashConfirmation = true }) {
            Image(systemName: "trash")
              .foregroundColor(.secondary)
          }
           .disabled(ext.isApple ? true : false)
                 //     .opacity(ext.isApple ? 0.3: 1.0)

          .buttonStyle(PlainButtonStyle())
//        }
      }
    }
   
    .onHover{ hovering in
    hoverShowingPath = hovering
    }
    .padding(.vertical, 4)
    .confirmationDialog(
      "Deregister Plugin",
      isPresented: $showingRemoveConfirmation,
      titleVisibility: .visible
    ) {
      Button("Deregister", role: .destructive) {
        manager.removePlugin(ext)
      }
      Button("Cancel", role: .cancel) { }
    } message: {
      Text("This will deregister the plugin from the system:\n\(ext.displayName)")
    }
    .confirmationDialog(
      "Move to Trash",
      isPresented: $showingTrashConfirmation,
      titleVisibility: .visible
    ) {
      Button("Move to Trash", role: .destructive) {
        manager.moveAppToTrash(path: parentAppPath)
      }
      Button("Cancel", role: .cancel) { }
    } message: {
      Text("This will move the entire app to trash:\n\(parentAppPath)")
    }
    
    .contextMenu{
      Button("Use") {
        manager.setElection(ext, to: "use")
      }
      Button("Deactvate") {
        manager.setElection(ext, to: "ignore")
      }
      Divider()
      Button("Show Details") {
        manager.loadPluginDetails(for: ext.identifier)
      }
      Button("Copy Identifier") {
              NSPasteboard.general.clearContents()

        NSPasteboard.general.setString(ext.identifier, forType: .string)
      }
      if !ext.path.isEmpty {
        Button("Copy Path") {
                NSPasteboard.general.clearContents()

          NSPasteboard.general.setString(ext.path, forType: .string)
        }
      }
      Divider()
      Button("Deregister Plugin") {
        showingRemoveConfirmation = true
      }
      if !ext.identifier.contains("com.apple") {
        Button("Move App to Trash", role: .destructive) {
          showingTrashConfirmation = true
        }
      }
         if manager.lastDeregisteredPath.last != nil {
        Button("Undo Last Deregister") {
            manager.undoLastDeregistration()
        }
        }
  
      
      
    }
    }
      private func pluginTypeColor(_ type: String) -> Color {
        switch type {
        // Core macOS
        case "QuickLook", "Thumbnail": return .blue
        case "Finder Sync", "File Provider", "File Actions": return .indigo
        case "Spotlight", "Spotlight Index": return .yellow
        
        // Security & Authentication
        case "Auth Modifier", "Credential Provider", "SSO Provider", "Kerberos", "CryptoKit", "Authentication": return .red
        
        // Safari & Web
        case "Safari", "Safari Extension", "Content Blocker": return .cyan
        
        // Communication
        case "Share", "Intents", "Intents UI": return .green
        case "Messages", "Message Filter", "Message Classifier", "Message Provider": return .green
        case "CallKit", "Call Directory": return .green
        
        // Media & Creative
        case "Photo Editing", "Photo Project", "Photos": return .pink
        case "Broadcasting", "Broadcast Setup", "Broadcast Upload": return .purple
        case "Audio Unit": return .orange
        
        // System Services
        case "System", "Apple AI", "UI Services", "Services": return .gray
        case "Notifications", "Notification Content", "Notification Service": return .orange
        case "Network Extension", "Network Proxy": return .mint
        case "File System", "iCloud": return .teal
        
        // User Interface
        case "Widget": return .purple
        case "Apple TV", "TV Top Shelf": return .black
        case "Keyboard": return .brown
        case "Settings": return .secondary
        
        // Development & Education
        case "Development", "Xcode Extension": return .blue
        case "Education", "ClassKit": return .green
        
        // Legacy & Special
        case "ScreenSaver": return .orange
        case "Legacy": return .gray
        case "Private": return .secondary
        case "Metrics": return .mint
        
        // Fallback
        default: return .secondary
        }
    }
  
  
}


 struct CheckboxToggleStyle: ToggleStyle {
  func makeBody(configuration: Configuration) -> some View {
    Button(action: {
      configuration.isOn.toggle()
    }) {
      HStack {
        Image(systemName: configuration.isOn ? "checkmark.square" : "square")
          .foregroundColor(configuration.isOn ? .accentColor : .secondary)
        configuration.label
      }
    }
    .buttonStyle(PlainButtonStyle())
  }
}




// MARK: - Data Models

enum ElectionState: String, CaseIterable {
  case use = "+"
  case ignore = "-"
  case debug = "!"
  case superseded = "="
  case unknown = "?"
  case none = ""
  
  var displayName: String {
    switch self {
    case .use: return "Use"
    case .ignore: return "Ignore"
    case .debug: return "Debug"
    case .superseded: return "Superseded"
    case .unknown: return "Unknown"
    case .none: return "Default"
    }
  }
  
  var color: Color {
    switch self {
    case .use: return .green
    case .ignore: return .white
    case .debug: return .blue
    case .superseded: return .red
    case .unknown: return .black
    case .none: return .black
    }
  }
}

struct PluginExtension: Identifiable{
  let identifier: String
  let displayName: String
  let version: String
  let path: String
  let id: String
  let electionState: ElectionState
  let isQuickLook: Bool
  let isApple: Bool
      let sdk: String  
     

    var pluginType: String {
        switch sdk.lowercased() {
        // QuickLook
        case let s where s.contains("quicklook.preview"):
            return "QuickLook"
        case let s where s.contains("quicklook.thumbnail"):
            return "Thumbnail"
        case let s where s.contains("quicklook"):
            return "QuickLook"
            
        // Authentication & Security
        case let s where s.contains("authentication-services-account"):
            return "Auth Modifier"
        case let s where s.contains("authentication-services-credential"):
            return "Credential Provider"
        case let s where s.contains("appsso.idp-extension"):
            return "SSO Provider"
        case let s where s.contains("appsso"):
            return "Kerberos"
        case let s where s.contains("ctk-tokens"):
            return "CryptoKit"
        case let s where s.contains("authentication"):
            return "Authentication"
            
        // Safari & Web
        case let s where s.contains("safari.content-blocker"):
            return "Content Blocker"
        case let s where s.contains("safari.extension"):
            return "Safari Extension"
        case let s where s.contains("safari"):
            return "Safari"
            
        // File Management & Sync
        case let s where s.contains("fileprovider-nonui"):
            return "File Provider"
        case let s where s.contains("fileprovider-actionsui"):
            return "File Actions"
        case let s where s.contains("findersync"):
            return "Finder Sync"
        case let s where s.contains("fileprovider"):
            return "File Provider"
        case let s where s.contains("finder"):
            return "Finder"
        case let s where s.contains("fskit"):
            return "File System"
        case let s where s.contains("storagemanagement"):
            return "iCloud"
            
        // Sharing & Intents
        case let s where s.contains("share-services"):
            return "Share"
        case let s where s.contains("intents-ui-service"):
            return "Intents UI"
        case let s where s.contains("intents-service"):
            return "Intents"
        case let s where s.contains("intents"):
            return "Intents"
        case let s where s.contains("share"):
            return "Share"
            
        // Communication & Messaging
        case let s where s.contains("callkit.call-directory"):
            return "Call Directory"
        case let s where s.contains("identitylookup.message-filter"):
            return "Message Filter"
        case let s where s.contains("identitylookup.classification-ui"):
            return "Message Classifier"
        case let s where s.contains("message-payload-provider"):
            return "Message Provider"
        case let s where s.contains("callkit"):
            return "CallKit"
        case let s where s.contains("message"):
            return "Messages"
            
        // Media & Broadcasting
        case let s where s.contains("broadcast-services-setupui"):
            return "Broadcast Setup"
        case let s where s.contains("broadcast-services-upload"):
            return "Broadcast Upload"
        case let s where s.contains("broadcast"):
            return "Broadcasting"
        case let s where s.contains("audiounit-ui"):
            return "Audio Unit"
        case let s where s.contains("audiounit"):
            return "Audio Unit"
            
        // Photos & Media Editing
        case let s where s.contains("photo-editing"):
            return "Photo Editing"
        case let s where s.contains("photo-project"):
            return "Photo Project"
        case let s where s.contains("photo"):
            return "Photos"
            
        // Notifications
        case let s where s.contains("usernotifications.content-extension"):
            return "Notification Content"
        case let s where s.contains("usernotifications.service"):
            return "Notification Service"
        case let s where s.contains("usernotifications"):
            return "Notifications"
            
        // Networking
        case let s where s.contains("networkextension.app-proxy"):
            return "Network Proxy"
        case let s where s.contains("networkextension"):
            return "Network Extension"
            
        // System & UI Services
        case let s where s.contains("ui-services"):
            return "UI Services"
        case let s where s.contains("services"):
            return "Services"
        case let s where s.contains("keyboard-service"):
            return "Keyboard"
        case let s where s.contains("mlhost"):
            return "System"
        case let s where s.contains("mlruntime"):
            return "Apple AI"
        case let s where s.contains("diagnosticextensions"):
            return "Metrics"
        case let s where s.contains("settings"):
            return "Settings"
            
        // Widgets & TV
        case let s where s.contains("widgetkit-extension"):
            return "Widget"
        case let s where s.contains("widgetkit"):
            return "Widget"
        case let s where s.contains("tv-top-shelf"):
            return "TV Top Shelf"
        case let s where s.contains("tv"):
            return "Apple TV"
            
        // Search & Indexing
        case let s where s.contains("spotlight.index"):
            return "Spotlight Index"
        case let s where s.contains("spotlight"):
            return "Spotlight"
            
        // Educational & Development
        case let s where s.contains("classkit.context-provider"):
            return "ClassKit"
        case let s where s.contains("dt.xcode.extension.source-editor"):
            return "Xcode Extension"
        case let s where s.contains("xcode"):
            return "Development"
        case let s where s.contains("classkit"):
            return "Education"
            
        // Screen Saver & Legacy
        case let s where s.contains("screensaver"):
            return "ScreenSaver"
        case let s where s.contains("legacy"):
            return "Legacy"
        case let s where s.contains("private"):
            return "Private"
            
        // Fallback
        case let s where s.isEmpty:
            return "Extension"
        default:
            return "Extension"
        }
    }
 
    var isEnabled: Bool {
        electionState == .use || electionState == .debug || electionState == .none || electionState == .unknown 
    } 
    var isNotUSE: Bool {
        electionState != .use
    }
}




struct UTIInfo {
  let identifier: String
  let fileExtensions: [String]
  let description: String
  let conformsTo: [String]
  let mimeTypes: [String]
}


enum ConflictType {
  case versionMismatch    // Dark red: older version is active
  case utiConflict       // Dark orange: multiple plugins for same UTI
  case locationWarning   // Light yellow: not in standard app locations
  case duplicatee   // indigo (purple?): duplicates are present

  var color: Color {
    switch self {
    case .versionMismatch: return Color.purple.opacity(0.8)
    case .utiConflict: return Color.indigo.opacity(0.8)
    case .locationWarning: return Color.brown.opacity(0.8)
            case .duplicatee: return Color.indigo.opacity(0.6) 
    }
  }
  
  var description: String {
    switch self {
    case .versionMismatch: return "Older version active"
    case .utiConflict: return "UTI conflict"
    case .locationWarning: return "Non-standard location"
     case .duplicatee: return "Duplicate extension"
     }
  }
}

