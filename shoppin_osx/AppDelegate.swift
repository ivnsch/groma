//
//  AppDelegate.swift
//  shoppin_osx
//
//  Created by ischuetz on 07.02.15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Cocoa
import CoreData

@objc
@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {



    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
       
        #if DEBUG
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "NSConstraintBasedLayoutVisualizeMutuallyExclusiveConstraints")
            #else
        #endif
    }
    

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
           PersistentStoreHelper.sharedInstance.saveContext()
    }


}

