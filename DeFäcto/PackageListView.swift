//
//  PackageListView.swift
//  DeFäcto
//
//  Created by CVPRO on 7/25/25.
//

import SwiftUI
import UIKit

struct PackageListView: View {
    @State var packageList = try! FileManager.default.contentsOfDirectory(atPath: FilePaths.outputDirectory.path)
    @State var showShareSheet: Bool = false
    @State var selectedPackage: String = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("Output Packages")
                .font(.title2.bold())
                .foregroundColor(.white)
                .padding(.top)

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
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(12)
                        .contextMenu {
                            Button(role: .destructive) {
                                deleteItem(package: package)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }

            Spacer()
        }
        .background(Color.black.ignoresSafeArea())
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: [FilePaths.outputDirectory.appendingPathComponent(selectedPackage)])
        }
    }

    func deleteItem(package: String) {
        if let index = packageList.firstIndex(of: package) {
            let removed = packageList.remove(at: index)
            try? FileManager.default.removeItem(atPath: FilePaths.outputDirectory.appendingPathComponent(removed).path)
            print("Deleted: \(removed)")
        }
    }
}
