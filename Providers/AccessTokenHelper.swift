//
//  AccessTokenHelper.swift
//  shoppin
//
//  Created by ischuetz on 19/04/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import Valet


public struct AccessTokenHelper {
    
    public static func loadToken() -> String? {
        let valet = VALValet(identifier: KeychainKeys.ValetIdentifier, accessibility: VALAccessibility.afterFirstUnlock)
        let maybeToken = valet?.string(forKey: KeychainKeys.token)
        logger.v("Valet has token: \(maybeToken != nil)")
        
        return maybeToken ?? loadPrefsToken()
    }
    
    public static func hasToken() -> Bool {
        
        let valet = VALValet(identifier: KeychainKeys.ValetIdentifier, accessibility: VALAccessibility.afterFirstUnlock)
        let valetHasTokenMaybe = valet?.containsObject(forKey: KeychainKeys.token)
        
        func onValetIsNilOrCantAccess() -> Bool {
            let isInPrefs = loadPrefsToken() != nil
            logger.d("No valet token, is it in prefs?: \(isInPrefs)")
            return isInPrefs
        }
        
        if let valet = valet {
            if valet.canAccessKeychain() {
                return valet.containsObject(forKey: KeychainKeys.token)
            } else {
                logger.e("Valet can't access keychain")
                return onValetIsNilOrCantAccess()
            }
        } else {
            logger.e("Valet is nil")
            return onValetIsNilOrCantAccess()
        }
    }
    
    public static func storeToken(_ token: String) {
        
        func afterStoredToken() {
            logger.v("Stored token")
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
                logger.e("Couldn't store token using valet. Can access key chain: \(valet.canAccessKeychain()). Fall back to prefs.")
                onValetFailed()
            }
        } else {
            logger.e("Valet not set, couldn't store token")
            onValetFailed()
        }
    }
    
    public static func removeToken() {
        
        logger.v("Removing login token")
        
        let valet = VALValet(identifier: KeychainKeys.ValetIdentifier, accessibility: VALAccessibility.afterFirstUnlock)
        if let valet = valet {
            if !valet.removeObject(forKey: KeychainKeys.token) {
                logger.e("Remove token returned false")
            }
            logger.v("Removed login token")
        } else {
            logger.e("Valet not set")
        }
        
        // In case we have stored a fallback remove it too
        removePrefsToken()
    }
    
    // MARK: - Prefs
    
    fileprivate static func loadPrefsToken() -> String? {
        logger.v("Loading token from prefs")
        return PreferencesManager.loadPreference(PreferencesManagerKey.loginTokenFallback)
    }
    
    fileprivate static func removePrefsToken() {
        PreferencesManager.clearPreference(key: PreferencesManagerKey.loginTokenFallback)
    }
}
