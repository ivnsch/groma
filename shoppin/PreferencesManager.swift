//
//  PreferencesManager.swift
//  shoppin
//
//  Created by ischuetz on 01.01.15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit

// TODO is it possible to declare this in class as only "Key"
enum PreferencesManagerKey: String {
    case listId = "listId"
}

class PreferencesManager {

    class func savePreference<T: AnyObject>(key:PreferencesManagerKey, value:T) {
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
    
    class func loadPreference<T: Any>(key:PreferencesManagerKey) -> T? {
        let objectMaybe: AnyObject? = self.loadPreference(key: key.rawValue)
        if let object: AnyObject = objectMaybe {
            
            let casted = object as? T
            
            if casted == nil {
                println("Casting error! the preference is stored but wrong type...")
            }
            
            return casted
            
            
        } else {
            return nil
        }
    }
    
    class private func savePreference<T: AnyObject>(#key: String, value: T) {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.setObject(value, forKey: key)
        userDefaults.synchronize()
    }
    
    class private func loadPreference(#key:String) -> AnyObject? {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        return userDefaults.objectForKey(key)
    }
}
