//
//  MainView.swift
//  DeFäcto
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
    @State private var ipaURLText = ""
    @State private var isDownloadingURL = false

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()
                    .frame(height: 32)

                Button(action: {
                    showInfoSheet = true
                }) {
                    HStack(spacing: 6) {
                        Text("More About DeFäcto")
                            .font(.callout)

                        Image(systemName: "info.circle")
                            .font(.headline)
                    }
                    .foregroundColor(.accentColor)
                    .frame(height: 45)
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                .padding(.horizontal)

                VStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                Color(
                                    UIColor.secondarySystemBackground
                                )
                            )
                            .frame(height: 170)

                        VStack(spacing: 10) {
                            Image(systemName: "plus.circle")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 36, height: 36)
                                .foregroundColor(.white)

                            Text("Drag & Drop or Tap to Browse")
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)

                            Text(
                                "Only .ipa files are allowed for upload"
                            )
                            .font(.caption)
                            .foregroundColor(.gray)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isPickerPresented = true
                    }

                    HStack(spacing: 12) {
                        Rectangle()
                            .fill(
                                Color(
                                    UIColor.separator
                                )
                            )
                            .frame(height: 1)

                        Text("OR")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.gray)

                        Rectangle()
                            .fill(
                                Color(
                                    UIColor.separator
                                )
                            )
                            .frame(height: 1)
                    }

                    HStack(spacing: 8) {
                        Image(systemName: "link")
                            .font(.caption)
                            .foregroundColor(.gray)

                        TextField(
                            "Type URL here",
                            text: $ipaURLText
                        )
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)

                        if !ipaURLText
                            .trimmingCharacters(
                                in: .whitespacesAndNewlines
                            )
                            .isEmpty {

                            Button {
                                downloadIPAFromURL()
                            } label: {
                                if isDownloadingURL {
                                    ProgressView()
                                        .controlSize(.small)
                                        .tint(.accentColor)
                                } else {
                                    Image(
                                        systemName:
                                            "arrow.down.circle.fill"
                                    )
                                    .font(.subheadline)
                                    .foregroundColor(.accentColor)
                                }
                            }
                            .disabled(isDownloadingURL)
                            .transition(
                                .opacity.combined(
                                    with: .scale
                                )
                            )
                        }
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 45)
                    .background(
                        Color(
                            UIColor.tertiarySystemBackground
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                Color(
                                    UIColor.separator
                                ),
                                lineWidth: 1
                            )
                    }
                    .clipShape(
                        RoundedRectangle(cornerRadius: 12)
                    )
                    .animation(
                        .easeInOut(duration: 0.18),
                        value: ipaURLText
                            .trimmingCharacters(
                                in: .whitespacesAndNewlines
                            )
                            .isEmpty
                    )
                }
                .padding(16)
                .background(
                    Color(
                        UIColor.secondarySystemBackground
                    )
                    .opacity(0.55)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            Color(
                                UIColor.separator
                            ),
                            lineWidth: 1
                        )
                }
                .clipShape(
                    RoundedRectangle(cornerRadius: 16)
                )
                .padding(.horizontal)

                if let ipaURL = fileManager.ipaURL {
                    let fileName = ipaURL.lastPathComponent

                    if fileManager.appName.isEmpty {
                        HStack(spacing: 6) {
                            Text("Look for something else")
                                .foregroundColor(.white)
                                .font(.callout)

                            Image(systemName: "xmark.seal")
                                .foregroundColor(.red)
                                .symbolEffect(
                                    .wiggle.right.byLayer,
                                    options: .nonRepeating
                                )
                        }
                        .frame(
                            maxWidth: .infinity,
                            alignment: .center
                        )
                        .padding(.horizontal)

                    } else {
                        let fileSize: String? = {
                            if let sizeNum =
                                try? FileManager.default
                                .attributesOfItem(
                                    atPath: ipaURL.path
                                )[.size] as? NSNumber {

                                return ByteCountFormatter.string(
                                    fromByteCount:
                                        sizeNum.int64Value,
                                    countStyle: .file
                                )
                            } else {
                                return nil
                            }
                        }()

                        VStack(spacing: 2) {
                            HStack(spacing: 6) {
                                Text(fileName)
                                    .foregroundColor(.white)
                                    .font(.callout)
                                    .lineLimit(1)
                                    .truncationMode(.middle)

                                Image(
                                    systemName:
                                        "checkmark.seal.fill"
                                )
                                .foregroundColor(.accentColor)
                                .font(.subheadline)
                            }

                            if let size = fileSize {
                                Text(size)
                                    .foregroundColor(.gray)
                                    .font(.caption2)
                            }
                        }
                        .frame(
                            maxWidth: .infinity,
                            alignment: .center
                        )
                    }

                } else {
                    Text("No files uploaded yet.")
                        .foregroundColor(.gray)
                        .font(.callout)
                }

                Spacer()

                VStack(spacing: 12) {
                    if fileManager.ipaURL != nil {
                        Button {
                            showEditSheet = true
                        } label: {
                            HStack {
                                Spacer()

                                Image(
                                    systemName:
                                        "arrow.right.circle"
                                )
                                .contentTransition(
                                    .symbolEffect(
                                        .replace.magic(
                                            fallback:
                                                .downUp
                                                .wholeSymbol
                                        ),
                                        options: .nonRepeating
                                    )
                                )

                                Text("PROCEED")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)

                                Spacer()
                            }
                            .foregroundColor(.white)
                            .padding()
                            .frame(height: 45)
                            .frame(maxWidth: .infinity)
                            .background(Color.accentColor)
                            .cornerRadius(12)
                        }
                        .disabled(
                            fileManager.appName.isEmpty
                        )
                        .padding(.horizontal)
                    }

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
            .background(
                Color.black.ignoresSafeArea()
            )
            .fileImporter(
                isPresented: $isPickerPresented,
                allowedContentTypes: [.item],
                allowsMultipleSelection: false
            ) { result in
                Task {
                    do {
                        guard let url =
                            try result.get().first else {
                            return
                        }

                        try await fileManager.handleIPA(
                            url: url
                        )

                    } catch {
                        errorMessage =
                            error.localizedDescription
                        showError = true
                    }
                }
            }
            .sheet(
                isPresented: $showEditSheet
            ) {
                EditAppInfoView()
            }
            .sheet(
                isPresented: $showInfoSheet
            ) {
                InfoView()
            }
            .alert(
                "Error",
                isPresented: $showError
            ) {
                Button(
                    "OK",
                    role: .cancel
                ) {}
            } message: {
                Text(errorMessage)
            }
        }
        .navigationViewStyle(
            StackNavigationViewStyle()
        )
    }

    private func downloadIPAFromURL() {
        let urlString =
            ipaURLText.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !urlString.isEmpty else {
            return
        }

        guard
            let remoteURL = URL(
                string: urlString
            ),
            let scheme =
                remoteURL.scheme?.lowercased(),
            scheme == "http"
                || scheme == "https"
        else {
            errorMessage =
                "Please enter a valid URL."
            showError = true
            return
        }

        isDownloadingURL = true

        Task {
            do {
                let (
                    temporaryURL,
                    response
                ) =
                try await URLSession.shared
                    .download(
                        from: remoteURL
                    )

                if let httpResponse =
                    response as? HTTPURLResponse,
                   !(200...299).contains(
                    httpResponse.statusCode
                   ) {

                    throw NSError(
                        domain: "Download",
                        code:
                            httpResponse.statusCode,
                        userInfo: [
                            NSLocalizedDescriptionKey:
                                "Unable to download the IPA file."
                        ]
                    )
                }

                var fileName =
                    response.suggestedFilename
                    ?? remoteURL.lastPathComponent

                if fileName.isEmpty {
                    fileName = "download.ipa"
                }

                guard
                    fileName
                        .lowercased()
                        .hasSuffix(".ipa")
                else {
                    throw NSError(
                        domain: "FileType",
                        code: 400,
                        userInfo: [
                            NSLocalizedDescriptionKey:
                                "The URL must point to an .ipa file."
                        ]
                    )
                }

                let destinationURL =
                    FileManager.default
                        .temporaryDirectory
                        .appendingPathComponent(
                            UUID().uuidString
                                + "-"
                                + fileName
                        )

                try FileManager.default
                    .moveItem(
                        at: temporaryURL,
                        to: destinationURL
                    )

                try await fileManager.handleIPA(
                    url: destinationURL
                )

                isDownloadingURL = false

            } catch {
                isDownloadingURL = false
                errorMessage =
                    error.localizedDescription
                showError = true
            }
        }
    }
}
