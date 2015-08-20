//
//  AppDelegate.swift
//  shoppin
//
//  Created by ischuetz on 06.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import UIKit
import CoreData

@objc
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        if !(PreferencesManager.loadPreference(PreferencesManagerKey.hasLaunchedBefore) ?? false) {
            PreferencesManager.savePreference(PreferencesManagerKey.hasLaunchedBefore, value: true)
            self.firstLaunchSetup()
        }
        
        let viewController: UIViewController = {
            if ProviderFactory().userProvider.loggedIn {
                return UIStoryboard.mainTabController()
            } else {
                return UIStoryboard.introNavController()
            }
        }()
        
        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        self.window?.rootViewController = viewController
        self.window?.makeKeyAndVisible()
        
        return true
    }
    
    private func firstLaunchSetup() {
        #if DEBUG
            self.debugFirstLaunchSetup()
            #else
        #endif
    }
    
    private func debugFirstLaunchSetup() {
//        self.addDummyPersistentObjects()
    }
    

    // TODO does this still make sense, maybe remove
//    private func addDummyPersistentObjects() {
//        let listItemProviderImpl = ListItemProviderImpl()
//        let mock = ListItemProviderMock()
//        listItemProviderImpl.lists {try in
//            if let firstList = try.success?.first {
//                mock.listItems(firstList, handler: {try in
//                    
//                    if let listItems = try.success {
//                        for listItem in listItems {
//                            listItem.list = firstList // change mock list to valid core data list
//                            listItemProviderImpl.add(listItem, handler: {try in
//                            })
//                        }
//                    }
//                })
//            }
//        }
//    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
    }
}

