//
//  EditAppInfoView.swift
//  DeFäcto
//
//  Created by CVPRO on 7/24/25.
//

import SwiftUI

struct EditAppInfoView: View {
    @EnvironmentObject var manager: MyFileManager
    @State private var showPicker = false
    @State private var showImagePicker = false
    @State private var newIcon: UIImage?
    @State private var exportedURL: URL?
    @State private var showShareSheet = false
    @State private var showSetupInstructions = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        Text("Pull down to go back")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.top, geometry.safeAreaInsets.top + 12)

                        VStack(spacing: 6) {
                            Button {
                                showImagePicker = true
                            } label: {
                                if let image = newIcon ?? manager.appIcon {
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 80, height: 80)
                                        .clipShape(RoundedRectangle(cornerRadius: 20))
                                } else {
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 80, height: 80)
                                        .overlay(
                                            Image(systemName: "photo")
                                                .foregroundColor(.gray)
                                        )
                                }
                            }

                            Text("Tap the icon to change appearence.")
                                .font(.footnote)
                                .foregroundColor(.gray)

                            Text("Customize bundle details as needed. Personalize your app’s identity.")
                                .multilineTextAlignment(.center)
                                .font(.footnote)
                                .foregroundColor(.gray)
                                .padding(.top, 4)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.15))
                        .cornerRadius(20)

                        VStack(spacing: 4) {
                            Button {
                                withAnimation {
                                    showSetupInstructions.toggle()
                                }
                            } label: {
                                HStack {
                                    Text("Setup Instructions")
                                    Spacer()
                                    Image(systemName: showSetupInstructions ? "chevron.down.circle" : "chevron.right.circle")
                                }
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding()
                                .background(.ultraThinMaterial)
                                .cornerRadius(12)
                            }

                            if showSetupInstructions {
                                VStack(alignment: .leading, spacing: 4) {
                                    headerRow(symbolName: "1.circle", text: "Edit general app info like name or ID.")
                                    headerRow(symbolName: "2.circle", text: "Use a custom icon by tapping the one above.")
                                    headerRow(symbolName: "3.circle", text: "Skip any field to keep its original value.")
                                }
                                .padding()
                                .background(Color.gray.opacity(0.15))
                                .cornerRadius(12)
                                .transition(.opacity.combined(with: .slide))
                            }
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("info (confirmed to edit)")
                                .font(.callout.bold())
                                .foregroundColor(.white)

                            appField("Enter new app name", $manager.appName)
                            appField("Enter new bundle ID", $manager.bundleIdentifier)
                            appField("Enter new package name", $manager.bundleIdentifier)
                        }

                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Version")
                                    .foregroundColor(.gray)
                                    .font(.footnote)
                                Text(manager.appVersion)
                                    .foregroundColor(.white)
                            }
                            Spacer()
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Build")
                                    .foregroundColor(.gray)
                                    .font(.footnote)
                                Text("15")
                                    .foregroundColor(.white)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(12)

                        Button {
                            Task {
                                try? await manager.updatePlist(with: [
                                    "CFBundleDisplayName": manager.appName,
                                    "CFBundleIdentifier": manager.bundleIdentifier,
                                    "CFBundleShortVersionString": manager.appVersion,
                                    "MinimumOSVersion": manager.minOSVersion
                                ])
                                if let icon = newIcon {
                                    try? await manager.replaceAppIcon(with: icon)
                                }
                                exportedURL = try? await manager.exportAsIPA()
                                showShareSheet = exportedURL != nil
                            }
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Export IPA")
                            }
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding()
                            .frame(height: 45)
                            .frame(maxWidth: .infinity)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(12)
                        }
                        .disabled(manager.ipaURL == nil)

                        if let url = exportedURL {
                            Text("Exported to: \(url.lastPathComponent)")
                                .font(.caption)
                                .foregroundColor(.accent)
                                .padding(.top, 4)
                        }
                    }
                    .padding()
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(selected: $newIcon)
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportedURL {
                    ShareSheet(activityItems: [url])
                }
            }
            .fileImporter(
                isPresented: $showPicker,
                allowedContentTypes: [.data],
                allowsMultipleSelection: false
            ) { result in
                guard let url = try? result.get().first else { return }
                Task {
                    try? await manager.handleIPA(url: url)
                }
            }
        }
    }

    @ViewBuilder
    private func appField(_ title: String, _ binding: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            TextField(title, text: binding)
                .padding(12)
                .background(Color.gray.opacity(0.2))
                .foregroundColor(.white)
                .cornerRadius(10)
                .font(.subheadline)
        }
    }

    private func headerRow(symbolName: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: symbolName)
                .foregroundColor(.accentColor)
                .font(.system(size: 16, weight: .semibold))
            Text(text)
                .foregroundColor(.white)
                .font(.footnote)
        }
    }
}
