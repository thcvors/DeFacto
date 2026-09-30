//
//  InfoView.swift
//  DeFäcto
//
//  Created by CVPRO on 7/24/25.
//

import SwiftUI

struct InfoView: View {
    @State private var showPackagesList = false
    @State private var showNoPackagesAlert = false

    struct AppVersion {
        static var shortVersion: String {
            Bundle.main.infoDictionary?[
                "CFBundleShortVersionString"
            ] as? String ?? "N/A"
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    Text("Pull down to go back")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(
                            .top,
                            geometry.safeAreaInsets.top + 12
                        )

                    Spacer()

                    Image("Memoji")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(
                                    Color.gray.opacity(0.3),
                                    lineWidth: 1
                                )
                        )
                        .shadow(radius: 4)

                    VStack(spacing: 6) {
                        Text("DeFäcto")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Text(
                            "Your tool for managing IPA files and customizing apps"
                        )
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                        Text(
                            "Version: \(AppVersion.shortVersion)"
                        )
                        .font(.caption2)
                        .foregroundColor(.gray)
                    }

                    VStack(spacing: 12) {
                        infoButton(
                            title: "View on GitHub",
                            icon: "swiftdata",
                            symbolColor: .teal
                        ) {
                            if let url = URL(
                                string: "https://github.com/thcvors/DeFacto"
                            ) {
                                UIApplication.shared.open(url)
                            }
                        }

                        infoButton(
                            title: "View Output Package List",
                            icon: "shippingbox.and.arrow.backward",
                            symbolColor: .mint
                        ) {
                            checkPackages()
                        }

                        infoButton(
                            title: "Clean up tmp Directory",
                            icon: "trash",
                            symbolColor: .secondary
                        ) {
                            MyFileManager.shared
                                .resetTmpDirectory()
                        }

                        infoButton(
                            title: "Clean up Output Directory",
                            icon: "trash",
                            symbolColor: .secondary
                        ) {
                            MyFileManager.shared
                                .resetOutputDirectory()
                        }
                    }
                    .padding(.horizontal)

                    VStack(spacing: 6) {
                        Text("Output Path")
                            .font(.caption2)
                            .foregroundColor(.gray)

                        Text(
                            FilePaths.outputDirectory.path
                        )
                        .font(.caption2)
                        .foregroundColor(.white)
                        .opacity(0.8)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .padding(.horizontal)
                    }

                    Spacer()

                    Text("Made by @cvors")
                        .font(.caption2)
                        .foregroundColor(
                            Color(
                                UIColor.systemGray
                            )
                        )
                        .padding(.bottom, 12)
                }
            }
        }
        .sheet(
            isPresented: $showPackagesList
        ) {
            PackageListView()
        }
        .alert(
            "No Packages Available",
            isPresented: $showNoPackagesAlert
        ) {
            Button(
                "OK",
                role: .cancel
            ) {}
        } message: {
            Text(
                "There are no packages available to manage."
            )
        }
    }

    private func infoButton(
        title: String,
        icon: String,
        symbolColor: Color = .gray,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: {
            withAnimation(
                .interpolatingSpring(
                    stiffness: 200,
                    damping: 5
                )
            ) {
                action()
            }
        }) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(symbolColor)

                Text(title)
                    .foregroundColor(.white)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()
            }
            .padding(.horizontal)
            .frame(height: 45)
            .frame(maxWidth: .infinity)
            .background(
                Color(
                    UIColor.secondarySystemBackground
                )
            )
            .cornerRadius(12)
        }
    }

    private func checkPackages() {
        do {
            let packages =
                try FileManager.default
                    .contentsOfDirectory(
                        atPath:
                            FilePaths.outputDirectory.path
                    )

            if packages.isEmpty {
                showNoPackagesAlert = true
            } else {
                showPackagesList = true
            }
        } catch {
            print(
                "Error loading packages: \(error.localizedDescription)"
            )

            showNoPackagesAlert = true
        }
    }
}

// MARK: - Directory Reset Extensions

extension MyFileManager {
    func resetTmpDirectory() {
        try? FileManager.default.removeItem(
            at: FilePaths.tmpDirectory
        )

        try? FileManager.default.createDirectory(
            at: FilePaths.tmpDirectory,
            withIntermediateDirectories: true
        )
    }

    func resetOutputDirectory() {
        try? FileManager.default.removeItem(
            at: FilePaths.outputDirectory
        )

        try? FileManager.default.createDirectory(
            at: FilePaths.outputDirectory,
            withIntermediateDirectories: true
        )
    }
}
