import SwiftUI
//import TipKit
import UniformTypeIdentifiers

struct CompactInfoView: View {
    @State private var selectedFileURL: URL?
    @State private var fileAnalysisResult: FileAnalysisResult?
    @State private var isAnalyzing = false
    @State private var showingFilePicker = false
    @State private var dragOver = false
   
    var body: some View {
        VStack(spacing: 8) {
            // Top row: Legend and Warnings side by side
            HStack(alignment: .top, spacing: 8) {
                CompactLegendView()
                    .frame(maxWidth: 100)
                
                CompactWarningsView()
//                              .popoverTip(comapact11())
//                    .frame(maxWidth: 250)
            }
//            .onAppear{try?  Tips.configure()}
            
            Divider()
            
            // Bottom: UTI Tool
            CompactUTIToolView(
                selectedFileURL: $selectedFileURL,
                fileAnalysisResult: $fileAnalysisResult,
                isAnalyzing: $isAnalyzing,
                showingFilePicker: $showingFilePicker,
                dragOver: $dragOver
            )
        }
        .padding(8)
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [UTType.item],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    selectedFileURL = url
                  CompactUTIToolView(
                    selectedFileURL: $selectedFileURL,
                    fileAnalysisResult: $fileAnalysisResult,
                    isAnalyzing: $isAnalyzing,
                    showingFilePicker: $showingFilePicker,
                    dragOver: $dragOver
                  ).analyzeFile(url: url)

                }
            case .failure:
                break
            }
        }
    }
}

// MARK: - Compact Sub-Views

struct CompactLegendView: View {
    var body: some View {
       //VStack(alignment: .leading, spacing: 4) {
//            Text("Status Colors")
//                .font(.caption)
//                .fontWeight(.semibold)
//            
            VStack(alignment: .leading, spacing: 5) {
                CompactLegendRow(color: .green, text: "Active")
                CompactLegendRow(color: .white, text: "Deactivated")
                CompactLegendRow(color: .blue, text: "Debug - Active")
                CompactLegendRow(color: .red, text: "Superseded")
                CompactLegendRow(color: .orange, text: "Conflict")
                CompactLegendRow(color: .black, text: "None")
            }
//        }
    }
}

struct CompactLegendRow: View {
    let color: Color
    let text: String
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(text)
                .font(.caption)
        }
    }
}

struct CompactWarningsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            CompactWarning(
                icon: "exclamationmark.triangle.fill",
                text: "Be careful with System extensions.",
                color: .accentColor
            )
            
            CompactWarning(
                icon: "info.circle.fill",
                text: "Deregister is persistent, deactivate is temporary. ",
                color: .accentColor
            )
                .help("Apple/System extensions might re-active after a reboot.")
            
//            CompactWarning(
//                icon: "shield.checkered",
//                text: "Tool creates backups automatically",
//                color: .accentColor
//            )
//                .help("/Data/tmp of this app's /Library/Container/")
            
            CompactWarning(
                icon: "shield.checkered",
                text: "The tool below can be used with any file that isn't previewed correctly, for its output to be included in a report.",
                color: .accentColor
            )
                .help("Mdls shows what the filetype is, UTType shows what the system has been told it is.\nYou can file a report in github.com, from the \"Issues\" tab.")
        }
    }
}

struct CompactWarning: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.caption)
                .frame(width: 12)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct CompactUTIToolView: View {
    @Binding var selectedFileURL: URL?
    @Binding var fileAnalysisResult: FileAnalysisResult?
    @Binding var isAnalyzing: Bool
    @Binding var showingFilePicker: Bool
    @Binding var dragOver: Bool
     var body: some View {
    HStack {
//        VStack() {
          
            // Compact drop zone
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(dragOver ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(dragOver ? Color.accentColor.opacity(0.1) : Color.secondary.opacity(0.05))
                    )
                    .frame(height: 90)
                
                VStack(spacing: 4) {
                  Text("UTI Informations")
          
                                                                                                 
                .font(.caption)
                .fontWeight(.semibold)
            
                    Image(systemName: "doc.badge.plus")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    Text("Drop file or click to select")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
           //                 .popoverTip(comapact22())

            }
            .onDrop(of: [UTType.fileURL], isTargeted: $dragOver) { providers in
                return handleDrop(providers: providers)
            }
            .onTapGesture {
                showingFilePicker = true
            }
//            .onAppear{
//            let tipOpt = [Tips.ConfigurationOption.displayFrequency(.immediate)]
//           try? Tips.configure(tipOpt)
//            }
            .frame(maxWidth: selectedFileURL != nil ? 109 : CGFloat.infinity)
            if let fileURL = selectedFileURL {
                VStack() {
//                    HStack {
//                        Text(fileURL.pathExtension)
//                            .font(.caption)
//                            .lineLimit(1)
//                            .truncationMode(.middle)
//                        Spacer()
////                        if isAnalyzing {
////                            ProgressView()
////                                .scaleEffect(0.6)
////                        }
//                    }
                    
                    if let result = fileAnalysisResult {
                        VStack(alignment: .leading){
                                                  Text("file extension: .\(result.fileExt)")
                                .font(.caption)
                                 .lineLimit(1)
                            
                            Text("mdls: \(result.contentType)")
                                .font(.caption)
                                 .lineLimit(1)
                            
                          if !(result.extensionUTIs.isEmpty) {
                            Text("uttype: \(result.extensionUTIs.first!)")
                                    .font(.caption)
                                     .lineLimit(1)
                                
                            if result.extensionUTIs.count  > 2 {
                              Text("+ \(result.extensionUTIs.count - 2) more")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Button("Copy") {
                                copyToPasteboard(result: result)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.mini)
                        }
                        .frame(maxWidth: .infinity, minHeight: 90)
 //                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .border( Color.secondary.opacity(0.3), width: 1)
                        .cornerRadius(6)
                    }
                }
            }
        }
    }
 
     private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        // Try to get URL directly first
        if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                DispatchQueue.main.async {
                    if let url = item as? URL {
                        selectedFileURL = url
                        analyzeFile(url: url)
                    } else if let data = item as? Data,
                             let url = URL(dataRepresentation: data, relativeTo: nil) {
                        selectedFileURL = url
                        analyzeFile(url: url)
                    } else if let urlString = item as? String,
                             let url = URL(string: urlString) {
                        selectedFileURL = url
                        analyzeFile(url: url)
                    }
                }
            }
        }
        
        return true // Return true if we can handle the drop type, regardless of async success
    }
    
      func analyzeFile(url: URL) {
      if url.pathExtension.lowercased() == "appex" {
    // Direct pluginkit call without validation
    DispatchQueue.global(qos: .userInitiated).async {
        do {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/pluginkit")
            process.arguments = ["-a", url.path]
            try process.run()
        } catch {
            print("Failed to register: \(error)")
        }
        
    }
    
} else {
 
        isAnalyzing = true
        
        Task {
            do {
                let contentType = try await getContentType(for: url)
                let extensionUTIs = try await getExtensionUTIs(for: url)
                
                let result = FileAnalysisResult(
                    fileExt: url.pathExtension.lowercased(),
                    contentType: contentType,
                    extensionUTIs: extensionUTIs 
                 )
                
                await MainActor.run {
                    fileAnalysisResult = result
                    isAnalyzing = false
                }
            } catch {
                await MainActor.run {
                    isAnalyzing = false
                }
            }
        }
    }
    }
    private func getContentType(for url: URL) async throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/mdls")
        process.arguments = [url.path, "-name", "kMDItemContentType"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        
        if let range = output.range(of: "\"([^\"]+)\"", options: .regularExpression) {
            let match = String(output[range])
            return match.replacingOccurrences(of: "\"", with: "")
        }
        
        return "Unable to determine"
    }
    
    private func getExtensionUTIs(for url: URL) async throws -> [String] {
        let fileExtension = url.pathExtension.lowercased()
        guard !fileExtension.isEmpty else { return [] }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/uttype")
        process.arguments = ["--extension", fileExtension]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        
        return output.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
    
    private func copyToPasteboard(result: FileAnalysisResult) {
        let reportText = """
UTI Analysis: \(result.fileExt)
mdls: \(result.contentType)
uttype: \(result.extensionUTIs.joined(separator: ", "))
"""
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(reportText, forType: .string)
    }
}

// MARK: - Supporting Types

struct FileAnalysisResult {
    let fileExt: String
    let contentType: String
    let extensionUTIs: [String]
}
