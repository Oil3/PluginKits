//
//  UTIConflictDetailView.swift
//  PluginKits
//
//  Created by Almahdi Morris Quet on 09/12/25.
//
import SwiftUI

struct UTIConflictDetailView: View {
  let uti: String
  let extensions: [AdvancedPluginExtension]
  @ObservedObject var manager: PluginKitManager  
  @State private var isExpanded = false
  
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      // UTI Header
      HStack {
        Button(action: { isExpanded.toggle() }) {
          Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
            .font(.caption)
        }
        .buttonStyle(PlainButtonStyle())
        
        VStack(alignment: .leading, spacing: 2) {
          Text(uti)
            .font(.headline)
            //.textSelection(.enabled)
          Text(utiDescription)
            .font(.caption)
            .foregroundColor(.secondary)
        }
        
        Spacer()
        
        Text("\(extensions.count) extensions")
          .font(.caption)
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(Color.red.opacity(0.2))
          .foregroundColor(.red)
          .cornerRadius(8)
      }
      .onAppear {
  // Load UTI extension info when the view appears
  manager.loadUTIExtension(for: uti)
  }
      if isExpanded {
        VStack(spacing: 6) {
          ForEach(extensions, id: \.uuid) { ext in
            HStack {
              VStack(alignment: .leading, spacing: 2) {
                HStack {
                  Circle()
                    .fill(ext.isApple ? Color.gray : Color.blue)
                    .frame(width: 8, height: 8)
                  
                  Text(ext.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                  
                  Text("v\(ext.version)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                  
                  if ext.isApple {
                    Text("Apple")
                      .font(.caption)
                      .padding(.horizontal, 6)
                      .padding(.vertical, 2)
                      .background(Color.gray.opacity(0.2))
                      .foregroundColor(.gray)
                      .cornerRadius(4)
                  }
                }
                
                Text(ext.path)
                  .font(.caption)
                  .foregroundColor(.secondary)
                  //.textSelection(.enabled)
                  .lineLimit(1)
                  .truncationMode(.middle)
                
                // Show all supported UTIs for this extension
                if ext.supportedContentTypes.count > 1 {
                  Text("Also supports: \(ext.supportedContentTypes.filter { $0 != uti }.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
                }
              }
              
              Spacer()
              
              Button(action: {
                // TODO: - 
    
              }) {
                Image(systemName: "info.circle")
                  .foregroundColor(.secondary)
              }
              .buttonStyle(PlainButtonStyle())
            }
            .padding(.vertical, 4)
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(6)
          }
        }
        .padding(.leading, 20)
      }
    }
    .padding(.vertical, 4)
  }
  
private var utiDescription: String {
  // First check if we have the file extension loaded
  if let fileExtension = manager.getFileExtension(for: uti) {
    if !fileExtension.isEmpty && fileExtension != "unknown" {
      return fileExtension
    }
  }
  
  // Fall back to hardcoded descriptions for common UTIs while loading
  switch uti {

  default:
    // Check if UTI extension is still loading
    if manager.utiExtensions[uti] == nil {
      return " "
    }
    
    // UTI was attempted but failed to load or returned unknown
    if uti.hasPrefix("com.apple.") {
      return "Apple Proprietary Format"
    } else if uti.hasPrefix("public.") {
      return "Standard Format"
    } else {
      return "Custom Format"
    }
  }
}
}



struct UTIInfoView: View {
    let utiInfo: UTIInfo
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("UTI Information") {
                    DetailRow(key: "Identifier", value: utiInfo.identifier)
                    DetailRow(key: "Description", value: utiInfo.description)
                }
                
                if !utiInfo.fileExtensions.isEmpty {
                    Section("File Extensions") {
                        ForEach(utiInfo.fileExtensions, id: \.self) { ext in
                            HStack {
                                Text(".\(ext)")
                                    .font(.monospaced(.body)())
                                    //.textSelection(.enabled)
                                Spacer()
                                Button("Copy") {
                                    NSPasteboard.general.setString(ext, forType: .string)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.mini)
                            }
                        }
                    }
                }
                
                if !utiInfo.mimeTypes.isEmpty {
                    Section("MIME Types") {
                        ForEach(utiInfo.mimeTypes, id: \.self) { mimeType in
                            Text(mimeType)
                                //.textSelection(.enabled)
                        }
                    }
                }
                
                if !utiInfo.conformsTo.isEmpty {
                    Section("Conforms To") {
                        ForEach(utiInfo.conformsTo, id: \.self) { uti in
                            Text(uti)
                                //.textSelection(.enabled)
                        }
                    }
                }
            }
                                                            

                 .alternatingRowBackgrounds(.enabled)      //comment out for macOS13Ventura comaptibility
                                                 //comment out for macOS13Ventura comaptibility
            .navigationTitle("UTI Details")
             .toolbar {
                ToolbarItem() {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 500, height: 400)
    }
}
 
