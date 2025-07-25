//
//  FilePaths.swift
//  DeFäcto
//
//  Created by CVPRO on 7/24/25.
//

import Foundation

struct FilePaths {
    static let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    static let tmpDirectory = documentDirectory.appendingPathComponent("tmp")
    static let outputDirectory = documentDirectory.appendingPathComponent("output")
}
