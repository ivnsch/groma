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
        self.addDummyData()
    }
    
    private func addDummyData() {
        let listProvider = RealmListItemProvider()
        let inventoryProvider = RealmInventoryProvider()
        
        let list1 = List(uuid: "1", name: "My first list")
        listProvider.saveList(list1) {result in
            
            let product1 = Product(uuid: "10", name: "Birnen", price: 3)
            let product2 = Product(uuid: "11", name: "Tomaten", price: 2)
            let product3 = Product(uuid: "12", name: "Schwarzer Tee", price: 2)
            let product4 = Product(uuid: "13", name: "Haenchen", price: 5)
            let product5 = Product(uuid: "14", name: "Spaguetti", price: 0.8)
            let product6 = Product(uuid: "15", name: "Sahne", price: 1)
            let product7 = Product(uuid: "16", name: "Pfefferminz Tee", price: 1)

            let product8 = Product(uuid: "17", name: "Kartoffeln", price: 1.2)
            let product9 = Product(uuid: "18", name: "Thunfisch", price: 0.9)
            let product10 = Product(uuid: "19", name: "Zitronen", price: 1.3)
            let product11 = Product(uuid: "20", name: "Kidney bohnen", price: 1)
            let product12 = Product(uuid: "21", name: "Klopapier", price: 3.4)
            let product13 = Product(uuid: "22", name: "Putzmittel boden", price: 5.1)
            let product14 = Product(uuid: "23", name: "Bier", price: 0.8)
            let product15 = Product(uuid: "24", name: "Cola (1L)", price: 1.2)
            let product16 = Product(uuid: "25", name: "Salz", price: 0.7)
            let product17 = Product(uuid: "26", name: "Zucker", price: 0.9)
            let product18 = Product(uuid: "27", name: "Seife", price: 0.8)
            let product19 = Product(uuid: "28", name: "Toastbrot", price: 0.7)
            
            let section1 = Section(uuid: "100", name: "Obst")
            let section2 = Section(uuid: "101", name: "Gemuese")
            let section3 = Section(uuid: "102", name: "Milchprodukte")
            let section4 = Section(uuid: "103", name: "Fleisch")
            let section5 = Section(uuid: "104", name: "Pasta")
            let section6 = Section(uuid: "105", name: "Getraenke")
            
            let listItems = [
                ListItem(uuid: "200", done: false, quantity: 5, product: product1, section: section1, list: list1, order: 0),
                ListItem(uuid: "201", done: false, quantity: 2, product: product2, section: section2, list: list1, order: 0),
                ListItem(uuid: "203", done: false, quantity: 3, product: product3, section: section6, list: list1, order: 0),
                ListItem(uuid: "204", done: false, quantity: 2, product: product4, section: section4, list: list1, order: 0),
                ListItem(uuid: "205", done: true, quantity: 4, product: product5, section: section5, list: list1, order: 0),
                ListItem(uuid: "206", done: true, quantity: 3, product: product6, section: section3, list: list1, order: 0),
                ListItem(uuid: "207", done: true, quantity: 4, product: product7, section: section6, list: list1, order: 0)
            ]
            
            
            listProvider.saveListItems(listItems) {saved in
            
                let inventory1 = Inventory(uuid: "400", name: "My Home inventory")
                inventoryProvider.saveInventory(inventory1) {saved in
                    
                    let inventoryItems = [
                        InventoryItem(quantityDelta: 1, product: product8, inventory: inventory1),
                        InventoryItem(quantityDelta: 10, product: product9, inventory: inventory1),
                        InventoryItem(quantityDelta: 1, product: product10, inventory: inventory1),
                        InventoryItem(quantityDelta: 7, product: product11, inventory: inventory1),
                        InventoryItem(quantityDelta: 4, product: product12, inventory: inventory1),
                        InventoryItem(quantityDelta: 1, product: product13, inventory: inventory1),
                        InventoryItem(quantityDelta: 6, product: product14, inventory: inventory1),
                        InventoryItem(quantityDelta: 4, product: product15, inventory: inventory1),
                        InventoryItem(quantityDelta: 2, product: product16, inventory: inventory1),
                        InventoryItem(quantityDelta: 1, product: product17, inventory: inventory1),
                        InventoryItem(quantityDelta: 3, product: product18, inventory: inventory1),
                        InventoryItem(quantityDelta: 1, product: product19, inventory: inventory1)
                    ]
                    
                    let user = SharedUser(email: "ivanschuetz@gmail.com") // Note this has to be the same as used in login
                    
                    let today = NSDate()
                    let calendar = NSCalendar.currentCalendar()
                    let components = NSDateComponents()
                    components.month = -2
                    let months2Ago = calendar.dateByAddingComponents(components, toDate: today, options: .WrapComponents)!
                    components.month = -4
                    let months4Ago = calendar.dateByAddingComponents(components, toDate: today, options: .WrapComponents)!
                    
                    let inventoryWithHistoryItems = [
                        InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[0], historyItemUuid: "600", addedDate: NSDate(), user: user),
                        InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[1], historyItemUuid: "601", addedDate: months4Ago, user: user),
                        InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[2], historyItemUuid: "602", addedDate: months2Ago, user: user),
                        InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[3], historyItemUuid: "603", addedDate: NSDate(), user: user),
                        InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[4], historyItemUuid: "604", addedDate: months2Ago, user: user),
                        InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[5], historyItemUuid: "605", addedDate: NSDate(), user: user),
                        InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[6], historyItemUuid: "606", addedDate: NSDate(), user: user),
                        InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[7], historyItemUuid: "607", addedDate: months4Ago, user: user),
                        InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[8], historyItemUuid: "608", addedDate: NSDate(), user: user),
                        InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[9], historyItemUuid: "609", addedDate: months2Ago, user: user),
                        InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[10], historyItemUuid: "610", addedDate: NSDate(), user: user),
                        InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[11], historyItemUuid: "611", addedDate: NSDate(), user: user)
                    ]
                
                    inventoryProvider.add(inventoryWithHistoryItems) {saved in
                        print("Done adding dummy data")
                    }
                }
            }
        }
    }
    
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

