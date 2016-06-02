//
//  LangManager.swift
//  shoppin
//
//  Created by ischuetz on 22/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs

func trans(key: String) -> String {
    return NSLocalizedString(key, comment: "")
}

func trans(key: String, _ params: CVarArgType...) -> String {
    return withVaList(params) {
        NSString(format: NSLocalizedString(key, comment: ""), arguments: $0)
    } as String
}


class LangManager {

    let availableLangs = ["de", "en", "es"]
    
    let defaultLang = "en"
    
    var deviceLang: String {
        return NSBundle.mainBundle().preferredLocalizations.first ?? defaultLang
    }
    
    var appLang: String {
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
