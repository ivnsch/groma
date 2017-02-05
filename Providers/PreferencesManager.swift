//
//  PreferencesManager.swift
//  shoppin
//
//  Created by ischuetz on 28/03/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

// TODO is it possible to declare this in class as only "Key"
public enum PreferencesManagerKey: String {
    case listId = "listId"
    case hasLaunchedBefore = "hasLaunchedBefore"
    case isFirstLaunch = "isFirstLaunch"
    case firstLaunchDate = "firstLaunchDate"
    case email = "email"
    case deviceId = "did"
    case showIntro = "showIntro"
    case lastTokenUpdate = "lastTokenUpdate"
    case dontShowAppRatingDialogAgain = "dontShowAppRatingDialogAgain"
    case lastAppRatingDialogDate = "lastAppRatingDialogDate"

    case shownCanSwipeToOpenStash = "shownCanSwipeToOpenStash"
    
    // explanation popups that are displayed only once after installation
    case showedAddDirectlyToInventoryHelp = "showedAddDirectlyToInventoryHelp"
    case showedDeleteHistoryItemHelp = "showedDeleteHistoryItemHelp"
    case showedCanSwipeToIncrementCounter = "showedCanSwipeToIncrementCounter" // we show this after n times, since it's not critical and we don't want to overwhelm user with popups the first time they use the app.
    case showedLongTapToEditCounter = "showedLongTapToEditCounter" // we show this after n times, since it's not critical and we don't want to overwhelm user with popups the first time they use the app.

    case websocketUuid = "websocketUuid"
    
    case loginTokenFallback = "loginTokenFallback"
    
    case registeredWithThisDevice = "registeredWithThisDevice"
    case overwroteLocalDataAfterNewDeviceLogin = "overwroteLocalDataAfterNewDeviceLogin"
    
    case userDisabledWebsocket = "userDisabledWebsocket"
    
    case lastShouldUpdateAppDialogDate = "lastShouldUpdateAppDialogDate" // the last date where should update app dialog was shown
    
    case cancelledClearFirstIncompleteMonthStats = "cancelledClearFirstIncompleteMonthStats"
    case clearedFirstIncompleteMonthStats = "clearedFirstIncompleteMonthStats"
    
    case internalMessageShowedNoServer = "internalMessageNoServer"
}

public class PreferencesManager {

    public class func savePreference<T: Any>(_ key: PreferencesManagerKey, value: T) {
        self.savePreference(key: key.rawValue, value: value)
    }
    
    //TODO is there a way to avoid having to pass e.g NSString to save a String. Tried with cast to AnyObject but it doesn't compile
//    class func savePreference<T>(key:PreferencesManagerKey, value:T) -> Bool {
//        if let obj = value as? AnyObject {
//            self.savePreference(key: key.rawValue, value: value as? AnyObject)
//        } else {
//            return false
//        }
//        return true
//    }
    
    public class func loadPreference<T: Any>(_ key:PreferencesManagerKey) -> T? {
        let objectMaybe: Any? = self.loadPreference(key: key.rawValue)
        if let object: Any = objectMaybe {
            
            let casted = object as? T
            
            if casted == nil {
                print("Casting error! the preference is stored but wrong type...")
            }
            
            return casted
            
            
        } else {
            return nil
        }
    }
    
    class fileprivate func savePreference<T: Any>(key: String, value: T) {
        let userDefaults = UserDefaults.standard
        userDefaults.set(value, forKey: key)
        userDefaults.synchronize()
    }

    public class func clearPreference(key: PreferencesManagerKey) {
        let userDefaults = UserDefaults.standard
        userDefaults.set(nil, forKey: key.rawValue)
        userDefaults.synchronize()
    }
    
    class fileprivate func loadPreference(key:String) -> Any? {
        let userDefaults = UserDefaults.standard
        return userDefaults.object(forKey: key)
    }
}
