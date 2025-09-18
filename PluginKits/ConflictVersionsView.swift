//
//  AdvancedAnalysisView.swift
//  PluginKits
//
//  Created by Almahdi Morris Quet on 09/12/25.
//
import SwiftUI


struct VersionConflictView: View {
    let conflict: (identifier: String, extensions: [AdvancedPluginExtension], hasActiveOlderVersion: Bool)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: conflict.hasActiveOlderVersion ? "exclamationmark.triangle.fill" : "exclamationmark.triangle")
                    .foregroundColor(conflict.hasActiveOlderVersion ? .red : .orange)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(conflict.extensions.first?.displayName ?? "Unknown")
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
                        .background(conflict.hasActiveOlderVersion ? Color.red.opacity(0.2) : Color.orange.opacity(0.2))
                        .foregroundColor(conflict.hasActiveOlderVersion ? .red : .orange)
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
    }
}


struct AdvancedPluginExtension: Equatable {
  static func == (lhs: AdvancedPluginExtension, rhs: AdvancedPluginExtension) -> Bool {
    false
  }
  
  let identifier: String
  let displayName: String
  let version: String
  let path: String
  let uuid: String
  let supportedContentTypes: [String]
  let bundleInfo: [String: Any]
  let isApple: Bool
   var electionValue: Int  // Store the raw value
    
    var isActive: Bool {
        return electionValue != 2// || electionValue == 257  // Active or Debug
    }
    
    var electionStatus: String {
        switch electionValue {
        case 1: return "Active"
        case 2: return "Disabled" 
        case 257: return "Debug"
        default: return "Unknown"
     }
     }
     }   

 
struct PluginDetailsView: View {
    let plugin: AdvancedPluginExtension
   // @Environment(\.dismiss) private var dismiss
    @ObservedObject var manager: PluginKitManager   
    
    var body: some View {

        VStack {
            List {
              Section("\(plugin.displayName) - Details") {
                DetailRow(key: "Display Name", value: plugin.displayName)
                DetailRow(key: "Identifier", value: plugin.identifier)
                DetailRow(key: "Version", value: plugin.version)
                DetailRow(key: "UUID", value: plugin.uuid)
                DetailRow(key: "Path", value: plugin.path)
                  .textSelection(.enabled)
                DetailRow(key: "Apple Extension", value: plugin.isApple ? "Yes" : "No")
                DetailRow(key: "Active", value: plugin.isActive ? "Yes" : "No")
              }
              if !plugin.supportedContentTypes.isEmpty {
                Section("\(plugin.displayName) - Supported Content Types") {
                  ForEach(plugin.supportedContentTypes, id: \.self) { uti in
                    HStack {
                      VStack(alignment: .leading, spacing: 2) {
                        Text(uti)
                        //.textSelection(.enabled)
                        
                        // Show file extension inline
                        if let extension = manager.getFileExtension(for: uti){
                          Text(".\(extension)")
                            .font(.caption)
                            .foregroundColor(.blue)
                          //.textSelection(.enabled)
                        } else {
                          Text("Loading...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                      }
                      Spacer()
                    }
                    .onAppear {
                      manager.loadUTIExtension(for: uti)
                    }
                  }
                }
              }
              
              Section("\(plugin.displayName) - Advanced") {
                ForEach(Array(plugin.bundleInfo.keys.sorted()), id: \.self) { key in
                  BundleInfoRow(key: key, value: plugin.bundleInfo[key])
                }
              }
            }
//            
                                                            

                 .alternatingRowBackgrounds(.enabled)      //comment out for macOS13Ventura comaptibility
                                                 //comment out for macOS13Ventura comaptibility
            .navigationTitle("\(plugin.displayName) Details")
 //             .toolbar {
//                ToolbarItem(placement: .automatic) {
//                    Button("Done") {
//                        dismiss()
//                    }
//                }
//            
//        }
    }
            .frame(width: 700, height: 600)
            .background(.clear)


}
}
struct BundleInfoRow: View {
    let key: String
    let value: Any?
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(key)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if isDictionary || isArray {
                    Spacer()
                    Button(action: { isExpanded.toggle() }) {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } 
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .contentShape(Rectangle())
            .onTapGesture(count: 2) {
                if isDictionary || isArray {
                    isExpanded.toggle()
                }
            }
            //.onTapGesture(count: 1) {
//            }
            
            if let dict = value as? [String: Any] {
                HStack {
                    Text("Dictionary (\(dict.count) items)")
                        .foregroundColor(.blue)
                    Spacer()
                }
                
                if isExpanded {
                    ForEach(Array(dict.keys.sorted()), id: \.self) { subKey in
                        BundleInfoRow(key: subKey, value: dict[subKey])
                            .padding(.leading, 16)
                    }
                }
            } else if let array = value as? [Any] {
                HStack {
                    Text("Array (\(array.count) items)")
                        .foregroundColor(.green)
                    Spacer()
                }
                
                if isExpanded {
                    ForEach(Array(array.enumerated()), id: \.offset) { index, item in
                        BundleInfoRow(key: "[\(index)]", value: item)
                            .padding(.leading, 16)
                    }
                }
            } else {
                Text("\(value ?? "nil")")
                    //.textSelection(.enabled)
            }
        }
    }
    
    private var isDictionary: Bool {
        value is [String: Any]
    }
         
    private var isArray: Bool {
        value is [Any]
    }
}




struct DetailRow: View {
    let key: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(key)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                //.textSelection(.enabled)
        }
    }
}
