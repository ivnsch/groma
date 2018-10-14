//
//  Keychain.swift
//  shoppin
//
//  Created by ischuetz on 03/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import Valet

public enum KeychainKey: String {
    case token = "token"

    case userEmail = "email"
    case userPassword = "password"
}

class Keychain {

    fileprivate let valet = VALValet(
        identifier: "lisa", // This seems to be a copy paste accident when this class was created. Don't change it.
        accessibility: VALAccessibility.afterFirstUnlock
    )

    func storeString(key: KeychainKey, value: String) -> Bool {
        guard let valet = valet else { logValetNotInitialized(); return false }
        if valet.setString(value, forKey: key.rawValue) {
            logger.d("Successfully set value for key: \(key)", .env)
            return true
        } else {
            // See https://github.com/square/Valet/issues/75 supposedly this happens only during debug. canAccessKeychain returns false with no apparent reason (device).
            logAccessProblem(verb: "store", key: key)
            return false
        }
    }

    func string(_ key: KeychainKey) -> String? {
        guard let valet = valet else { logValetNotInitialized(); return nil }
        return valet.string(forKey: key.rawValue) ?? {
            logAccessProblem(verb: "get", key: key)
            return nil
        }()
    }

    func contains(_ key: KeychainKey) -> Bool {
        guard let valet = valet else { logValetNotInitialized(); return false }
        return valet.containsObject(forKey: key.rawValue)
    }

    func remove(_ key: KeychainKey) -> Bool {
        guard let valet = valet else { logValetNotInitialized(); return false }
        return valet.removeObject(forKey: key.rawValue)
    }

    func removeAll() -> Bool {
        guard let valet = valet else { logValetNotInitialized(); return false }
        return valet.removeAllObjects()
    }

    func isAvailable() -> Bool {
        guard let valet = valet else { logValetNotInitialized(); return false }
        return valet.canAccessKeychain()
    }

    fileprivate func logValetNotInitialized() {
        logger.e("Valet not initialized", .env)
    }

    fileprivate func logAccessProblem(verb: String, key: KeychainKey) {
        logger.e("Was not able to \(verb) value for key: \(key.rawValue). Is available: \(isAvailable()))", .env)
    }
}
