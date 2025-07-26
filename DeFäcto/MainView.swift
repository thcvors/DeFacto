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
                Spacer().frame(height: 32)
                
                Button(action: {
                    showInfoSheet = true
                }) {
                    HStack(spacing: 6) {
                        Text("More About DeFäcto")
                        Image(systemName: "info.circle")
                    }
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
                    .frame(height: 45)
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                .padding(.horizontal)
                
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.secondarySystemBackground))
                        .frame(height: 200)
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
                        
                        Text("Only .ipa files are allowed for upload.")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal)
                .onTapGesture {
                    isPickerPresented = true
                }
                
                // 파일 업로드 상태
                if let fileName = fileManager.ipaURL?.lastPathComponent {
                    if fileManager.appName.isEmpty {
                        HStack(spacing: 6) {
                            Text("Look for something else")
                                .foregroundColor(.white)
                                .font(.callout)
                            
                            Image(systemName: "xmark.seal")
                                .foregroundColor(.red)
                                .symbolEffect(.wiggle.right.byLayer, options: .nonRepeating)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.horizontal)
                    } else {
                        let fileSize: String? = {
                            if let sizeNum = try? FileManager.default.attributesOfItem(atPath: fileManager.ipaURL!.path)[.size] as? NSNumber {
                                return ByteCountFormatter.string(fromByteCount: sizeNum.int64Value, countStyle: .file)
                            } else {
                                return nil
                            }
                        }()
                        
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.accentColor)
                                .font(.subheadline)
                            
                            VStack(spacing: 2) {
                                Text(fileName)
                                    .foregroundColor(.white)
                                    .font(.callout)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                
                                if let size = fileSize {
                                    Text(size)
                                        .foregroundColor(.gray)
                                        .font(.caption2)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                } else {
                    Text("No files uploaded yet.")
                        .foregroundColor(.gray)
                        .font(.callout)
                }

                Spacer()

                VStack(spacing: 12) {
                    Button {
                        showEditSheet = true
                    } label: {
                        HStack {
                            if fileManager.ipaURL == nil {
                                Text("proceed")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            } else {
                                Spacer()
                                Image(systemName: "chevron.right.circle")
                                    .contentTransition(.symbolEffect(.replace.magic(fallback: .downUp.wholeSymbol), options: .nonRepeating))
                                Text("PROCEED")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(height: 45)
                        .frame(maxWidth: .infinity)
                        .background(fileManager.ipaURL == nil ? Color.gray.opacity(0.3) : Color.accentColor)
                        .cornerRadius(12)
                    }
                    .disabled(fileManager.ipaURL == nil || fileManager.appName.isEmpty)
                    .padding(.horizontal)

                    Text("Made by @cvors")
                        .font(.caption2)
                        .foregroundColor(Color(UIColor.tertiaryLabel))
                        .padding(.bottom, 12)
                }
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
