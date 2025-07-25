//
//  IPAFile.swift
//  DeFacto
//
//  Created by CVPRO on 7/24/25.
//

import Foundation
import ZipArchive

class IPAFile: ObservableObject {
    static let shared = IPAFile()
    private init() {}

    // MARK: - File Info
    var fileURL: URL = URL(fileURLWithPath: "")
    var contentDirURL: URL = URL(fileURLWithPath: "")
    var payloadURL: URL = URL(fileURLWithPath: "")
    var infoPlistPath: URL = URL(fileURLWithPath: "")

    // MARK: - State Flags
    @Published var fileName: String = ""
    var fileImported: Bool = false
    var payloadExist: Bool = false
    var appContentExist: Bool = false
    var infoPlistExist: Bool = false
    var app_executableExist: Bool = false
    @Published var processing: Bool = false

    // MARK: - IPA Info
    @Published var appNameInPayload: String = ""
    @Published var app_executable: String = ""
    @Published var app_name: String = ""
    @Published var app_bundle: String = ""
    @Published var app_min_ios: String = ""

    // MARK: - Internal Config
    var config: [String: Any]?

    // MARK: - Payload Methods
    func getPayloadURL() {
        payloadURL = contentDirURL.appendingPathComponent("Payload")
        payloadExist = FileManager.default.fileExists(atPath: payloadURL.path)
    }

    func getAppNameInPayload() {
        guard let contents = try? FileManager.default.contentsOfDirectory(atPath: payloadURL.path) else {
            appContentExist = false
            return
        }

        for item in contents where item.hasSuffix(".app") {
            appNameInPayload = item
            appContentExist = true
            return
        }

        appContentExist = false
    }

    func getInfoPlistPath() {
        guard appContentExist else {
            infoPlistExist = false
            return
        }

        infoPlistPath = payloadURL.appendingPathComponent("\(appNameInPayload)/Info.plist")
        infoPlistExist = FileManager.default.fileExists(atPath: infoPlistPath.path)
    }

    func getInfoPlistValue() {
        do {
            let plistData = try Data(contentsOf: infoPlistPath)
            guard let dict = try PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [String: Any] else { return }

            config = dict

            if let executable = dict["CFBundleExecutable"] as? String {
                app_executable = executable
                app_name = dict["CFBundleName"] as? String ?? ""
                app_bundle = dict["CFBundleIdentifier"] as? String ?? ""
                app_min_ios = dict["MinimumOSVersion"] as? String ?? "14.0"
                app_executableExist = true
            } else {
                app_executableExist = false
            }
        } catch {
            print("Failed to read Info.plist: \(error.localizedDescription)")
        }
    }

    func updateInfoPlistValue() {
        guard let plist = NSMutableDictionary(contentsOfFile: infoPlistPath.path) else { return }

        plist["CFBundleDisplayName"] = app_name
        plist["CFBundleIdentifier"] = app_bundle
        plist.write(toFile: infoPlistPath.path, atomically: false)
    }

    // MARK: - File Manipulation
    func moveModdedPackage() {
        do {
            let newAppFolderName = "\(app_executable).app"
            let currentAppPath = payloadURL.appendingPathComponent(appNameInPayload)
            let newAppPath = payloadURL.appendingPathComponent(newAppFolderName)

            if appNameInPayload != newAppFolderName {
                try FileManager.default.moveItem(at: currentAppPath, to: newAppPath)
            }

            try FileManager.default.moveItem(at: contentDirURL, to: FilePaths.tmpDirectory.appendingPathComponent(app_executable))
        } catch {
            print("Failed to move package: \(error.localizedDescription)")
        }
    }

    func zipToIPA() {
        let outputPath = FilePaths.outputDirectory.appendingPathComponent("\(app_executable).ipa").path
        let contentPath = FilePaths.tmpDirectory.appendingPathComponent(app_executable).path

        SSZipArchive.createZipFile(atPath: outputPath, withContentsOfDirectory: contentPath)
    }

    func resultIPAExist() -> Bool {
        FileManager.default.fileExists(atPath: FilePaths.outputDirectory.appendingPathComponent("\(app_executable).ipa").path)
    }
}
