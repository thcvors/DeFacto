//
//  AppInfo.swift
//  DeFäcto
//
//  Created by CVPRO on 7/24/25.
//


import Foundation

struct AppInfo {
    private static let infoDict = Bundle.main.infoDictionary

    static var version: String {
        infoDict?["CFBundleShortVersionString"] as? String ?? "N/A"
    }

    static var build: String {
        infoDict?["CFBundleVersion"] as? String ?? "N/A"
    }
}
