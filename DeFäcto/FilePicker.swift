//
//  FilePicker.swift
//  DeFacto
//
//  Created by CVPRO on 7/24/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct FilePicker: UIViewControllerRepresentable {
    var onPicked: (URL) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let types = [UTType(filenameExtension: "ipa")!]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        picker.shouldShowFileExtensions = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        return Coordinator(onPicked: onPicked)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPicked: (URL) -> Void

        init(onPicked: @escaping (URL) -> Void) {
            self.onPicked = onPicked
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else {
                print("No file selected.")
                return
            }

            //Try security-scoped access
            guard url.startAccessingSecurityScopedResource() else {
                print("Permission denied: Unable to access the selected file.")
                return
            }

            defer {
                url.stopAccessingSecurityScopedResource()
            }

            do {
                let fileManager = FileManager.default
                let tmpDir = fileManager.temporaryDirectory
                let destinationURL = tmpDir.appendingPathComponent(url.lastPathComponent)

                if fileManager.fileExists(atPath: destinationURL.path) {
                    try fileManager.removeItem(at: destinationURL)
                }

                try fileManager.copyItem(at: url, to: destinationURL)
                print("File copied to sandbox: \(destinationURL.path)")

                onPicked(destinationURL)

            } catch {
                print("Failed to copy file: \(error.localizedDescription)")
            }
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            print("File picking cancelled.")
        }
    }
}
