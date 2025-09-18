//
//  AdvancedAnalysisView 2.swift
//  PluginKits
//
//  Created by Almahdi Morris Quet on 09/14/25.
//


//
//  AdvancedAnalysisView.swift
//  PluginKits
//
//  Created by Almahdi Morris Quet on 09/12/25.
//
import SwiftUI

struct AdvancedAnalysisView: View {
    @ObservedObject var manager: PluginKitManager
    @State private var selectionn: PluginExtension.ID = ""
    @State private var selectedTab = 0
    
    var versionConflicts: [(identifier: String, extensions: [AdvancedPluginExtension], hasActiveOlderVersion: Bool)] {
        let grouped = Dictionary(grouping: manager.advancedExtensions) { $0.identifier }
        
        return grouped.compactMap { identifier, extensions in
            guard extensions.count > 1 else { return nil }
            
            // Sort by version (newest first)
            let sortedExtensions = extensions.sorted { ext1, ext2 in
                return ext1.version.compare(ext2.version, options: .numeric) == .orderedDescending
            }
            
            let newestVersion = sortedExtensions.first!
            let activeExtensions = extensions.filter { $0.isActive }
            
            // Check if any active version is older than the newest available
            let hasActiveOlderVersion = activeExtensions.contains { activeExt in
                activeExt.version.compare(newestVersion.version, options: .numeric) == .orderedAscending
            }
            
            return (identifier: identifier, extensions: sortedExtensions, hasActiveOlderVersion: hasActiveOlderVersion)
        }.sorted { $0.identifier < $1.identifier }
    }
    
    var utiConflicts: [String: [AdvancedPluginExtension]] {
        var conflicts: [String: [AdvancedPluginExtension]] = [:]
        
        for ext in manager.advancedExtensions {
            for uti in ext.supportedContentTypes {
                conflicts[uti, default: []].append(ext)
            }
        }
        
        return conflicts.filter { $0.value.count > 1 }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
             if manager.isLoading {
                ProgressView("Analyzing QuickLook extensions...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Group {
                    switch selectedTab {
                    case 0:

                        List(selection: $selectionn) {
                            if !versionConflicts.isEmpty {
                                Section("Extensions: duplicated and conflicting versions") {
                                    ForEach(versionConflicts, id: \.identifier) { conflict in
                                        VersionConflictView(conflict: conflict)
                                            .listRowBackground(
                                                conflict.hasActiveOlderVersion ? Color.red.opacity(0.1) : nil
                                            )
                                    }
                                }
                            }
                            
                            if !utiConflicts.isEmpty {
                                Section("UTIs controlled by multiple extensions") {
                                    ForEach(Array(utiConflicts.keys.sorted()), id: \.self) { uti in
                                        UTIConflictDetailView(uti: uti, extensions: utiConflicts[uti] ?? [], manager: manager)
                                    }
                                }
                            }
                        }
                        .listStyle(PlainListStyle())
                                                

                 .alternatingRowBackgrounds(.enabled)      //comment out for macOS13Ventura comaptibility
                                                
                    case 1:
                         ConflictResolutionView(manager: manager)
                        
                    default:
                        EmptyView()
                    }
                }
            }
        }
        .onAppear {
            manager.loadAdvancedAnalysis()
        }
    }
}
