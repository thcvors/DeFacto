//
//  MyUserDefaults.swift
//  DeFäcto
//
//  Created by CVPRO on 7/24/25.
//


import Foundation
import SwiftUI

class MyUserDefaults: ObservableObject {
    static let shared = MyUserDefaults()
    private init() {}

    @AppStorage("defaacto.preference.debugging") var debugging: Bool = true
}
