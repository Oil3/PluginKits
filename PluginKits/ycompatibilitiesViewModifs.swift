//
//  compatibilitiesViewModifs.swift
//  PluginKits
//
//  Created by Almahdi Morris Quet on 09/18/25.
//
import SwiftUI
extension AdvancedAnalysisView: View {
  
}
struct AlternatingRowBackgroundsModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 14.0, *) {
            content                                                

                 .alternatingRowBackgrounds(.enabled)      //comment out for macOS13Ventura comaptibility
                                                
        } else {
            content
        }
    }
}


}
