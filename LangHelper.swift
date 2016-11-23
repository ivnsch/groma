//
//  LangHelper.swift
//  shoppin
//
//  Created by ischuetz on 04/05/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs

enum SupportedLang: String {
    case DE = "de", EN = "en", ES = "es"
}

// TODO is this used? Duplicate of LangManager?
class LangHelper: Any {
    
    // TODO rename *supported* lang!
    static func currentAppLang() -> SupportedLang {
        // TODO relationship with prefered lang? - make sure this can only be one of the preferred langs
        if let langCode = (Locale.current as NSLocale).object(forKey: NSLocale.Key.languageCode) as? String {
            if let supportedLang = SupportedLang(rawValue: langCode) {
                return supportedLang
            } else {
                QL3("Not supported lang code: \(langCode), returning english")
                return .EN
            }
        } else {
            QL3("Not lang code, returning english")
            return .EN
        }
    }
}
