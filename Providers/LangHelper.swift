//
//  LangHelper.swift
//  shoppin
//
//  Created by ischuetz on 04/05/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit


public enum SupportedLang: String {
    case DE = "de", EN = "en", ES = "es"
}

// TODO is this used? Duplicate of LangManager?
public class LangHelper: Any {
    
    // TODO rename *supported* lang!
    public static func currentAppLang() -> SupportedLang {
        // TODO relationship with prefered lang? - make sure this can only be one of the preferred langs
        if let langCode = (Locale.current as NSLocale).object(forKey: NSLocale.Key.languageCode) as? String {
            if let supportedLang = SupportedLang(rawValue: langCode) {
                return supportedLang
            } else {
                logger.w("Not supported lang code: \(langCode), returning english")
                return .EN
            }
        } else {
            logger.w("Not lang code, returning english")
            return .EN
        }
    }
}
