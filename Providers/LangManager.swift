//
//  LangManager.swift
//  shoppin
//
//  Created by ischuetz on 22/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs

public func trans(_ key: String) -> String {
    return NSLocalizedString(key, comment: "")
}

public func trans(_ key: String, _ params: CVarArg...) -> String {
    return withVaList(params) {
        (NSString(format: NSLocalizedString(key, comment: ""), arguments: $0) as String)
    } as String
}


public class LangManager {

    public let availableLangs = ["de", "en", "es"]
    
    public let defaultLang = "en"
    
    public init() {}
    
    public var deviceLang: String {
        return Bundle.main.preferredLocalizations.first ?? defaultLang
    }
    
    public var appLang: String {
        QL2("Device lang: \(deviceLang)")
        if availableLangs.contains(deviceLang) {
            QL2("Returning device lang: \(deviceLang)")
            return deviceLang
        } else {
            QL2("Device lang not supported, returning default lang: \(defaultLang)")
            return defaultLang
        }
    }
}
