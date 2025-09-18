import SwiftUI
import UniformTypeIdentifiers

@main
struct PluginKitManagerApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView()
      //.textSelection(.enabled)
    }
    
    .windowResizability(.contentSize)
    .defaultSize(width: 1200, height: 800)
  }
}

struct ContentView: View {
  @StateObject private var manager = PluginKitManager()
  @StateObject private var resolutionManager = ConflictResolutionManager(pluginManager: PluginKitManager())
  @State private var selectedTab = 1
   var body: some View {
    NavigationSplitView {
      VStack(alignment: .leading, spacing: 0) {
        // Header
        HStack {
          Image(systemName: "puzzlepiece.extension.fill")
            .font(.title2)
            .foregroundColor(.accentColor)
          Text("PluginKits")
            .font(.title2)
            .fontWeight(.semibold)
          
          Spacer()
          
          Button(action: manager.refresh) {
            Image(systemName: "arrow.clockwise")
          }
          .disabled(manager.isLoading)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        
        Divider()
        
        // Navigation Sidebar
        VStack(spacing: 0) {
          // Navigation buttons (top half)
          List(selection: $selectedTab) {                
            Button(action: {
              selectedTab = 0
              manager.loadExtensions()
            }) {
              HStack {
                Image(systemName: "puzzlepiece.extension")
                VStack(alignment: .leading, spacing: 2) {
                  Text("All Plug-ins List")
                   } 
                }
              }
              .buttonStyle(PlainButtonStyle())
              .tag(0)   
            
            Button(action: {
              selectedTab = 1
              manager.loadQuickLookExtensions()
            }) {
              HStack {
                Image(systemName: "rectangle.and.text.magnifyingglass")
                VStack(alignment: .leading, spacing: 2) {
                  Text("Quick Look Specific")
                }
  
              }
            }
            .buttonStyle(PlainButtonStyle())
            .tag(1)
            HStack{
            Label("Conflicts", systemImage: "checklist")
          }
                        .tag(2)
}
          .listStyle(SidebarListStyle())
          
          Divider()
          
          // Resolution Progress (bottom half)
          VStack(alignment: .leading, spacing: 8) {
            CompactInfoView()
//            SquareInfoView()
          }
          .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
          .frame(minWidth: 200, minHeight: 300)
        }
      }
       .navigationSplitViewColumnWidth(
            min: 2, ideal: 350, max: 350)
    } detail: {
      Group {
        switch selectedTab {
        case 0:
          AllPluginsView(manager: manager)
        case 1:
          QuickLookExtensionsView(manager: manager)
                 case 2: 
                 ConflictResolutionView(manager: manager)  // Pass binding
        default:
          AllPluginsView(manager: manager)
        }
      }
      
    }
      .toolbar {
        ToolbarItemGroup(placement: .secondaryAction) {
   if manager.lastDeregisteredPath.last != nil {
        Button("Undo Last Deregister") {
            manager.undoLastDeregistration()
        }        }
     }
        
        }
        
        
//            Button("Quick Swap") {
//                performHotSwap()
//            }
//            .disabled(hotSwapConflict == nil)
//            .help("Swaps between two Quick Look previewer extensions.")
////            Button("Refresh") {
////                manager.refresh()
////            }
////            .disabled(manager.isLoading)
//        }
    
//  }
    .onAppear {
      manager.refresh()
//          manager.detectConflicts(for: manager.allExtensions)

    
    
    }
    .alert("Error", isPresented: .constant(manager.error != nil)) {
      Button("OK") { manager.error = nil }
    } message: {
      Text(manager.error ?? "")
    } 
     .popover(isPresented: $manager.showingPluginDetails) {
      if let plugin = manager.selectedPluginDetails {
        PluginDetailsView(plugin: plugin, manager: manager)
      }
    }
  }
}

// Compact version for sidebar
struct CompactResolutionStepView: View {
    let step: ResolutionStep
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: step.status.icon)
                .foregroundColor(step.status.color)
                .frame(width: 12)
            
            Text(step.description)
                .font(.caption)
                .lineLimit(2)
                .truncationMode(.tail)
            
            Spacer(minLength: 0)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Sort Config
enum SortField: String, CaseIterable {
    case name = "Name"
    case identifier = "Identifier" 
    case version = "Version"
    case status = "Status"
    case type = "Type"
    case path = "Path"
    
    var systemImage: String {
        switch self {
        case .name: return "textformat"
        case .identifier: return "tag"
        case .version: return "number"
        case .status: return "circle"
        case .type: return "app"
        case .path: return "folder"
        }
    }
}

enum SortOrder {
    case ascending, descending
    
    var systemImage: String {
        switch self {
        case .ascending: return "chevron.up"
        case .descending: return "chevron.down"
        }
    }
    
    mutating func toggle() {
        self = (self == .ascending) ? .descending : .ascending
    }
}

// MARK: - Sortable Header Button
struct SortableHeaderButton: View {
    let field: SortField
    let currentField: SortField
    let currentOrder: SortOrder
    let action: (SortField) -> Void
    
    var body: some View {
        Button(action: { action(field) }) {
            HStack(spacing: 4) {
                Image(systemName: field.systemImage)
                    .font(.caption)
                Text(field.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                
                if currentField == field {
                    Image(systemName: currentOrder.systemImage)
                        .font(.caption2)
                        .foregroundColor(.accentColor)
                }
            }
            .foregroundColor(currentField == field ? .accentColor : .secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                currentField == field ? 
                Color.accentColor.opacity(0.1) : 
                Color.clear
            )
            .cornerRadius(4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// Adds '.isOff" to toggles so we can use the inverse of the binding
extension Toggle {
    init<V>(_ titleKey: LocalizedStringKey, isOff binding: Binding<V>) where Label == Text, V == Bool {
        self.init(titleKey, isOn: Binding(
            get: { !binding.wrappedValue },
            set: { binding.wrappedValue = !$0 }
        ))
    }
    
    init<S, V>(_ title: S, isOff binding: Binding<V>) where Label == Text, S : StringProtocol, V == Bool {
        self.init(title, isOn: Binding(
            get: { !binding.wrappedValue },
            set: { binding.wrappedValue = !$0 }
        ))
    }
}
