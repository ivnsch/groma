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
    
    private static let serverSupportedCountries = ["de"]
    
    static func currentDeviceCountry() -> String? {
        return NSLocale.currentLocale().objectForKey(NSLocaleCountryCode) as? String
    }
    
    static func isInServerSupportedCountry() -> Bool {
        
        let countryCodeMaybe = currentDeviceCountry()?.lowercaseString
        let isSupported = countryCodeMaybe.map{serverSupportedCountries.contains($0)} ?? false
        
        QL1("Is server supported country: \(countryCodeMaybe), isSupported: \(isSupported)")
        
        return isSupported
//        return true
    }
}