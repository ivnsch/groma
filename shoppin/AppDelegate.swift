//
//  AppDelegate.swift
//  shoppin
//
//  Created by ischuetz on 06.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import UIKit
import CoreData
import FBSDKCoreKit
import Reachability
import ChameleonFramework

@objc
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    private var reachability: Reachability!
    
    private let userProvider = ProviderFactory().userProvider // arc
    private let listProvider = RealmListItemProvider() // arc
    private let inventoryProvider = RealmInventoryProvider() // arc
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        if !(PreferencesManager.loadPreference(PreferencesManagerKey.hasLaunchedBefore) ?? false) {
            PreferencesManager.savePreference(PreferencesManagerKey.hasLaunchedBefore, value: true)
            self.firstLaunchSetup()
        }
        
        let viewController: UIViewController = {
            if PreferencesManager.loadPreference(PreferencesManagerKey.showIntro) ?? true {
                return UIStoryboard.introNavController()
            } else {
                return UIStoryboard.mainTabController()
            }
        }()
        
        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        self.window?.rootViewController = viewController
        self.window?.makeKeyAndVisible()

        initReachability()

        initGlobalAppearance()
        
        // Facebook sign-in
        return FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    private func initGlobalAppearance() {
        let fontName = "HelveticaNeue"
        let lightFontName = "HelveticaNeue-Light"
        let boldFontName = "HelveticaNeue-Bold"
        if let tabsFont = UIFont(name: lightFontName, size: 11), barButtonsFont = UIFont(name: fontName, size: 17), titleFont = UIFont(name: boldFontName, size: 17),segmentedControlFont = UIFont(name: lightFontName, size: 12) {
            UITabBarItem.appearance().setTitleTextAttributes([NSFontAttributeName: tabsFont], forState: .Normal)
            UINavigationBar.appearance().titleTextAttributes = [NSFontAttributeName: titleFont, NSForegroundColorAttributeName: Theme.navigationBarTextColor]
            UIBarButtonItem.appearance().setTitleTextAttributes([NSFontAttributeName: barButtonsFont, NSForegroundColorAttributeName: Theme.navigationBarTextColor], forState: .Normal)
            UISegmentedControl.appearance().setTitleTextAttributes([NSFontAttributeName: segmentedControlFont], forState: .Normal)
        } else {
            print("Error: Font not found: \(fontName) or: \(lightFontName)")
        }

//        UINavigationBar.appearance().barTintColor = UIColor(red: 93/255, green: 167/255, blue: 1, alpha: 1) // color "theme": 5DA7FF (blue), FF5DA6 (pink), A7FF5D(green)
        // grey: AEAEAE
//        UINavigationBar.appearance().tintColor = UIColor.blackColor()
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        
//        print("AppDelegate open url: \(url)")
        
        if url.scheme.contains("fb335124139955932") {
            return FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)
        } else if url.scheme.contains("google") {
            return GIDSignIn.sharedInstance().handleURL(url, sourceApplication: sourceApplication, annotation: annotation)
        } else {
            return false
        }
    }
    
    private func firstLaunchSetup() {
        #if DEBUG
            debugFirstLaunchSetup()
            #else
        #endif
        // TODO async and timing, ensure any other component that touches realm runs after prefill is finished. Prefill creates the realm file.
        // since this is done the first time it may make sense to put it in the intro screen? this way also more controllable
        prefillDatabase()
    }
    
    private func prefillDatabase(onFinish: VoidFunction? = nil) {

        let p = NSHomeDirectory() + "/Documents/default.realm"
        if let prefillPath = NSBundle.mainBundle().pathForResource("prefill", ofType: "realm") {
            print("Copying prefill database to: \(p)")
            do {
                try NSFileManager.defaultManager().copyItemAtPath(prefillPath, toPath: p)
                print("Copied prefill database")
                onFinish?()
                
            } catch let error as NSError {
                print("Error copying prefill database: \(error)")
                onFinish?()
            }
        } else {
            print("Prefill database was not found")
            onFinish?()
        }
    }
    
    
    // MARK: - Debug
    
    private func debugFirstLaunchSetup() {
        self.addDummyData()
    }
    
    private func addDummyData() {

        let list1 = List(uuid: "1", name: "My first list", bgColor: RandomFlatColorWithShade(.Dark))
        listProvider.saveList(list1) {[weak self] result in
            
            guard let weakSelf = self else {return}

            let section1 = Section(uuid: "100", name: "Obst", order: 0)
            let section2 = Section(uuid: "101", name: "Gemuese", order: 1)
            let section3 = Section(uuid: "102", name: "Milchprodukte", order: 2)
            let section4 = Section(uuid: "103", name: "Fleisch", order: 3)
            let section5 = Section(uuid: "104", name: "Pasta", order: 4)
            let section6 = Section(uuid: "105", name: "Getraenke", order: 5)
            let cleaning = Section(uuid: "106", name: "Putzmittel", order: 6)
            let hygienic = Section(uuid: "107", name: "Hygiene", order: 7)
            let spices = Section(uuid: "108", name: "Gewürze", order: 8)
            let bread = Section(uuid: "109", name: "Brot", order: 8)

            let fruitsCat = "Obst"
            let vegetablesCat = "Gemuese"
            let milkCat = "Milchprodukte"
            let meatCat = "Fleisch"
            let pastaCat = "Pasta"
            let drinksCat = "Getraenke"
            let cleaningCat = "Putzmittel"
            let hygienicCat = "Hygiene"
            let spicesCat = "Gewürze"
            let breadCat = "Brot"
            
            let product1 = Product(uuid: "10", name: "Birnen", price: 3, category: fruitsCat)
            let product2 = Product(uuid: "11", name: "Tomaten", price: 2, category: vegetablesCat)
            let product3 = Product(uuid: "12", name: "Schwarzer Tee", price: 2, category: drinksCat)
            let product4 = Product(uuid: "13", name: "Haenchen", price: 5, category: meatCat)
            let product5 = Product(uuid: "14", name: "Spaguetti", price: 0.8, category: pastaCat)
            let product6 = Product(uuid: "15", name: "Sahne", price: 1, category: milkCat)
            let product7 = Product(uuid: "16", name: "Pfefferminz Tee", price: 1, category: drinksCat)

            let product8 = Product(uuid: "17", name: "Kartoffeln", price: 1.2, category: vegetablesCat)
            let product9 = Product(uuid: "18", name: "Thunfisch", price: 0.9, category: meatCat)
            let product10 = Product(uuid: "19", name: "Zitronen", price: 1.3, category: fruitsCat)
            let product11 = Product(uuid: "20", name: "Kidney bohnen", price: 1, category: vegetablesCat)
            let product12 = Product(uuid: "21", name: "Klopapier", price: 3.4, category: cleaningCat)
            let product13 = Product(uuid: "22", name: "Putzmittel boden", price: 5.1, category: hygienicCat)
            let product14 = Product(uuid: "23", name: "Bier", price: 0.8, category: drinksCat)
            let product15 = Product(uuid: "24", name: "Cola (1L)", price: 1.2, category: drinksCat)
            let product16 = Product(uuid: "25", name: "Salz", price: 0.7, category: spicesCat)
            let product17 = Product(uuid: "26", name: "Zucker", price: 0.9, category: spicesCat)
            let product18 = Product(uuid: "27", name: "Seife", price: 0.8, category: hygienicCat)
            let product19 = Product(uuid: "28", name: "Toastbrot", price: 0.7, category: breadCat)

            
            let listItems = [
                ListItem(uuid: "200", status: .Todo, quantity: 5, product: product1, section: section1, list: list1, order: 0),
                ListItem(uuid: "201", status: .Todo, quantity: 2, product: product2, section: section2, list: list1, order: 0),
                ListItem(uuid: "203", status: .Todo, quantity: 3, product: product3, section: section6, list: list1, order: 0),
                ListItem(uuid: "204", status: .Todo, quantity: 2, product: product4, section: section4, list: list1, order: 0),
                ListItem(uuid: "205", status: .Todo, quantity: 4, product: product5, section: section5, list: list1, order: 0),
                ListItem(uuid: "206", status: .Todo, quantity: 3, product: product6, section: section3, list: list1, order: 0),
                ListItem(uuid: "207", status: .Todo, quantity: 4, product: product7, section: section6, list: list1, order: 1)
            ]
            
            weakSelf.listProvider.saveListItems(listItems, incrementQuantity: false) {saved in
            
                let inventory1 = Inventory(uuid: "400", name: "My Home inventory")
                weakSelf.inventoryProvider.saveInventory(inventory1) {saved in
            
                    func inventoryItem(quantityDelta quantityDelta: Int, product: Product, inventory: Inventory) -> InventoryItem {
                        return InventoryItem(quantity: quantityDelta, quantityDelta: quantityDelta, product: product, inventory: inventory)
                    }
                    
                    
                    let inventoryItems = [
                        inventoryItem(quantityDelta: 1, product: product8, inventory: inventory1),
                        inventoryItem(quantityDelta: 10, product: product9, inventory: inventory1),
                        inventoryItem(quantityDelta: 1, product: product10, inventory: inventory1),
                        inventoryItem(quantityDelta: 7, product: product11, inventory: inventory1),
                        inventoryItem(quantityDelta: 4, product: product12, inventory: inventory1),
                        inventoryItem(quantityDelta: 1, product: product13, inventory: inventory1),
                        inventoryItem(quantityDelta: 6, product: product14, inventory: inventory1),
                        inventoryItem(quantityDelta: 4, product: product15, inventory: inventory1),
                        inventoryItem(quantityDelta: 2, product: product16, inventory: inventory1),
                        inventoryItem(quantityDelta: 1, product: product17, inventory: inventory1),
                        inventoryItem(quantityDelta: 3, product: product18, inventory: inventory1),
                        inventoryItem(quantityDelta: 1, product: product19, inventory: inventory1),
                        
                        inventoryItem(quantityDelta: 1, product: product8, inventory: inventory1),
                        inventoryItem(quantityDelta: 10, product: product9, inventory: inventory1),
                        inventoryItem(quantityDelta: 1, product: product10, inventory: inventory1),
                        inventoryItem(quantityDelta: 7, product: product11, inventory: inventory1),
                        inventoryItem(quantityDelta: 4, product: product12, inventory: inventory1),
                        inventoryItem(quantityDelta: 1, product: product13, inventory: inventory1),
                        inventoryItem(quantityDelta: 6, product: product14, inventory: inventory1),
                        inventoryItem(quantityDelta: 4, product: product15, inventory: inventory1),
                        inventoryItem(quantityDelta: 2, product: product16, inventory: inventory1),
                        inventoryItem(quantityDelta: 1, product: product17, inventory: inventory1),
                        inventoryItem(quantityDelta: 3, product: product18, inventory: inventory1),
                        inventoryItem(quantityDelta: 1, product: product19, inventory: inventory1),
                        
                        inventoryItem(quantityDelta: 1, product: product8, inventory: inventory1),
                        inventoryItem(quantityDelta: 10, product: product9, inventory: inventory1),
                        inventoryItem(quantityDelta: 1, product: product10, inventory: inventory1),
                        inventoryItem(quantityDelta: 7, product: product11, inventory: inventory1),
                        inventoryItem(quantityDelta: 4, product: product12, inventory: inventory1),
                        inventoryItem(quantityDelta: 1, product: product13, inventory: inventory1),
                        inventoryItem(quantityDelta: 6, product: product14, inventory: inventory1),
                        inventoryItem(quantityDelta: 4, product: product15, inventory: inventory1),
                        inventoryItem(quantityDelta: 2, product: product16, inventory: inventory1),
                        inventoryItem(quantityDelta: 1, product: product17, inventory: inventory1),
                        inventoryItem(quantityDelta: 3, product: product18, inventory: inventory1),
                        inventoryItem(quantityDelta: 1, product: product19, inventory: inventory1),

                        inventoryItem(quantityDelta: 1, product: product8, inventory: inventory1),
                        inventoryItem(quantityDelta: 10, product: product9, inventory: inventory1),
                        inventoryItem(quantityDelta: 1, product: product10, inventory: inventory1),
                        inventoryItem(quantityDelta: 7, product: product11, inventory: inventory1),
                        inventoryItem(quantityDelta: 4, product: product12, inventory: inventory1),
                        inventoryItem(quantityDelta: 1, product: product13, inventory: inventory1),
                        inventoryItem(quantityDelta: 6, product: product14, inventory: inventory1),
                        inventoryItem(quantityDelta: 4, product: product15, inventory: inventory1),
                        inventoryItem(quantityDelta: 2, product: product16, inventory: inventory1),
                        inventoryItem(quantityDelta: 1, product: product17, inventory: inventory1),
                        inventoryItem(quantityDelta: 3, product: product18, inventory: inventory1),
                        inventoryItem(quantityDelta: 1, product: product19, inventory: inventory1),
                        
                        inventoryItem(quantityDelta: 1, product: product8, inventory: inventory1),
                        inventoryItem(quantityDelta: 10, product: product9, inventory: inventory1),
                        inventoryItem(quantityDelta: 1, product: product10, inventory: inventory1),
                        inventoryItem(quantityDelta: 7, product: product11, inventory: inventory1),
                        inventoryItem(quantityDelta: 4, product: product12, inventory: inventory1),
                        inventoryItem(quantityDelta: 1, product: product13, inventory: inventory1),
                        inventoryItem(quantityDelta: 6, product: product14, inventory: inventory1),
                        inventoryItem(quantityDelta: 4, product: product15, inventory: inventory1),
                        inventoryItem(quantityDelta: 2, product: product16, inventory: inventory1),
                        inventoryItem(quantityDelta: 1, product: product17, inventory: inventory1),
                        inventoryItem(quantityDelta: 3, product: product18, inventory: inventory1),
                        inventoryItem(quantityDelta: 1, product: product19, inventory: inventory1)
                    ]
                    
                    let user = SharedUser(email: "ivanschuetz@gmail.com") // Note this has to be the same as used in login
                    
                    let today = NSDate()
                    let calendar = NSCalendar.currentCalendar()
                    let components = NSDateComponents()
                    components.month = -2
                    let months2Ago = calendar.dateByAddingComponents(components, toDate: today, options: .WrapComponents)!
                    components.month = -4
                    let months4Ago = calendar.dateByAddingComponents(components, toDate: today, options: .WrapComponents)!
                    
                    
                    // TODO !! why items with date before today not stored in the database? why server has after sync 75 items and client db 60 (correct count)?
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
                        InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[11], historyItemUuid: "611", addedDate: NSDate(), user: user),
                        
                        InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[12], historyItemUuid: "612", addedDate: NSDate(), user: user),
                        InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[13], historyItemUuid: "613", addedDate: months4Ago, user: user),
                        InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[14], historyItemUuid: "614", addedDate: months2Ago, user: user),
                        InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[15], historyItemUuid: "615", addedDate: NSDate(), user: user),
                        InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[16], historyItemUuid: "616", addedDate: months2Ago, user: user),
                        InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[17], historyItemUuid: "617", addedDate: NSDate(), user: user),
                        InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[18], historyItemUuid: "618", addedDate: NSDate(), user: user),
                        InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[19], historyItemUuid: "619", addedDate: months4Ago, user: user),
                        InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[20], historyItemUuid: "620", addedDate: NSDate(), user: user),
                        InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[21], historyItemUuid: "621", addedDate: months2Ago, user: user),
                        InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[22], historyItemUuid: "622", addedDate: NSDate(), user: user),
                        InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[23], historyItemUuid: "623", addedDate: NSDate(), user: user),
                        
                        InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[24], historyItemUuid: "624", addedDate: NSDate(), user: user),
                        InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[25], historyItemUuid: "625", addedDate: months4Ago, user: user),
                        InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[26], historyItemUuid: "626", addedDate: months2Ago, user: user),
                        InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[27], historyItemUuid: "627", addedDate: NSDate(), user: user),
                        InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[28], historyItemUuid: "628", addedDate: months2Ago, user: user),
                        InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[29], historyItemUuid: "629", addedDate: NSDate(), user: user),
                        InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[30], historyItemUuid: "630", addedDate: NSDate(), user: user),
                        InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[31], historyItemUuid: "631", addedDate: months4Ago, user: user),
                        InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[32], historyItemUuid: "632", addedDate: NSDate(), user: user),
                        InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[33], historyItemUuid: "633", addedDate: months2Ago, user: user),
                        InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[34], historyItemUuid: "634", addedDate: NSDate(), user: user),
                        InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[35], historyItemUuid: "635", addedDate: NSDate(), user: user),
                        
                        InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[36], historyItemUuid: "636", addedDate: NSDate(), user: user),
                        InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[37], historyItemUuid: "637", addedDate: months4Ago, user: user),
                        InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[38], historyItemUuid: "638", addedDate: months2Ago, user: user),
                        InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[39], historyItemUuid: "639", addedDate: NSDate(), user: user),
                        InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[40], historyItemUuid: "640", addedDate: months2Ago, user: user),
                        InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[41], historyItemUuid: "641", addedDate: NSDate(), user: user),
                        InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[42], historyItemUuid: "642", addedDate: NSDate(), user: user),
                        InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[43], historyItemUuid: "643", addedDate: months4Ago, user: user),
                        InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[44], historyItemUuid: "644", addedDate: NSDate(), user: user),
                        InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[45], historyItemUuid: "645", addedDate: months2Ago, user: user),
                        InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[46], historyItemUuid: "646", addedDate: NSDate(), user: user),
                        InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[47], historyItemUuid: "647", addedDate: NSDate(), user: user),
                        
                        InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[48], historyItemUuid: "648", addedDate: NSDate(), user: user),
                        InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[49], historyItemUuid: "649", addedDate: months4Ago, user: user),
                        InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[50], historyItemUuid: "650", addedDate: months2Ago, user: user),
                        InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[51], historyItemUuid: "651", addedDate: NSDate(), user: user),
                        InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[52], historyItemUuid: "652", addedDate: months2Ago, user: user),
                        InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[53], historyItemUuid: "653", addedDate: NSDate(), user: user),
                        InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[54], historyItemUuid: "654", addedDate: NSDate(), user: user),
                        InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[55], historyItemUuid: "655", addedDate: months4Ago, user: user),
                        InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[56], historyItemUuid: "656", addedDate: NSDate(), user: user),
                        InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[57], historyItemUuid: "657", addedDate: months2Ago, user: user),
                        InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[58], historyItemUuid: "658", addedDate: NSDate(), user: user),
                        InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[59], historyItemUuid: "659", addedDate: NSDate(), user: user)
                    ]
                
                    weakSelf.inventoryProvider.add(inventoryWithHistoryItems) {saved in
                        print("Done adding dummy data")
                    }
                }
            }
        }
        
        // add more lists...
        //        let lists = [
        //            List(uuid: "2", name: "My first list", bgColor: RandomFlatColorWithShade(.Dark)),
        //            List(uuid: "3", name: "My first list", bgColor: RandomFlatColorWithShade(.Dark)),
        //            List(uuid: "4", name: "My first list", bgColor: RandomFlatColorWithShade(.Dark)),
        //            List(uuid: "5", name: "My first list", bgColor: RandomFlatColorWithShade(.Dark)),
        //            List(uuid: "6", name: "My first list", bgColor: RandomFlatColorWithShade(.Dark)),
        //            List(uuid: "7", name: "My first list", bgColor: RandomFlatColorWithShade(.Dark)),
        //            List(uuid: "8", name: "My first list", bgColor: RandomFlatColorWithShade(.Dark)),
        //            List(uuid: "9", name: "My first list", bgColor: RandomFlatColorWithShade(.Dark)),
        //            List(uuid: "10", name: "My first list", bgColor: RandomFlatColorWithShade(.Dark)),
        //            List(uuid: "11", name: "My first list", bgColor: RandomFlatColorWithShade(.Dark)),
        //            List(uuid: "12", name: "My first list", bgColor: RandomFlatColorWithShade(.Dark)),
        //            List(uuid: "13", name: "My first list", bgColor: RandomFlatColorWithShade(.Dark)),
        //            List(uuid: "14", name: "My first list", bgColor: RandomFlatColorWithShade(.Dark)),
        //            List(uuid: "15", name: "My first list", bgColor: RandomFlatColorWithShade(.Dark)),
        //            List(uuid: "16", name: "My first list", bgColor: RandomFlatColorWithShade(.Dark)),
        //            List(uuid: "17", name: "My first list", bgColor: RandomFlatColorWithShade(.Dark)),
        //            List(uuid: "18", name: "My first list", bgColor: RandomFlatColorWithShade(.Dark)),
        //            List(uuid: "19", name: "My first list", bgColor: RandomFlatColorWithShade(.Dark)),
        //            List(uuid: "20", name: "My first list", bgColor: RandomFlatColorWithShade(.Dark)),
        //            List(uuid: "21", name: "My first list", bgColor: RandomFlatColorWithShade(.Dark)),
        //            List(uuid: "22", name: "My first list", bgColor: RandomFlatColorWithShade(.Dark)),
        //            List(uuid: "23", name: "My first list", bgColor: RandomFlatColorWithShade(.Dark))
        //        ]
        //        listProvider.saveLists(lists, update: true) {[weak self] result in
        //        }
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
    
    
    // MARK: - Reachability
    
    private func initReachability() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"checkForReachability:", name: kReachabilityChangedNotification, object: nil)
        self.reachability = Reachability.reachabilityForInternetConnection()
        self.reachability.startNotifier()
    }
    
    func checkForReachability(notification: NSNotification) {
        
        let networkReachability = notification.object as! Reachability
        let remoteHostStatus = networkReachability.currentReachabilityStatus()

        if remoteHostStatus != .NotReachable { // wifi / wwan
            print("Device went online")
            
            if userProvider.loggedIn {
                print("User is logged in, start sync")
                window?.defaultProgressVisible(true)
                userProvider.sync {[weak self] in
                    print("Sync finished")
                    self?.window?.defaultProgressVisible(false)
                }
            }
        }
    }
}

