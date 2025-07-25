//
//  DeFätoApp.swift
//  DeFäcto
//
//  Created by CVPRO on 7/24/25.
//

import SwiftUI

@main
struct DeFactoApp: App {
    init() {
        UIView.appearance().overrideUserInterfaceStyle = .dark
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(MyFileManager.shared)
        }
    }
}
