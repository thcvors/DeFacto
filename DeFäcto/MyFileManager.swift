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
        if !FileManager.default.fileExists(atPath: FilePaths.tmpDirectory.path) {
            try? FileManager.default.createDirectory(at: FilePaths.tmpDirectory, withIntermediateDirectories: true)
        }
        if !FileManager.default.fileExists(atPath: FilePaths.outputDirectory.path) {
            try? FileManager.default.createDirectory(at: FilePaths.outputDirectory, withIntermediateDirectories: true)
        }
    }

    // MARK: - IPA Handling
    func handleIPA(url: URL) async throws {
        // 📍 보안 스코프 리소스 접근 요청
        guard url.startAccessingSecurityScopedResource() else {
            throw NSError(domain: "IPA", code: 403, userInfo: [NSLocalizedDescriptionKey: "권한이 없어 파일을 열 수 없습니다."])
        }
        defer { url.stopAccessingSecurityScopedResource() }

        self.ipaURL = url
        setUpPath() // 디렉토리 생성 (없으면)

        let fileName = url.lastPathComponent.replacingOccurrences(of: ".ipa", with: "")
        let zipURL = FilePaths.tmpDirectory.appendingPathComponent("\(fileName).zip")
        let extractedDir = FilePaths.tmpDirectory.appendingPathComponent("Extracted")

        // 이전 작업 디렉토리 정리
        if FileManager.default.fileExists(atPath: extractedDir.path) {
            try FileManager.default.removeItem(at: extractedDir)
        }

        try FileManager.default.copyItem(at: url, to: zipURL)
        SSZipArchive.unzipFile(atPath: zipURL.path, toDestination: extractedDir.path)

        let payloadURL = extractedDir.appendingPathComponent("Payload")
        guard let appDir = try FileManager.default.contentsOfDirectory(at: payloadURL, includingPropertiesForKeys: nil).first(where: { $0.pathExtension == "app" }) else {
            throw NSError(domain: "IPA", code: 404, userInfo: [NSLocalizedDescriptionKey: "Payload 내부에 .app이 없습니다."])
        }

        let infoPlist = appDir.appendingPathComponent("Info.plist")
        let data = try Data(contentsOf: infoPlist)
        guard let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] else {
            throw NSError(domain: "IPA", code: 500, userInfo: [NSLocalizedDescriptionKey: "Info.plist를 파싱할 수 없습니다."])
        }

        self.appName = (plist["CFBundleDisplayName"] as? String) ?? (plist["CFBundleName"] as? String) ?? "Unknown"
        self.bundleIdentifier = plist["CFBundleIdentifier"] as? String ?? ""
        self.appVersion = plist["CFBundleShortVersionString"] as? String ?? ""
        self.minOSVersion = plist["MinimumOSVersion"] as? String ?? ""

        // 아이콘 추출
        if let iconDict = (plist["CFBundleIcons"] as? [String: Any])?["CFBundlePrimaryIcon"] as? [String: Any],
           let iconNames = iconDict["CFBundleIconFiles"] as? [String] {
            for iconName in iconNames.reversed() {
                let possiblePaths = [
                    appDir.appendingPathComponent(iconName),
                    appDir.appendingPathComponent("\(iconName)@2x.png"),
                    appDir.appendingPathComponent("\(iconName)@3x.png")
                ]

                if let foundImage = possiblePaths.compactMap({ UIImage(contentsOfFile: $0.path) }).first {
                    self.appIcon = foundImage
                    break
                }
            }
        }
    }

    // MARK: - Edit Info.plist
    func updatePlist(with values: [String: String]) async throws {
        let extractedDir = FilePaths.tmpDirectory.appendingPathComponent("Extracted")
        let payloadPath = extractedDir.appendingPathComponent("Payload")

        guard let appDir = try? FileManager.default.contentsOfDirectory(
            at: payloadPath,
            includingPropertiesForKeys: nil
        ).first(where: { $0.pathExtension == "app" }) else {
            throw NSError(domain: "IPA", code: 1, userInfo: [NSLocalizedDescriptionKey: "App bundle not found"])
        }

        let infoPlistURL = appDir.appendingPathComponent("Info.plist")
        guard let data = try? Data(contentsOf: infoPlistURL),
              var plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] else {
            throw NSError(domain: "IPA", code: 2, userInfo: [NSLocalizedDescriptionKey: "Info.plist not found or unreadable"])
        }

        for (key, value) in values where !value.isEmpty {
            plist[key] = value
        }

        let updatedData = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        try updatedData.write(to: infoPlistURL)
        print("✅ Info.plist updated successfully")
    }

    // MARK: - Icon Replacement
    func replaceAppIcon(with image: UIImage) async throws {
        self.appIcon = image
        // TODO: Implement app icon replacement in .app directory if needed
    }

    // MARK: - Export IPA
    func exportAsIPA() async throws -> URL {
        guard let ipaURL else {
            throw NSError(domain: "Export", code: 404, userInfo: [NSLocalizedDescriptionKey: "No IPA file loaded"])
        }

        let fileName = ipaURL.lastPathComponent.replacingOccurrences(of: ".ipa", with: "")
        let exportPath = FilePaths.outputDirectory.appendingPathComponent("\(fileName)_exported.ipa")
        let extractedDir = FilePaths.tmpDirectory.appendingPathComponent("Extracted")
        let workingPath = FilePaths.tmpDirectory.appendingPathComponent(fileName)

        if FileManager.default.fileExists(atPath: workingPath.path) {
            try FileManager.default.removeItem(at: workingPath)
        }

        try FileManager.default.copyItem(at: extractedDir, to: workingPath)

        SSZipArchive.createZipFile(atPath: exportPath.path, withContentsOfDirectory: workingPath.path)
        print("✅ IPA exported to \(exportPath.path)")
        return exportPath
    }
}
