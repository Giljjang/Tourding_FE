//
//  AppConfig.swift
//  Tourding_FE
//
//  Created by 이유현 on 7/24/25.
//

import Foundation

private let BASE_URL_RAW = Bundle.main.infoDictionary?["BASE_URL"] as? String ?? ""
let BASE_URL = BASE_URL_RAW.isEmpty ? "" : "https://\(BASE_URL_RAW)"
