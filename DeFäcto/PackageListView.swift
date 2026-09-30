//
//  PackageListView.swift
//  DeFäcto
//
//  Created by CVPRO on 7/25/25.
//

import SwiftUI
import UIKit

struct PackageListView: View {
    @State private var packageList: [String] = []
    @State private var showShareSheet = false
    @State private var selectedPackage = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("Output Packages")
                .font(.title2.bold())
                .foregroundColor(.white)
                .padding(.top)

            if packageList.isEmpty {
                Spacer()

                VStack(spacing: 10) {
                    Image(systemName: "shippingbox")
                        .font(.system(size: 32))
                        .foregroundColor(.gray)

                    Text("No Packages Available")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(packageList, id: \.self) { package in
                            HStack {
                                Text(package)
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                    .truncationMode(.middle)

                                Spacer()

                                Button {
                                    selectedPackage = package
                                    showShareSheet = true
                                } label: {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.subheadline)
                                        .foregroundColor(.accentColor)
                                        .padding(8)
                                        .background(
                                            Color.white.opacity(0.1)
                                        )
                                        .clipShape(Circle())
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding()
                            .background(
                                Color.gray.opacity(0.2)
                            )
                            .cornerRadius(12)
                            .contextMenu {
                                Button(role: .destructive) {
                                    deleteItem(package: package)
                                } label: {
                                    Label(
                                        "Delete",
                                        systemImage: "trash"
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .background(
            Color.black.ignoresSafeArea()
        )
        .onAppear {
            loadPackages()
        }
        .sheet(isPresented: $showShareSheet) {
            if !selectedPackage.isEmpty {
                ShareSheet(
                    activityItems: [
                        FilePaths.outputDirectory
                            .appendingPathComponent(
                                selectedPackage
                            )
                    ]
                )
            }
        }
    }

    private func loadPackages() {
        do {
            packageList =
                try FileManager.default.contentsOfDirectory(
                    atPath: FilePaths.outputDirectory.path
                )
                .sorted()
        } catch {
            packageList = []

            print(
                "Error loading packages: \(error.localizedDescription)"
            )
        }
    }

    private func deleteItem(package: String) {
        let packageURL =
            FilePaths.outputDirectory
                .appendingPathComponent(package)

        do {
            try FileManager.default.removeItem(
                at: packageURL
            )

            packageList.removeAll {
                $0 == package
            }

            print("Deleted: \(package)")
        } catch {
            print(
                "Error deleting package: \(error.localizedDescription)"
            )
        }
    }
}
