//
//  LangHelper.swift
//  shoppin
//
//  Created by ischuetz on 04/05/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs

class CountryHelper {
    
//    private static let serverSupportedCountries = ["de"]
    fileprivate static let serverSupportedCountries: [String] = []
    
    static func currentDeviceCountry() -> String? {
        return (Locale.current as NSLocale).object(forKey: NSLocale.Key.countryCode) as? String
    }
    
    static func isInServerSupportedCountry() -> Bool {
        
        let countryCodeMaybe = currentDeviceCountry()?.lowercased()
        let isSupported = countryCodeMaybe.map{serverSupportedCountries.contains($0)} ?? false
        
        QL1("Is server supported country: \(countryCodeMaybe), isSupported: \(isSupported)")
        
        return isSupported
//        return true
    }
}
