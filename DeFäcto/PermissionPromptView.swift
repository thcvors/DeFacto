//
//  PermissionPromptView.swift
//  DeFacto
//
//  Created by CVPRO on 7/24/25.
//

import SwiftUI
import AVFoundation
import Photos
import UniformTypeIdentifiers

struct PermissionPromptView: View {
    @State private var isAuthorized = false
    @State private var goToMain = false
    @State private var showDocPicker = false

    var body: some View {
        if goToMain {
            MainView()
        } else {
            ScrollView {
                VStack(spacing: 24) {
                    Spacer().frame(height: 60)

                    Image("CVO15")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 88, height: 88)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(radius: 4)

                    VStack(spacing: 12) {
                        Text("We need your permission to continue using the app's full features.")
                            .font(.footnote)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    VStack(spacing: 16) {
                        Button(action: {
                            requestPermissions {
                                showDocPicker = true
                            }
                        }) {
                            HStack {
                                Image(systemName: "key.2.on.ring")
                                Text("Allow Access")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(height: 45)
                            .frame(maxWidth: 500)
                            .background(Color.accentColor)
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }

                        Button(action: {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack {
                                Image(systemName: "gearshape")
                                Text("Open Settings")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(height: 45)
                            .frame(maxWidth: 500)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)

                    Spacer()

                    Text("Your data is safe and never shared.")
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .padding(.bottom, 12)
                }
            }
            .background(Color.black.ignoresSafeArea())
            .sheet(isPresented: $showDocPicker, onDismiss: {
                isAuthorized = true
                goToMain = true
            }) {
                DocumentAccessTriggerView()
            }
        }
    }

    func requestPermissions(completion: @escaping () -> Void) {
        PHPhotoLibrary.requestAuthorization { status in
            print("Photo library status: \(status.rawValue)")
            guard status == .authorized || status == .limited else {
                print("Photo access denied.")
                return
            }

            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        print("Camera access granted.")
                        completion()
                    } else {
                        print("Camera access denied.")
                    }
                }
            }
        }
    }
}

struct DocumentAccessTriggerView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.data], asCopy: true)
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
}
