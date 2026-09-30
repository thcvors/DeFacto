//
//  MyFileManager.swift
//  DeFacto
//
//  Created by CVPRO on 7/24/25.
//

import Foundation
import SwiftUI
import ZipArchive

@MainActor
class MyFileManager: ObservableObject {
    static let shared = MyFileManager()
    private init() {}

    // MARK: - Published Properties
    @Published var ipaURL: URL? = nil
    @Published var appName: String = ""
    @Published var bundleIdentifier: String = ""
    @Published var appVersion: String = ""
    @Published var minOSVersion: String = ""
    @Published var appIcon: UIImage?

    // MARK: - Setup
    func setUpPath() {
        if !FileManager.default.fileExists(
            atPath: FilePaths.tmpDirectory.path
        ) {
            try? FileManager.default.createDirectory(
                at: FilePaths.tmpDirectory,
                withIntermediateDirectories: true
            )
        }

        if !FileManager.default.fileExists(
            atPath: FilePaths.outputDirectory.path
        ) {
            try? FileManager.default.createDirectory(
                at: FilePaths.outputDirectory,
                withIntermediateDirectories: true
            )
        }
    }

    // MARK: - IPA Handling
    func handleIPA(url: URL) async throws {

        let didStartSecurityAccess =
            url.startAccessingSecurityScopedResource()

        defer {
            if didStartSecurityAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        guard FileManager.default.fileExists(atPath: url.path) else {
            throw NSError(
                domain: "IPA",
                code: 404,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "IPA file could not be found."
                ]
            )
        }

        setUpPath()

        appName = ""
        bundleIdentifier = ""
        appVersion = ""
        minOSVersion = ""
        appIcon = nil

        let fileName =
            url.deletingPathExtension().lastPathComponent

        let zipURL =
            FilePaths.tmpDirectory
                .appendingPathComponent("\(fileName).zip")

        let extractedDir =
            FilePaths.tmpDirectory
                .appendingPathComponent("Extracted")

        // 기존 ZIP 제거
        if FileManager.default.fileExists(
            atPath: zipURL.path
        ) {
            try FileManager.default.removeItem(
                at: zipURL
            )
        }

        // 기존 압축 해제 폴더 제거
        if FileManager.default.fileExists(
            atPath: extractedDir.path
        ) {
            try FileManager.default.removeItem(
                at: extractedDir
            )
        }

        // IPA -> ZIP
        try FileManager.default.copyItem(
            at: url,
            to: zipURL
        )

        let unzipSuccess =
            SSZipArchive.unzipFile(
                atPath: zipURL.path,
                toDestination: extractedDir.path
            )

        guard unzipSuccess else {
            throw NSError(
                domain: "IPA",
                code: 422,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Unable to extract the IPA file."
                ]
            )
        }

        let payloadURL =
            extractedDir
                .appendingPathComponent("Payload")

        guard FileManager.default.fileExists(
            atPath: payloadURL.path
        ) else {
            throw NSError(
                domain: "IPA",
                code: 404,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Payload folder was not found."
                ]
            )
        }

        let payloadContents =
            try FileManager.default.contentsOfDirectory(
                at: payloadURL,
                includingPropertiesForKeys: nil
            )

        guard let appDir = payloadContents.first(
            where: {
                $0.pathExtension.lowercased() == "app"
            }
        ) else {
            throw NSError(
                domain: "IPA",
                code: 404,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "No .app was found inside Payload."
                ]
            )
        }

        let infoPlist =
            appDir.appendingPathComponent(
                "Info.plist"
            )

        let data =
            try Data(contentsOf: infoPlist)

        guard let plist =
            try PropertyListSerialization.propertyList(
                from: data,
                options: [],
                format: nil
            ) as? [String: Any]
        else {
            throw NSError(
                domain: "IPA",
                code: 500,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Unable to parse Info.plist."
                ]
            )
        }

        appName =
            (plist["CFBundleDisplayName"] as? String)
            ?? (plist["CFBundleName"] as? String)
            ?? "Unknown"

        bundleIdentifier =
            plist["CFBundleIdentifier"] as? String
            ?? ""

        appVersion =
            plist["CFBundleShortVersionString"] as? String
            ?? ""

        minOSVersion =
            plist["MinimumOSVersion"] as? String
            ?? ""

        if let iconDict =
            (plist["CFBundleIcons"] as? [String: Any])?[
                "CFBundlePrimaryIcon"
            ] as? [String: Any],

           let iconNames =
            iconDict["CFBundleIconFiles"] as? [String] {

            for iconName in iconNames.reversed() {
                let possiblePaths = [
                    appDir.appendingPathComponent(
                        iconName
                    ),
                    appDir.appendingPathComponent(
                        "\(iconName)@2x.png"
                    ),
                    appDir.appendingPathComponent(
                        "\(iconName)@3x.png"
                    )
                ]

                if let foundImage =
                    possiblePaths.compactMap({
                        UIImage(contentsOfFile: $0.path)
                    }).first {

                    appIcon = foundImage
                    break
                }
            }
        }

        // 성공적으로 IPA 분석이 끝난 뒤 설정
        ipaURL = url
    }

    // MARK: - Edit Info.plist
    func updatePlist(
        with values: [String: String]
    ) async throws {

        let extractedDir =
            FilePaths.tmpDirectory
                .appendingPathComponent("Extracted")

        let payloadPath =
            extractedDir
                .appendingPathComponent("Payload")

        guard let appDir = try?
            FileManager.default.contentsOfDirectory(
                at: payloadPath,
                includingPropertiesForKeys: nil
            )
            .first(
                where: {
                    $0.pathExtension == "app"
                }
            )
        else {
            throw NSError(
                domain: "IPA",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "App bundle not found"
                ]
            )
        }

        let infoPlistURL =
            appDir.appendingPathComponent(
                "Info.plist"
            )

        guard
            let data =
                try? Data(
                    contentsOf: infoPlistURL
                ),

            var plist =
                try? PropertyListSerialization
                    .propertyList(
                        from: data,
                        options: [],
                        format: nil
                    ) as? [String: Any]
        else {
            throw NSError(
                domain: "IPA",
                code: 2,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Info.plist not found or unreadable"
                ]
            )
        }

        for (key, value) in values
        where !value.isEmpty {
            plist[key] = value
        }

        let updatedData =
            try PropertyListSerialization.data(
                fromPropertyList: plist,
                format: .xml,
                options: 0
            )

        try updatedData.write(
            to: infoPlistURL
        )

        print(
            "Info.plist updated successfully"
        )
    }

    // MARK: - Icon Replacement
    func replaceAppIcon(
        with image: UIImage
    ) async throws {
        appIcon = image

        // TODO:
        // Implement app icon replacement
        // in .app directory if needed
    }

    // MARK: - Export IPA
    func exportAsIPA() async throws -> URL {

        guard let ipaURL else {
            throw NSError(
                domain: "Export",
                code: 404,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "No IPA file loaded"
                ]
            )
        }

        let fileName =
            ipaURL
                .deletingPathExtension()
                .lastPathComponent

        let exportPath =
            FilePaths.outputDirectory
                .appendingPathComponent(
                    "\(fileName)_exported.ipa"
                )

        let extractedDir =
            FilePaths.tmpDirectory
                .appendingPathComponent(
                    "Extracted"
                )

        let workingPath =
            FilePaths.tmpDirectory
                .appendingPathComponent(
                    fileName
                )

        if FileManager.default.fileExists(
            atPath: workingPath.path
        ) {
            try FileManager.default.removeItem(
                at: workingPath
            )
        }

        if FileManager.default.fileExists(
            atPath: exportPath.path
        ) {
            try FileManager.default.removeItem(
                at: exportPath
            )
        }

        try FileManager.default.copyItem(
            at: extractedDir,
            to: workingPath
        )

        let zipSuccess =
            SSZipArchive.createZipFile(
                atPath: exportPath.path,
                withContentsOfDirectory:
                    workingPath.path
            )

        guard zipSuccess else {
            throw NSError(
                domain: "Export",
                code: 500,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Unable to export IPA."
                ]
            )
        }

        print(
            "✅ IPA exported to \(exportPath.path)"
        )

        return exportPath
    }
}
