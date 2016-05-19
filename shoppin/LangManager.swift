//
//  LangManager.swift
//  shoppin
//
//  Created by ischuetz on 22/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit

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
        return NSLocale.preferredLanguages().first ?? defaultLang
    }
    
    var appLang: String {
        if availableLangs.contains(deviceLang) {
            return deviceLang
        } else {
            return defaultLang
        }
    }
}
