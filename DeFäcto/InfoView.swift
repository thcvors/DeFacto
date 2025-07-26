//
//  InfoView.swift
//  DeFäcto
//
//  Created by CVPRO on 7/24/25.
//

import SwiftUI

struct InfoView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showPackagesList = false
    @State private var showNoPackagesAlert = false

    struct AppVersion {
        static var shortVersion: String {
            Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "N/A"
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 24) {
                    Spacer(minLength: geometry.safeAreaInsets.top)

                    Text("Pull down to go back")
                        .font(.subheadline)
                        .foregroundColor(.white)

                    Spacer()
                    Image("Memoji")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1))
                        .shadow(radius: 4)

                    VStack(spacing: 6) {
                        Text("DeFäcto")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Text("Your tool for managing IPA files and customizing apps.")
                            .font(.footnote)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Text("Version: \(AppVersion.shortVersion)")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }

                    VStack(spacing: 12) {
                        infoButton(title: "View on GitHub", icon: "swiftdata", symbolColor: .orange) {
                            if let url = URL(string: "https://github.com/thcvors/DeFacto") {
                                UIApplication.shared.open(url)
                            }
                        }

                        infoButton(title: "View Output Package List", icon: "shippingbox", symbolColor: .brown) {
                            checkPackages()
                        }

                        infoButton(title: "Clean up tmp Directory", icon: "trash", symbolColor: .red) {
                            MyFileManager.shared.resetTmpDirectory()
                        }

                        infoButton(title: "Clean up Output Directory", icon: "trash", symbolColor: .red) {
                            MyFileManager.shared.resetOutputDirectory()
                        }
                    }
                    .padding(.horizontal)

                    VStack(spacing: 6) {
                        Text("Output Path")
                            .font(.caption2)
                            .foregroundColor(.gray)

                        Text(FilePaths.outputDirectory.path)
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
                        .foregroundColor(Color(UIColor.tertiaryLabel))
                        .padding(.bottom, 12)
                }
                .padding(.top, geometry.safeAreaInsets.top)
                .padding(.bottom, geometry.safeAreaInsets.bottom)
            }
        }
        .alert(isPresented: $showNoPackagesAlert) {
            Alert(
                title: Text("No Packages Available"),
                message: Text("There are no packages available to manage."),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private func infoButton(title: String, icon: String, symbolColor: Color = .gray, action: @escaping () -> Void) -> some View {
        Button(action: {
            withAnimation(.interpolatingSpring(stiffness: 200, damping: 5)) {
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
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
        }
    }

    private func checkPackages() {
        do {
            let packages = try FileManager.default.contentsOfDirectory(atPath: FilePaths.outputDirectory.path)
            showNoPackagesAlert = packages.isEmpty
            if !packages.isEmpty {
                showPackagesList.toggle()
            }
        } catch {
            print("Error loading packages: \(error.localizedDescription)")
            showNoPackagesAlert = true
        }
    }
}

// MARK: - Directory Reset Extensions
extension MyFileManager {
    func resetTmpDirectory() {
        try? FileManager.default.removeItem(at: FilePaths.tmpDirectory)
        try? FileManager.default.createDirectory(at: FilePaths.tmpDirectory, withIntermediateDirectories: true)
    }

    func resetOutputDirectory() {
        try? FileManager.default.removeItem(at: FilePaths.outputDirectory)
        try? FileManager.default.createDirectory(at: FilePaths.outputDirectory, withIntermediateDirectories: true)
    }
}
