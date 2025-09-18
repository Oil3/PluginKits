//
//  PopoverTip.swift
//  PluginKits
//
//  Created by Almahdi Morris Quet on 09/17/25.
//


import SwiftUI
//import TipKit

struct comapact11: Tip {
    var title: Text {
        Text("comapact1")
            .foregroundStyle(.indigo)
    }

    var message: Text? {
        Text("Tcomapact1comapact1comapact1 \(Image(systemName: "wand.and.stars"))comapact1comapact1comapact1.")
    }
}

struct comapact22: Tip {
    var title: Text {
        Text("comapact2comapact2")
            .foregroundStyle(.indigo)
    }

    var message: Text? {
        Text("ww22222222222222222222 hold \(Image(systemName: "sidebar.squares.leading")) tcomapact2.")
    }
}
