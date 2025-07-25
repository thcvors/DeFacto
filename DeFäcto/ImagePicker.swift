//
//  ImagePicker.swift
//  DeFäcto
//
//  Created by CVPRO on 7/24/25.
//

import SwiftUI
import PhotosUI

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selected: UIImage?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        var parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let item = results.first?.itemProvider else { return }
            if item.canLoadObject(ofClass: UIImage.self) {
                item.loadObject(ofClass: UIImage.self) { object, _ in
                    DispatchQueue.main.async {
                        self.parent.selected = object as? UIImage
                    }
                }
            }
        }
    }
}
