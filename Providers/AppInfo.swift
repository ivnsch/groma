// src https://github.com/kostiakoval/AppInfo/blob/master/AppInfo/Classes/AppInfo.swift
//
//  AppInfo.swift
//  AppInfo
//
//  Created by Konstantin Koval on 06/03/15.
//  Copyright (c) 2015 Kostiantyn Koval. All rights reserved.
//

import Foundation

//MARK: - Convertors

private func string(_ object: AnyObject?) -> String? {
    return object as? String
}

private func stringToInt(_ object: AnyObject?) -> Int? {
    return (object as? String).map{Int($0)} ?? nil
}

private func int(_ object: AnyObject?) -> Int? {
    return (object as? NSNumber)?.intValue
}

private func array<T>(_ object: AnyObject?) -> Array<T>? {
    return object as? Array
}

public struct AppInfo {
    
    fileprivate static let bundleInfo: Dictionary<String, AnyObject> = Bundle.main.infoDictionary! as Dictionary<String, AnyObject>
    
    public static var CFBundleIdentifier: String? {
        return bundleInfo["CFBundleIdentifier"] >>> string
    }
    
    public static var DTPlatformName: String? {
        return bundleInfo["DTPlatformName"] >>> string
    }
    
    public static var UIMainStoryboardFile: String? {
        return bundleInfo["UIMainStoryboardFile"] >>> string
    }
    
    public static var CFBundleVersion: Int? {
        return bundleInfo["CFBundleVersion"] >>> stringToInt
    }
    
    public static var CFBundleSignature: String? {
        return bundleInfo["CFBundleSignature"] >>> string
    }
    
    public static var CFBundleExecutable: String? {
        return bundleInfo["CFBundleExecutable"] >>> string
    }
    
    public static var LSRequiresIPhoneOS: Int? {
        return bundleInfo["LSRequiresIPhoneOS"] >>> int
    }
    
    public static var CFBundleName: String? {
        return bundleInfo["CFBundleName"] >>> string
    }
    
    public static var UILaunchStoryboardName: String? {
        return bundleInfo["UILaunchStoryboardName"] >>> string
    }
    
    public static var CFBundleSupportedPlatforms: Array<String>? {
        return bundleInfo["CFBundleSupportedPlatforms"] >>> array
    }
    
    public static var CFBundlePackageType: String? {
        return bundleInfo["CFBundlePackageType"] >>> string
    }
    
    public static var CFBundleNumericVersion: Int? {
        return bundleInfo["CFBundleNumericVersion"] >>> int
    }
    
    public static var CFBundleInfoDictionaryVersion: String? {
        return bundleInfo["CFBundleInfoDictionaryVersion"] >>> string
    }
    
    public static var UIRequiredDeviceCapabilities: Array<String>? {
        return bundleInfo["UIRequiredDeviceCapabilities"] >>> array
    }
    
    public static var UISupportedInterfaceOrientations: Array<String>? {
        return bundleInfo["UISupportedInterfaceOrientations"] >>> array
    }
    
    public static var CFBundleInfoPlistURL: String? {
        return bundleInfo["CFBundleInfoPlistURL"] >>> string
    }
    
    public static var CFBundleDevelopmentRegion: String? {
        return bundleInfo["CFBundleDevelopmentRegion"] >>> string
    }
    
    public static var DTSDKName: String? {
        return bundleInfo["DTSDKName"] >>> string
    }
    
    public static var UIDeviceFamily: Array<Int>? {
        return bundleInfo["UIDeviceFamily"] >>> array
    }
    
    public static var CFBundleShortVersionString: String? {
        return bundleInfo["CFBundleShortVersionString"] >>> string
    }
}
