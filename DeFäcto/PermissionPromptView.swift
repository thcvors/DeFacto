//
//  PermissionPromptView.swift
//  DeFacto
//
//  Created by CVPRO on 7/24/25.
//

import SwiftUI
import AVFoundation
import Photos

struct PermissionPromptView: View {
    @Environment(\.scenePhase) private var scenePhase

    @State private var goToMain = false
    @State private var isRequestingPermissions = false

    private enum PermissionState {
        case notDetermined
        case allowed
        case denied
    }

    @State private var permissionState: PermissionState = .notDetermined

    var body: some View {
        Group {
            if goToMain {
                MainView()
            } else {
                permissionContent
            }
        }
        .onAppear {
            updatePermissionState()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                updatePermissionState()
            }
        }
    }

    private var permissionContent: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Spacer()
                        .frame(height: 60)

                    Image("CVO15")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 88, height: 88)
                        .clipShape(
                            RoundedRectangle(cornerRadius: 20)
                        )
                        .shadow(radius: 4)

                    Text(permissionMessage)
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    VStack(spacing: 12) {
                        Button {
                            primaryButtonTapped()
                        } label: {
                            HStack(spacing: 8) {
                                if isRequestingPermissions {
                                    ProgressView()
                                        .controlSize(.small)
                                        .tint(.white)
                                } else {
                                    Image(
                                        systemName: primarySymbol
                                    )
                                    .font(.subheadline)
                                }

                                Text(primaryTitle)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(height: 45)
                            .frame(maxWidth: 500)
                            .background(Color.accentColor)
                            .cornerRadius(12)
                        }
                        .disabled(isRequestingPermissions)
                        .padding(.horizontal)

                        if permissionState != .allowed {
                            Button {
                                openSettings()
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "gearshape")
                                        .font(.subheadline)

                                    Text("Go to Settings")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(height: 45)
                                .frame(maxWidth: 500)
                                .background(
                                    Color(
                                        UIColor.secondarySystemBackground
                                    )
                                )
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                            .transition(
                                .opacity.combined(
                                    with: .move(edge: .bottom)
                                )
                            )
                        }
                    }
                    .padding(.top, 8)
                    .animation(
                        .easeInOut(duration: 0.2),
                        value: permissionState
                    )

                    Spacer()

                    Text("Your data is safe and never shared")
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .padding(.bottom, 12)
                }
            }
        }
    }

    private var primaryTitle: String {
        if isRequestingPermissions {
            return "Requesting Access..."
        }

        switch permissionState {
        case .notDetermined:
            return "Allow Access"

        case .allowed:
            return "Access Allowed"

        case .denied:
            return "Open Settings"
        }
    }

    private var primarySymbol: String {
        switch permissionState {
        case .notDetermined:
            return "hand.raised"

        case .allowed:
            return "checkmark.circle.fill"

        case .denied:
            return "gearshape.fill"
        }
    }

    private var permissionMessage: String {
        switch permissionState {
        case .notDetermined:
            return "We need your permission to continue using the app's full features"

        case .allowed:
            return "Access is ready to continue using DeFäcto"

        case .denied:
            return "Access is currently disabled and can be enabled in Settings"
        }
    }

    private func primaryButtonTapped() {
        switch permissionState {
        case .allowed:
            goToMain = true

        case .notDetermined:
            requestPermissions()

        case .denied:
            openSettings()
        }
    }

    private func updatePermissionState() {
        let photoStatus =
            PHPhotoLibrary.authorizationStatus(
                for: .readWrite
            )

        let cameraStatus =
            AVCaptureDevice.authorizationStatus(
                for: .video
            )

        let photoAllowed =
            photoStatus == .authorized ||
            photoStatus == .limited

        let cameraAllowed =
            cameraStatus == .authorized

        if photoAllowed && cameraAllowed {
            permissionState = .allowed
            return
        }

        let photoDenied =
            photoStatus == .denied ||
            photoStatus == .restricted

        let cameraDenied =
            cameraStatus == .denied ||
            cameraStatus == .restricted

        if photoDenied || cameraDenied {
            permissionState = .denied
            return
        }

        permissionState = .notDetermined
    }

    private func requestPermissions() {
        guard !isRequestingPermissions else {
            return
        }

        isRequestingPermissions = true

        let photoStatus =
            PHPhotoLibrary.authorizationStatus(
                for: .readWrite
            )

        if photoStatus == .notDetermined {
            PHPhotoLibrary.requestAuthorization(
                for: .readWrite
            ) { _ in
                requestCameraPermission()
            }
        } else {
            requestCameraPermission()
        }
    }

    private func requestCameraPermission() {
        let cameraStatus =
            AVCaptureDevice.authorizationStatus(
                for: .video
            )

        if cameraStatus == .notDetermined {
            AVCaptureDevice.requestAccess(
                for: .video
            ) { _ in
                DispatchQueue.main.async {
                    isRequestingPermissions = false
                    updatePermissionState()
                }
            }
        } else {
            DispatchQueue.main.async {
                isRequestingPermissions = false
                updatePermissionState()
            }
        }
    }

    private func openSettings() {
        guard let settingsURL = URL(
            string: UIApplication.openSettingsURLString
        ) else {
            return
        }

        UIApplication.shared.open(settingsURL)
    }
}
