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
        let valet = VALValet(identifier: KeychainKeys.ValetIdentifier, accessibility: VALAccessibility.afterFirstUnlock)
        let maybeToken = valet?.string(forKey: KeychainKeys.token)
        QL1("Valet has token: \(maybeToken != nil)")
        
        return maybeToken ?? loadPrefsToken()
    }
    
    static func hasToken() -> Bool {
        
        let valet = VALValet(identifier: KeychainKeys.ValetIdentifier, accessibility: VALAccessibility.afterFirstUnlock)
        let valetHasTokenMaybe = valet?.containsObject(forKey: KeychainKeys.token)
        
        func onValetIsNilOrCantAccess() -> Bool {
            let isInPrefs = loadPrefsToken() != nil
            QL2("No valet token, is it in prefs?: \(isInPrefs)")
            return isInPrefs
        }
        
        if let valet = valet {
            if valet.canAccessKeychain() {
                return valet.containsObject(forKey: KeychainKeys.token)
            } else {
                QL4("Valet can't access keychain")
                return onValetIsNilOrCantAccess()
            }
        } else {
            QL4("Valet is nil")
            return onValetIsNilOrCantAccess()
        }
    }
    
    static func storeToken(_ token: String) {
        
        func afterStoredToken() {
            QL1("Stored token")
            PreferencesManager.savePreference(PreferencesManagerKey.lastTokenUpdate, value: Date())
        }
        
        func onValetFailed() {
            PreferencesManager.savePreference(PreferencesManagerKey.loginTokenFallback, value: NSString(string: token))
            afterStoredToken()
        }
        
        let valet = VALValet(identifier: KeychainKeys.ValetIdentifier, accessibility: VALAccessibility.afterFirstUnlock)
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
        
        let valet = VALValet(identifier: KeychainKeys.ValetIdentifier, accessibility: VALAccessibility.afterFirstUnlock)
        if let valet = valet {
            if !valet.removeObject(forKey: KeychainKeys.token) {
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
    
    fileprivate static func loadPrefsToken() -> String? {
        QL1("Loading token from prefs")
        return PreferencesManager.loadPreference(PreferencesManagerKey.loginTokenFallback)
    }
    
    fileprivate static func removePrefsToken() {
        PreferencesManager.clearPreference(key: PreferencesManagerKey.loginTokenFallback)
    }
}
