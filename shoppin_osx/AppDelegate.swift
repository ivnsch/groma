//
//  AppDelegate.swift
//  shoppin_osx
//
//  Created by ischuetz on 07.02.15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Cocoa
import CoreData
import Valet

@objc
@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    private var suggestionsPrefiller: SuggestionsPrefiller? // arc
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application

        #if DEBUG
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "NSConstraintBasedLayoutVisualizeMutuallyExclusiveConstraints")
            
            generatePrefillDatabase() // enable this only to generate prefilled database
            #else
        #endif
    }
    
    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
    
    /**
    * Create database which we embed in the app in order to prefill the app's database
    * TODO try to use test for this (PrefillDatabase - not working because sth with Realm). This should not be in of the app.
    */
    private func generatePrefillDatabase() {
        print("Creating prefilled database")
        self.suggestionsPrefiller = SuggestionsPrefiller()
        self.suggestionsPrefiller?.prefill {
            print("Finished creating prefilled database")
        }
    }
}

