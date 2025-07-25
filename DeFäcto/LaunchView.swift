//
//  LaunchView.swift
//  DeFäcto
//
//  Created by CVPRO on 7/25/25.
//

import SwiftUI

struct LaunchView: View {
    @State private var showPermissionView = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Image("CVO15")
                .resizable()
                .renderingMode(.original)
                .frame(width: 100, height: 100)
                .clipShape(Circle())
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showPermissionView = true
            }
        }
        .fullScreenCover(isPresented: $showPermissionView) {
            PermissionPromptView()
        }
    }
}
