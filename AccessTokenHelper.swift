//
//  AccessTokenHelper.swift
//  shoppin
//
//  Created by ischuetz on 19/04/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import Valet
import QorumLogs

struct AccessTokenHelper {
    
    static func loadToken() -> String? {
        let valet = VALValet(identifier: KeychainKeys.ValetIdentifier, accessibility: VALAccessibility.AfterFirstUnlock)
        let maybeToken = valet?.stringForKey(KeychainKeys.token)
        QL1("Loaded valet token: \(maybeToken)")
        
        return maybeToken ?? loadPrefsToken()
    }
    
    static func hasToken() -> Bool {
        let valet = VALValet(identifier: KeychainKeys.ValetIdentifier, accessibility: VALAccessibility.AfterFirstUnlock)
        if let valet = valet {
            return valet.containsObjectForKey(KeychainKeys.token)
        } else {
            let isInPrefs = loadPrefsToken() != nil
            QL4("Valet token set, is in prefs?: \(isInPrefs)")
            return isInPrefs
        }
    }
    
    static func storeToken(token: String) {
        
        func afterStoredToken() {
            QL1("Stored token: \(token)")
            PreferencesManager.savePreference(PreferencesManagerKey.lastTokenUpdate, value: NSDate())
        }
        
        func onValetFailed() {
            PreferencesManager.savePreference(PreferencesManagerKey.loginTokenFallback, value: NSString(string: token))
            afterStoredToken()
        }
        
        let valet = VALValet(identifier: KeychainKeys.ValetIdentifier, accessibility: VALAccessibility.AfterFirstUnlock)
        if let valet = valet {
            if valet.setString(token, forKey: KeychainKeys.token) {
                afterStoredToken()
            } else {
                // See https://github.com/square/Valet/issues/75 supposedly this happens only during debug. canAccessKeychain returns false with no apparent reason (device).
                QL4("Couldn't store token using valet. Can access key chain: \(valet.canAccessKeychain()). Fall back to prefs.")
                onValetFailed()
            }
        } else {
            QL4("Valet not set, couldn't store token")
            onValetFailed()
        }
    }
    
    static func removeToken() {
        
        QL1("Removing login token")
        
        let valet = VALValet(identifier: KeychainKeys.ValetIdentifier, accessibility: VALAccessibility.AfterFirstUnlock)
        if let valet = valet {
            if !valet.removeObjectForKey(KeychainKeys.token) {
                QL4("Remove token returned false")
            }
            QL1("Removed login token")
        } else {
            QL4("Valet not set")
        }
        
        // In case we have stored a fallback remove it too
        removePrefsToken()
    }
    
    // MARK: - Prefs
    
    private static func loadPrefsToken() -> String? {
        return PreferencesManager.loadPreference(PreferencesManagerKey.loginTokenFallback)
    }
    
    private static func removePrefsToken() {
        PreferencesManager.clearPreference(key: PreferencesManagerKey.loginTokenFallback)
    }
}
