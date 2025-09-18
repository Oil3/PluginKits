import SwiftUI

// MARK: - Main Conflict Resolution View

struct ConflictResolutionView: View {
    @ObservedObject var manager: PluginKitManager
    @StateObject private var resolutionManager: ConflictResolutionManager
    @State private var selectedTab = 0
    
    init(manager: PluginKitManager) {
        self.manager = manager
        self._resolutionManager = StateObject(wrappedValue: ConflictResolutionManager(pluginManager: manager))
    }
    
    var extensionConflicts: [ExtensionConflict] {
        let grouped = Dictionary(grouping: manager.advancedExtensions) { $0.identifier }
        
        return grouped.compactMap { identifier, extensions in
            guard extensions.count > 1 else { return nil }
            
            let sortedExtensions = extensions.sorted { ext1, ext2 in
                return ext1.version.compare(ext2.version, options: .numeric) == .orderedDescending
            }
            
            return ExtensionConflict(
                identifier: identifier,
                displayName: extensions.first?.displayName ?? identifier,
                extensions: sortedExtensions,
                conflictType: .duplicates
            )
        }.sorted { $0.displayName < $1.displayName }
    }
    
    var utiConflictGroups: [UTIConflictGroup] {
        var conflicts: [String: [AdvancedPluginExtension]] = [:]
        
        // Group UTIs by conflicting extensions
        for ext in manager.advancedExtensions {
            for uti in ext.supportedContentTypes {
                conflicts[uti, default: []].append(ext)
            }
        }
        
        let conflictingUTIs = conflicts.filter { $0.value.count > 1 }
        
        // Group by extension combinations
        var extensionGroups: [Set<String>: [String]] = [:]
        
        for (uti, extensions) in conflictingUTIs {
            let extensionIds = Set(extensions.map { $0.uuid })
            extensionGroups[extensionIds, default: []].append(uti)
        }
        
        return extensionGroups.map { (extensionIds, utis) in
            let extensions = manager.advancedExtensions.filter { extensionIds.contains($0.uuid) }
            return UTIConflictGroup(utis: utis.sorted(), extensions: extensions)
        }.sorted { $0.displayUTIs < $1.displayUTIs }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Conflict Resolution")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Resolve extension and UTI conflicts")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(extensionConflicts.count) extension conflicts")
                        .foregroundColor(.red)
                        .font(.caption)
                    Text("\(utiConflictGroups.count) UTI competing groups")
                        .foregroundColor(.orange)
                        .font(.caption)
                }
            }
            .padding()
            
            // Tab Selection
            Picker("Conflict Type", selection: $selectedTab) {
                Text("Extension Conflicts").tag(0)
                Text("UTI Conflicts").tag(1)
                Text("Details").tag(2)
            }
            .labelsHidden()
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            Divider()
            
            // Content
            Group {
                switch selectedTab {
                case 0:
                    ExtensionConflictsView(
                        conflicts: extensionConflicts,
                        resolutionManager: resolutionManager
                    )
                case 1:
                    UTIConflictsView(
                        conflictGroups: utiConflictGroups,
                        resolutionManager: resolutionManager
                    )
                case 2:
                AdvancedAnalysisView(manager: manager)
                
                
                                    //ResolutionProgressView(resolutionManager: resolutionManager)
                default:
                    EmptyView()
                }
            }
        }
    }
}

// MARK: - Extension Conflicts View

struct ExtensionConflictsView: View {
    let conflicts: [ExtensionConflict]
    @ObservedObject var resolutionManager: ConflictResolutionManager
    @State private var selectedConflicts: Set<ExtensionConflict.ID> = []
     var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if conflicts.isEmpty {
                VStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.green)
                    Text("All extensions appear unique.")
                        .font(.title3)
                        .fontWeight(.medium)
                    Text("One extension, one location.")
                        .font(.caption)
                        .foregroundColor(.secondary)    
                        Text("Manual management stays enabled.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Select conflicts to resolve:")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button("Select All") {
                            selectedConflicts = Set(conflicts.map { $0.id })
                        }
                        .disabled(selectedConflicts.count == conflicts.count)
                        
                        Button("Clear Selection") {
                            selectedConflicts.removeAll()
                        }
                        .disabled(selectedConflicts.isEmpty)
                        
                        Button("Resolve Selected") {
                            resolveSelectedConflicts()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(selectedConflicts.isEmpty || resolutionManager.isResolving)
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    List(conflicts, id: \.id) { conflict in
                        ExtensionConflictRow(
                            conflict: conflict,
                            isSelected: selectedConflicts.contains(conflict.id),
                            onToggle: { isSelected in
                                if isSelected {
                                    selectedConflicts.insert(conflict.id)
                                } else {
                                    selectedConflicts.remove(conflict.id)
                                }
                            }
                        )
                    }
                    .listStyle(PlainListStyle())
                }
            }
        }
    }
    
    private func resolveSelectedConflicts() {
        let conflictsToResolve = conflicts.filter { selectedConflicts.contains($0.id) }
        
        Task {
            for conflict in conflictsToResolve {
                await resolutionManager.resolveExtensionConflict(conflict)
            }
        }
      
    }
}

struct ExtensionConflictRow: View {
    let conflict: ExtensionConflict
    let isSelected: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
                Button(action: { onToggle(!isSelected) }) {

        HStack {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundColor(isSelected ? .accentColor : .secondary)
            
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: conflict.conflictType.color == .red ? "exclamationmark.triangle.fill" : "exclamationmark.triangle")
                        .foregroundColor(conflict.conflictType.color)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(conflict.displayName)
                            .font(.headline)
                        Text(conflict.identifier)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(conflict.extensions.count) versions")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(conflict.conflictType.color.opacity(0.2))
                            .foregroundColor(conflict.conflictType.color)
                            .cornerRadius(8)
                        
                        if conflict.hasActiveOlderVersion {
                            Text("Older version active")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
                
                VStack(spacing: 4) {
                    ForEach(conflict.extensions, id: \.uuid) { ext in
                        HStack {
                            Circle()
                                .fill(ext.isActive ? (ext == conflict.extensions.first ? Color.green : Color.red) : Color.gray)
                                .frame(width: 8, height: 8)
                            
                            Text("v\(ext.version)")
                                .font(.subheadline)
                                .fontWeight(ext == conflict.extensions.first ? .semibold : .regular)
                            
                            if ext == conflict.extensions.first {
                                Text("Latest")
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.2))
                                    .foregroundColor(.blue)
                                    .cornerRadius(4)
                            }
                            
                            if ext.isActive {
                                Text("Active")
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(ext == conflict.extensions.first ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                                    .foregroundColor(ext == conflict.extensions.first ? .green : .red)
                                    .cornerRadius(4)
                            }
                            
                            Spacer()
                            
                            Text(ext.path)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                    }
                }
                .padding(.leading, 20)
            }
                        .contentShape(Rectangle())

        }

        .padding(.vertical, 4)
    }
                        .buttonStyle(PlainButtonStyle())
}
}

// MARK: - UTI Conflicts View

struct UTIConflictsView: View {
    let conflictGroups: [UTIConflictGroup]
    @ObservedObject var resolutionManager: ConflictResolutionManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if conflictGroups.isEmpty {
                VStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.green)
                    Text("No UTI Conflicts")
                        .font(.title3)
                        .fontWeight(.medium)
                    Text("All UTIs are handled by single extensions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(conflictGroups) { group in
                            UTIConflictGroupView(
                                conflictGroup: group,
                                resolutionManager: resolutionManager
                            )
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

struct UTIConflictGroupView: View {
    let conflictGroup: UTIConflictGroup
    @ObservedObject var resolutionManager: ConflictResolutionManager
    @State private var selectedMasterExtension: AdvancedPluginExtension?
    @State private var enforceMode = false
    @State private var showingConfirmation = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            Text("UTI Competing Group")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Main conflict display
            HStack(spacing: 16) {
                // Left extension(s)
                VStack(alignment: .leading, spacing: 8) {
//                    Text("Extension 1")
//                        .font(.subheadline)
//                        .fontWeight(.medium)
//                        .foregroundColor(.secondary)
                    
                    if let firstExt = conflictGroup.extensions.first {
                        ExtensionCardView(
                            extension: firstExt,
                            isMaster: selectedMasterExtension?.uuid == firstExt.uuid,
                            onSelectAsMaster: { selectedMasterExtension = firstExt }
                        )
                    }
                }
                .frame(maxWidth: .infinity)
                
                // Center - UTIs
                VStack(spacing: 8) {
                    Text("Conflicting UTIs")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                    
                    VStack(spacing: 4) {
                        ForEach(conflictGroup.utis.prefix(5), id: \.self) { uti in
                            Text(uti)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.orange.opacity(0.1))
                                .foregroundColor(.orange)
                                .cornerRadius(6)
                        }
                        
                        if conflictGroup.utis.count > 5 {
                            Text("+ \(conflictGroup.utis.count - 5) more")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(width: 200)
                
                // Right extension(s)
                VStack(alignment: .leading, spacing: 8) {
//                    Text("Extension 2")
//                        .font(.subheadline)
//                        .fontWeight(.medium)
//                        .foregroundColor(.secondary)
                    
                    if conflictGroup.extensions.count > 1{
                     let secondExt = conflictGroup.extensions[1] 
                        ExtensionCardView(
                            extension: secondExt,
                            isMaster: selectedMasterExtension?.uuid == secondExt.uuid,
                            onSelectAsMaster: { selectedMasterExtension = secondExt }
                        )
                    }
                }
                .frame(maxWidth: .infinity)
            }
            
            // Additional extensions (if more than 2)
            if conflictGroup.extensions.count > 2 {
                VStack(spacing: 8) {
                    Text("Additional Extensions")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 16) {
                        ForEach(Array(conflictGroup.extensions.dropFirst(2).enumerated()), id: \.offset) { index, ext in
                            ExtensionCardView(
                                extension: ext,
                                isMaster: selectedMasterExtension?.uuid == ext.uuid,
                                onSelectAsMaster: { selectedMasterExtension = ext }
                            )
                        }
                    }
                }
            }
            
            Divider()
            
            // Resolution controls
            VStack(spacing: 12) {
                HStack {
                                    Spacer()

//                    Toggle("Delete the other?", isOn: $enforceMode)
//                        .toggleStyle(CheckboxToggleStyle())
                    
                    
                    Button(
                  selectedMasterExtension == nil ? "Select master" : "Apply") {
                        showingConfirmation = true
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedMasterExtension == nil || resolutionManager.isResolving)
                }
                
                if selectedMasterExtension != nil {
                    Text(enforceMode ? 
                         "Master extension will be set to 'use', others will be ignored and removed" :
                         "Master extension will be set to 'use', others will be set to 'ignore'")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(12)
        .confirmationDialog(
            "Resolve UTI Conflict",
            isPresented: $showingConfirmation,
            titleVisibility: .hidden,
            
        ) {
          Button("OK") {
                if let master = selectedMasterExtension {
                    Task {
                        await resolutionManager.resolveUTIConflict(conflictGroup, masterExtension: master, enforce: enforceMode)
                    }
                }
            }
            .keyboardShortcut(.return, modifiers: [])
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(enforceMode ? 
                 "Additionally puts yielding extension(s) in the trash." :
                 "Sets election preferences for the conflicting extensions.")
        }
    }
}
struct ExtensionCardView: View {
    let extension: AdvancedPluginExtension
    let isMaster: Bool
    let onSelectAsMaster: () -> Void
    
    var currentElectionStatus: String {
        switch `extension`.electionValue {
        case 1: return "In Use"
        case 2: return "Deactivated"
        case 257: return "Active-Debug"
        default: return "Default"
        }
    }
    
    var electionColor: Color {
        switch `extension`.electionValue {
        case 1: return .green      // In Use
        case 2: return .red        // Ignored
        case 257: return .blue     // Debug
        default: return .gray      // Default
        }
    }
    
    var body: some View {
        Button(action: onSelectAsMaster) {
          VStack(alignment: .leading, spacing: 8) {
            HStack {
              Image(systemName: isMaster ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isMaster ? .green : .secondary)
              
              VStack(alignment: .leading, spacing: 2) {
                Text(`extension`.displayName)
                  .font(.subheadline)
                  .fontWeight(.medium)
                  .lineLimit(1)
                
                HStack(spacing: 8) {
                  Text("v\(`extension`.version)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                  
                  // Election status badge
                  Text(currentElectionStatus)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(electionColor.opacity(0.2))
                    .foregroundColor(electionColor)
                    .cornerRadius(4)
                }
              }
              
              Spacer()
              
              VStack(alignment: .trailing, spacing: 2) {
                if `extension`.isApple {
                  Text("Apple/System")
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.gray)
                    .cornerRadius(4)
                }
              }
            }
            
            if isMaster {
              Text("Master")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.green)
            }
            
            Text(`extension`.path)
              .font(.caption)
              .foregroundColor(.secondary)
              .lineLimit(2)
              .truncationMode(.middle)
          }
//          .background(xx/x)
                  .contentShape(Rectangle())

        }
        .buttonStyle(PlainButtonStyle())
        .padding(8)
        .background(isMaster ? Color.green.opacity(0.1) : Color.secondary.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isMaster ? Color.green : Color.clear, lineWidth: 2)
        )
        .cornerRadius(8)
    }
}
//    var body: some View {
//                            Button(action: onSelectAsMaster) {
//
//        VStack(alignment: .leading, spacing: 8) {
//
//            HStack {
//                    Image(systemName: isMaster ? "checkmark.circle.fill" : "circle")
//                        .foregroundColor(isMaster ? .green : .secondary)
//                
//                
////VStack(alignment: .leading, spacing: 2) {
//                    Text(`extension`.displayName)
//                        .font(.subheadline)
//                        .fontWeight(.medium)
//                        .lineLimit(1)
//                    
//             //       HStack(spacing: 8) {
//                        Text("v\(`extension`.version)")
//                            .font(.caption)
//                            .foregroundColor(.secondary)
//                        
//                        // Election status badge
//                        Text(currentElectionStatus)
//                            .font(.caption)
//                            .padding(.horizontal, 6)
//                            .padding(.vertical, 2)
//                            .background(electionColor.opacity(0.2))
//                            .foregroundColor(electionColor)
//                            .cornerRadius(4)
//                    }
//                }
//                
//                Spacer()
//                
//                VStack(alignment: .trailing, spacing: 2) {
//                    if `extension`.isApple {
//                        Text("Apple/System")
//                            .font(.caption)
//                            .padding(.horizontal, 6)
//                            .padding(.vertical, 2)
//                            .background(Color.gray.opacity(0.2))
//                            .foregroundColor(.gray)
//                            .cornerRadius(4)
//                    }
//                }
//            }
//            
//            if isMaster {
//                Text("Master")
//                    .font(.caption)
//                    .fontWeight(.medium)
//                    .foregroundColor(.green)
//            }
//            
//            Text(`extension`.path)
//                .font(.caption)
//                .foregroundColor(.secondary)
//                .lineLimit(2)
//                .truncationMode(.middle)
//        }
//        }
//.frame(maxWidth: .infinity)
//                                .buttonStyle(PlainButtonStyle())
//
//.contentShape(Rectangle())
//
//        .padding(8)
//        .background(isMaster ? Color.green.opacity(0.1) : Color.secondary.opacity(0.1))
//        .overlay(
//            RoundedRectangle(cornerRadius: 8)
//                .stroke(isMaster ? Color.green : Color.clear, lineWidth: 2)
//        )
//        .cornerRadius(8)
//    }
//}

// MARK: - Resolution Progress View

struct ResolutionProgressView: View {
    @ObservedObject var resolutionManager: ConflictResolutionManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Resolution Progress")
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.horizontal)
                .padding(.top)
            
            if resolutionManager.resolutionSteps.isEmpty {
                VStack {
                    Image(systemName: "gearshape")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No Active Resolution")
                        .font(.title3)
                        .fontWeight(.medium)
                    Text("Select conflicts to resolve and progress will appear here")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(resolutionManager.resolutionSteps) { step in
                            ResolutionStepView(step: step)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

struct ResolutionStepView: View {
    let step: ResolutionStep
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: step.status.icon)
                .foregroundColor(step.status.color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(step.description)
                    .font(.subheadline)
                
                if let error = step.error {
                    Text("Error: \(error)")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            Spacer()
            
            if step.status == .inProgress {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .padding(.vertical, 4)
    }
}
