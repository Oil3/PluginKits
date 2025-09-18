//
//  AllPluginsView.swift
//  PluginKits
//
//  Created by Almahdi Morris Quet on 09/13/25.
//

import SwiftUI


struct AllPluginsView: View {
    
    /// Tracks which extensions just got deregistered for undo banners
    @State private var showingUndoBanners: [String: String] = [:] // [extensionID: extensionName]
    @ObservedObject var manager: PluginKitManager
    @State private var searchText = ""
   //                        @State private var offsett: CGFloat = 0

//    @State private var hideAppleExtensions = false
  @SceneStorage("hideAppleExtensions") private var hideAppleExtensions = false
    @State private var showQuickLookOnly = false
    @State private var sortField: SortField = .name
    @State private var sortOrder: SortOrder = .ascending
        @State private var selectionn: PluginExtension.ID = ""
    var filteredAndSortedExtensions: [PluginExtension] {
        var extensions = manager.allExtensions
        if !extensions.isEmpty { extensions.removeFirst()}
        // Apply filters
        if hideAppleExtensions {
            extensions = extensions.filter { !$0.isApple }
        }
        
        if showQuickLookOnly {
            extensions = extensions.filter { $0.isQuickLook }
        }
        
        if !searchText.isEmpty {
            extensions = extensions.filter { ext in
                ext.displayName.localizedCaseInsensitiveContains(searchText) ||
                ext.identifier.localizedCaseInsensitiveContains(searchText) ||
                ext.sdk.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply sorting
        return sortExtensions(extensions, by: sortField, order: sortOrder)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("All extensions in registry")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(filteredAndSortedExtensions.count) plugins")
                    .foregroundColor(.secondary)
                                            .font(.caption)

            }
            .padding()
                             
            // Filters and Search
//            VStack(spacing: 8) {
//              
//            }
//            .padding(.horizontal)
//            .padding(.bottom)
//            
            // Sort Controls
            HStack {
                Text("Sort by:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
//                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(SortField.allCases, id: \.self) { field in
                            SortableHeaderButton(
                                field: field,
                                currentField: sortField,
                                currentOrder: sortOrder,
                                action: handleSort
                            )
                        }
                    }
                    .padding(.horizontal, 4)
//                }
                                HStack {
               Spacer()

                    Toggle("Show System", isOff: $hideAppleExtensions)
                        .toggleStyle(.automatic)
     // .frame(maxWidth: .infinity, alignment: .leading)

                     //}
//                    Toggle("QuickLook Only", isOn: $showQuickLookOnly)
//                        .toggleStyle(CheckboxToggleStyle())
//                         Image(systemName: "magnifyingglass")
//                        .foregroundColor(.secondary)
                        
                    TextField("Search...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(maxWidth: 90)
             
                   // Spacer()
                }
            .font(.caption)
                    .fontWeight(.medium)        
                                            .foregroundColor(.secondary)
//                                                                    

    }
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            Divider()
            


//            if manager.isLoading {
//                ProgressView("Loading plugins...")
//                    .frame(maxWidth: .infinity, maxHeight: .infinity)
//            } else {
                List(filteredAndSortedExtensions, id: \.id, selection: $selectionn ) { ext in
                  SimplePluginRowView(ext: ext, manager: manager)
//                }
//                .listStyle(PlainListStyle())r
                .listStyle(.bordered)
                                                           

                 .alternatingRowBackgrounds(.enabled)      //comment out for macOS13Ventura comaptibility
                                                 
           //comment out for macOS13Ventura comaptibility    
  //   #warning("disabled for compatibily >= macos13")   //.defaultScrollAnchor(.center)
       .onTapGesture(count: 2, perform: {
    
            manager.loadPluginDetails(for: ext.identifier)

    
    
    })
   

            }
            
        }
//          .offset(y: offsett) // Apply offset to the content
//            .gesture(
//                DragGesture()
//                    .onChanged { value in
//                        offsett += value.translation.height 
// NSLog("offsett: \(offsett)") 
//                     }    )
    }
    
    private func handleSort(_ field: SortField) {
        if sortField == field {
            sortOrder.toggle()
        } else {
            sortField = field
            sortOrder = .ascending
        }
    }
    
 
    
    private func sortExtensions(_ extensions: [PluginExtension], by field: SortField, order: SortOrder) -> [PluginExtension] {
        let sorted = extensions.sorted { ext1, ext2 in
            let result: Bool
            
            switch field {
            case .name:
                result = ext1.displayName.localizedCaseInsensitiveCompare(ext2.displayName) == .orderedAscending
            case .identifier:
                result = ext1.identifier.localizedCaseInsensitiveCompare(ext2.identifier) == .orderedAscending
            case .version:
                result = ext1.version.compare(ext2.version, options: .numeric) == .orderedAscending
            case .status:
                result = ext1.electionState.rawValue < ext2.electionState.rawValue
      case .type:
     if ext1.pluginType != ext2.pluginType {
        result = ext1.pluginType.localizedCaseInsensitiveCompare(ext2.pluginType) == .orderedAscending
    } else {
        // Within same type, sort by name
        result = ext1.displayName.localizedCaseInsensitiveCompare(ext2.displayName) == .orderedAscending
    }
            case .path:
                result = ext1.path.localizedCaseInsensitiveCompare(ext2.path) == .orderedAscending
            }
            
            return order == .ascending ? result : !result
        }
        
        return sorted
    }
    
    private func extensionTypeScore(_ ext: PluginExtension) -> Int {
        if ext.isApple { return 0 }
        if ext.isQuickLook { return 1 }
        return 2
    }
}

// MARK: - QuickLook Extensions View
struct QuickLookExtensionsView: View {
    @ObservedObject var manager: PluginKitManager
  @SceneStorage("hideAppleExtensions") private var hideAppleExtensions = false
    @State private var sortField: SortField = .name
    @State private var sortOrder: SortOrder = .ascending
    @State private var selectionn: PluginExtension.ID = ""
        @State private var searchText = ""
@State private var conflicts: [String: ConflictType] = [:] 
   var filteredAndSortedExtensions: [PluginExtension] {
        var extensions = manager.quickLookExtensions
        if !extensions.isEmpty { extensions.removeFirst()}
         if hideAppleExtensions {
            extensions = extensions.filter { !$0.isApple }
        }
                if !searchText.isEmpty {
            extensions = extensions.filter { ext in
                ext.displayName.localizedCaseInsensitiveContains(searchText) ||
                ext.identifier.localizedCaseInsensitiveContains(searchText) ||
                ext.sdk.localizedCaseInsensitiveContains(searchText)
            }}
        
        return sortExtensions(extensions, by: sortField, order: sortOrder)
    }
  

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
//                VStack(alignment: .leading, spacing: 4) {
                    Text("Quick Look Previewer Extensions")
                        .font(.title2)
                        .fontWeight(.semibold)
//                    Text("All plug-ins known by the system, including duplicates.")
//                        .font(.caption)
//                        .foregroundColor(.secondary)
//                }
                
                Spacer()
//                
//                VStack(alignment: .trailing, spacing: 4) {
                
                    
                    Text("\(filteredAndSortedExtensions.count) extensions")
                        .foregroundColor(.secondary)
                        .font(.caption)
//                }
            }
            .padding()
            
            // Sort Controls
            HStack {
                Text("Sort by:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
//                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach([SortField.name, .version, .status, .path], id: \.self) { field in
                            SortableHeaderButton(
                                field: field,
                                currentField: sortField,
                                currentOrder: sortOrder,
                                action: handleSort
                            )
                        }
                    }
                    .padding(.horizontal, 4)
//                }
Spacer()
                    Toggle("Show System", isOff: $hideAppleExtensions)
     .toggleStyle(.automatic)
     
                     TextField("Search...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(maxWidth: 90)
             
                            //      Spacer()
//                
//                Button(action: resetSort) {
//                    Image(systemName: "arrow.clockwise")
//                        .font(.caption)
//                }
//                .buttonStyle(PlainButtonStyle())
//                .help("Reset to default sort")
            }
                       .font(.caption)
                    .fontWeight(.medium)        
                                            .foregroundColor(.secondary)

            .padding(.horizontal)
            .padding(.bottom, 8)
            
            Divider()
//            
//            if manager.isLoading {
//                ProgressView("Loading QuickLook extensions...")
//                    .frame(maxWidth: .infinity, maxHeight: .infinity)
//            } else {
//                List(filteredAndSortedExtensions, id: \.id  ) { ext in
                List(filteredAndSortedExtensions, id: \.id, selection: $selectionn) { ext in
                SimplePluginRowView(ext: ext, manager: manager, conflicts: conflicts)
//                }
               
                                                 

                 .alternatingRowBackgrounds(.enabled)      //comment out for macOS13Ventura comaptibility
                                                 //comment out for macOS13Ventura comaptibility
                 .listStyle(PlainListStyle())
                                            
    .onTapGesture(count: 2, perform: {
    
            manager.loadPluginDetails(for: ext.identifier)
    })
             }
                   .onAppear {
                   DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
updateConflicts()
        }
        manager.refresh()
}
//        .onChange(of: manager.quickLookExtensions) { _ in
//            updateConflicts()
//        }
        }
    }
       private func updateConflicts() {
//        conflicts = manager.detectConflicts(for: manager.allExtensions)
        conflicts = manager.detectConflicts(for: manager.quickLookExtensions)
      //  print("Updated conflicts: \(conflicts.count)")
        manager.loadQuickLookExtensions()
    }
    private func handleSort(_ field: SortField) {
        if sortField == field {
            sortOrder.toggle()
        } else {
            sortField = field
            sortOrder = .ascending
        }
    }
    
    private func resetSort() {
        sortField = .name
        sortOrder = .ascending
    }
    
    private func sortExtensions(_ extensions: [PluginExtension], by field: SortField, order: SortOrder) -> [PluginExtension] {
        let sorted = extensions.sorted { ext1, ext2 in
            let result: Bool
            
            switch field {
            case .name:
                result = ext1.displayName.localizedCaseInsensitiveCompare(ext2.displayName) == .orderedAscending
            case .identifier:
                result = ext1.identifier.localizedCaseInsensitiveCompare(ext2.identifier) == .orderedAscending
            case .version:
                result = ext1.version.compare(ext2.version, options: .numeric) == .orderedAscending
            case .status:
                // Sort by election state priority
                let priority1 = electionStatePriority(ext1.electionState)
                let priority2 = electionStatePriority(ext2.electionState)
                if priority1 != priority2 {
                    result = priority1 < priority2
                } else {
                    result = ext1.displayName.localizedCaseInsensitiveCompare(ext2.displayName) == .orderedAscending
                }
            case .type:
                let type1 = extensionTypeScore(ext1)
                let type2 = extensionTypeScore(ext2)
                if type1 != type2 {
                    result = type1 < type2
                } else {
                    result = ext1.displayName.localizedCaseInsensitiveCompare(ext2.displayName) == .orderedAscending
                }
            case .path:
                result = ext1.path.localizedCaseInsensitiveCompare(ext2.path) == .orderedAscending
            }
            
            return order == .ascending ? result : !result
        }
        
        return sorted
    }
    
    private func electionStatePriority(_ state: ElectionState) -> Int {
        switch state {
        case .use: return 0
        case .debug: return 1
        case .none: return 2
        case .ignore: return 3
        case .superseded: return 4
        case .unknown: return 5
        }
    }
    
    private func extensionTypeScore(_ ext: PluginExtension) -> Int {
        if ext.isApple { return 0 }
        return 1
    }
}
