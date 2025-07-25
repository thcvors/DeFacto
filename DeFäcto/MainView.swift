//
//  MainView.swift
//  DeFäcto
//
//  Created by CVPRO on 7/24/25.
//

import SwiftUI

struct MainView: View {
    @EnvironmentObject var fileManager: MyFileManager
    @State private var isPickerPresented = false
    @State private var showEditSheet = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showInfoSheet = false

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer().frame(height: 32) // 상단 간격

                // More About 버튼
                Button(action: {
                    showInfoSheet = true
                }) {
                    HStack(spacing: 6) {
                        Text("More About DeFäcto")
                        Image(systemName: "info.circle")
                    }
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(8) // 덜 둥글게
                }
                .padding(.horizontal)

                // 업로드 카드
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.secondarySystemBackground))
                        .frame(height: 160)
                    VStack(spacing: 10) {
                        Image(systemName: "plus.circle")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 36, height: 36)
                            .foregroundColor(.gray)

                        Text("Drag & Drop or Tap to Browse")
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)

                        Text("Max file size: 1 GB")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal)
                .onTapGesture {
                    isPickerPresented = true
                }

                // 파일 업로드 상태
                if let fileName = fileManager.ipaURL?.lastPathComponent,
                   let fileSize = try? FileManager.default.attributesOfItem(atPath: fileManager.ipaURL!.path)[.size] as? NSNumber {
                    
                    let formattedSize = ByteCountFormatter.string(fromByteCount: fileSize.int64Value, countStyle: .file)

                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(fileName)
                                .foregroundColor(.white)
                                .font(.callout)
                                .lineLimit(1)
                                .truncationMode(.middle)

                            Text(formattedSize)
                                .foregroundColor(.gray)
                                .font(.caption2)
                        }

                        Spacer()

                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.accentColor)
                            .font(.caption)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                    .padding(.horizontal)

                } else {
                    Text("No files uploaded yet.")
                        .foregroundColor(.gray)
                        .font(.callout)
                }
                Spacer()

                // Proceed 버튼
                Button {
                    showEditSheet = true
                } label: {
                    HStack {
                        Spacer()
                        Image(systemName: "chevron.right.circle")
                        Text("Proceed")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(fileManager.ipaURL == nil ? Color.gray.opacity(0.3) : Color.accentColor)
                    .cornerRadius(8)
                }
                .disabled(fileManager.ipaURL == nil)
                .padding(.horizontal)

                Text("Made by @cvors")
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .padding(.bottom, 12)
            }
            .background(Color.black.ignoresSafeArea())
            .fileImporter(
                isPresented: $isPickerPresented,
                allowedContentTypes: [.item],
                allowsMultipleSelection: false
            ) { result in
                Task {
                    do {
                        guard let url = try result.get().first else { return }
                        guard url.startAccessingSecurityScopedResource() else {
                            throw NSError(domain: "Permission", code: 401, userInfo: [NSLocalizedDescriptionKey: "Permission denied to access file"])
                        }
                        defer { url.stopAccessingSecurityScopedResource() }

                        try await fileManager.handleIPA(url: url)
                    } catch {
                        errorMessage = error.localizedDescription
                        showError = true
                    }
                }
            }
            .sheet(isPresented: $showEditSheet) {
                EditAppInfoView()
            }
            .sheet(isPresented: $showInfoSheet) {
                InfoView()
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
