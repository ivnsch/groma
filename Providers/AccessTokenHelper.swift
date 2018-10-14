//
//  AccessTokenHelper.swift
//  shoppin
//
//  Created by ischuetz on 19/04/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation

// For now everything commented as not using this and don't want to check/test if keychain wrapper works correctly here.
// But at last with valet and the last time this code was used, it was working!
public struct AccessTokenHelper {

//    fileprivate static let keychain = Keychain()

    public static func loadToken() -> String? {
        return nil


//        let maybeToken = keychain.string(KeychainKeys.token)
//        logger.v("Valet has token: \(maybeToken != nil)")
//
//        return maybeToken ?? loadPrefsToken()
    }
    
    public static func hasToken() -> Bool {
        return false


//        let valetHasTokenMaybe = keychain.contains(KeychainKeys.token)
//
//        func onValetIsNilOrCantAccess() -> Bool {
//            let isInPrefs = loadPrefsToken() != nil
//            logger.d("No valet token, is it in prefs?: \(isInPrefs)")
//            return isInPrefs
//        }
//
//        if keychain.isAvailable() {
//            return keychain.contains(KeychainKeys.token)
//        } else {
//            logger.e("Valet can't access keychain")
//            return onValetIsNilOrCantAccess()
//        }
    }
    
    public static func storeToken(_ token: String) {


//        func afterStoredToken() {
//            logger.v("Stored token")
//            PreferencesManager.savePreference(PreferencesManagerKey.lastTokenUpdate, value: Date())
//        }
//
//        func onKeychainFailed() {
//            PreferencesManager.savePreference(PreferencesManagerKey.loginTokenFallback, value: NSString(string: token))
//            afterStoredToken()
//        }
//
//        if keychain.storeString(key: KeychainKeys.token, value: token) {
//            afterStoredToken()
//        } else {
//            logger.e("Couldn't store token. Fall back to prefs.")
//            onKeychainFailed()
//        }
    }
    
    public static func removeToken() {


//        logger.v("Removing login token")
//
//        if !keychain.remove(KeychainKeys.token) {
//            logger.e("Remove token returned false")
//        }
//        logger.v("Removed login token")
//
//        // In case we have stored a fallback remove it too
//        removePrefsToken()
    }
    
    // MARK: - Prefs
    
    fileprivate static func loadPrefsToken() -> String? {
        return nil


//        logger.v("Loading token from prefs")
//        return PreferencesManager.loadPreference(PreferencesManagerKey.loginTokenFallback)
    }
    
    fileprivate static func removePrefsToken() {


//        PreferencesManager.clearPreference(key: PreferencesManagerKey.loginTokenFallback)
    }
}
