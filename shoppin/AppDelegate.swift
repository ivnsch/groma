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
import HockeySDK
import QorumLogs

@objc
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, RatingPopupDelegate {

    private let debugAddDummyData = false
    private let debugGeneratePrefillDatabases = false
    private let debugForceShowIntro = false
    
    var window: UIWindow?
    
    private var reachability: Reachability!
    
    private let userProvider = ProviderFactory().userProvider // arc
    private let listProvider = RealmListItemProvider() // arc   
    private let inventoryProvider = RealmInventoryProvider() // arc
    
    private var suggestionsPrefiller: SuggestionsPrefiller? // arc

    private var ratingPopup: RatingPopup? // arc
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

        initIsFirstLaunch()
        
        ifDebugLaunchActions()
        
        showController(firstController())

        initReachability()

        initGlobalAppearance()
        
        // Facebook sign-in
        let initFb = FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        
        initHockey()
        
        configLog()
        
        checkPing()
        
        checkRatePopup()
        
        initWebsocket()
        
        return initFb
    }
    
    private func checkRatePopup() {
        if let controller = window?.rootViewController {
            ratingPopup = RatingPopup()
            ratingPopup?.delegate = self
            ratingPopup?.checkShow(controller)
        } else {
            QL4("Couldn't show rating popup, either window: \(window) or root controller: \(window?.rootViewController) is nil)")
        }
    }
    
    private func configLog() {
        QorumLogs.enabled = true
        QorumLogs.minimumLogLevelShown = 1
        QorumOnlineLogs.minimumLogLevelShown = 4
     
        QorumLogs.KZLinkedConsoleSupportEnabled = true

//        QorumLogs.onlyShowTheseFiles(MyWebSocket.self, MyWebsocketDispatcher.self)

//        QorumLogs.test()
    }
    
    private func initWebsocket() {
        Providers.userProvider.connectWebsocketIfLoggedIn()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsocketList:", name: WSNotificationName.List.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsocketInventory:", name: WSNotificationName.Inventory.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsocketSharedSync:", name: WSNotificationName.SyncShared.rawValue, object: nil)
    }
    
    private func initHockey() {
        BITHockeyManager.sharedHockeyManager().configureWithIdentifier("589348069297465892087104a6337407")
        // Do some additional configuration if needed here
        BITHockeyManager.sharedHockeyManager().startManager()
        BITHockeyManager.sharedHockeyManager().authenticator.authenticateInstallation()
    }
    
    private func showController(controller: UIViewController) {
        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        self.window?.rootViewController = controller
        self.window?.makeKeyAndVisible()
    }
    
    private func firstController() -> UIViewController {
        // The intro is shown (even if user stops the app and comes back) until it's completed (log in / register success or skip)
        if (isDebug() && debugForceShowIntro) || PreferencesManager.loadPreference(PreferencesManagerKey.showIntro) ?? true {
            return UIStoryboard.introNavController()
        } else {
            return UIStoryboard.mainTabController()
        }
    }
    
    private func initIsFirstLaunch() {
        if !(PreferencesManager.loadPreference(PreferencesManagerKey.hasLaunchedBefore) ?? false) { // first launch
            QL2("Initialising first app launch preferences")
            PreferencesManager.savePreference(PreferencesManagerKey.hasLaunchedBefore, value: true)
            PreferencesManager.savePreference(PreferencesManagerKey.isFirstLaunch, value: true)
            PreferencesManager.savePreference(PreferencesManagerKey.firstLaunchDate, value: NSDate())
        } else { // after first launch
            PreferencesManager.savePreference(PreferencesManagerKey.isFirstLaunch, value: false)
        }
    }
    
    private func initGlobalAppearance() {
        UITabBarItem.appearance().setTitleTextAttributes([NSFontAttributeName: Fonts.superSmallLight], forState: .Normal)
        UINavigationBar.appearance().titleTextAttributes = [NSFontAttributeName: Fonts.regular, NSForegroundColorAttributeName: Theme.navigationBarTextColor]
        UIBarButtonItem.appearance().setTitleTextAttributes([NSFontAttributeName: Fonts.regular, NSForegroundColorAttributeName: Theme.navigationBarTextColor], forState: .Normal)
        UISegmentedControl.appearance().setTitleTextAttributes([NSFontAttributeName: Fonts.verySmallLight], forState: .Normal)
        
        UITabBar.appearance().tintColor = Theme.tabBarSelectedColor
//        UITabBar.appearance().barTintColor = Theme.tabBarBackgroundColor
//        UITabBar.appearance().translucent = false

//        UINavigationBar.appearance().barTintColor = Theme.navigationBarBackgroundColor
        UINavigationBar.appearance().tintColor = Theme.navigationBarTextColor
//        UINavigationBar.appearance().translucent = false
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

    // MARK: - Debug
    
    private func isDebug() -> Bool {
        #if DEBUG
            return true
            #else
            return false
        #endif
    }
    
    // Actions executed if app is in debug mode
    private func ifDebugLaunchActions() {
        #if DEBUG
            if debugGeneratePrefillDatabases {
                generatePrefillDatabase()
            }
            if debugAddDummyData || !(PreferencesManager.loadPreference(PreferencesManagerKey.hasLaunchedBefore) ?? false) { // first launch
                addDummyData()
//                addDummyDataMini()
            }
            #else
        #endif
    }
    
    /**
    * Create database which we embed in the app in order to prefill the app's database
    * TODO try to use test for this (PrefillDatabase - not working because sth with Realm). This should not be in of the app.
    */
    private func generatePrefillDatabase() {
        print("Creating prefilled databases")
        self.suggestionsPrefiller = SuggestionsPrefiller()
        self.suggestionsPrefiller?.prefill {
            print("Finished creating prefilled databases")
        }
    }

    // A minimal dummy data setup with 1 inventory, 1 list and 1 list item (with corresponding product and category)
    private func addDummyDataMini() {
        
        var uuid: String {
            return NSUUID().UUIDString
        }
        let fruitsCat = ProductCategory(uuid: uuid, name: "Obst", color: UIColor.flatRedColor())
        let product1 = Product(uuid: uuid, name: "Birnen", price: 3, category: fruitsCat, baseQuantity: 1, unit: .None, brand: "")

        let inventory1 = Inventory(uuid: uuid, name: "My Home inventory", bgColor: UIColor.flatGreenColor(), order: 0)
        inventoryProvider.saveInventory(inventory1) {[weak self] saved in
        
            let list1 = List(uuid: uuid, name: "My first list", bgColor: RandomFlatColorWithShade(.Dark), order: 0, inventory: inventory1)
            self?.listProvider.saveList(list1) {[weak self] result in
                
                guard let weakSelf = self else {return}
                
                let section1 = Section(uuid: uuid, name: "Obst", list: list1, order: ListItemStatusOrder(status: .Todo, order: 0))
                let listItems = [
                    ListItem(uuid: uuid, product: product1, section: section1, list: list1, todoQuantity: 5, todoOrder: 0)
                ]
                
                weakSelf.listProvider.saveListItems(listItems, incrementQuantity: false) {saved in
                    print("Done adding dummy data (mini)")
                }
            }
        }
    }
    
    private func addDummyData() {
        
        var uuid: String {
            return NSUUID().UUIDString
        }
        
        let fruitsCat = ProductCategory(uuid: uuid, name: "Obst", color: UIColor.flatRedColor())
        let vegetablesCat = ProductCategory(uuid: uuid, name: "Gemuese", color: UIColor.flatGreenColor())
        let milkCat = ProductCategory(uuid: uuid, name: "Milchprodukte", color: UIColor.flatYellowColor())
        let meatCat = ProductCategory(uuid: uuid, name: "Fleisch", color: UIColor.flatRedColorDark())
        let fishCat = ProductCategory(uuid: uuid, name: "Fisch", color: UIColor.flatBlueColorDark())
        let pastaCat = ProductCategory(uuid: uuid, name: "Pasta", color: UIColor.flatWhiteColorDark())
        let drinksCat = ProductCategory(uuid: uuid, name: "Getraenke", color: UIColor.flatBlueColor().lightenByPercentage(0.5))
        let cleaningCat = ProductCategory(uuid: uuid, name: "Putzmittel", color: UIColor.flatMagentaColor())
        let hygienicCat = ProductCategory(uuid: uuid, name: "Hygiene", color: UIColor.flatGrayColor())
        let spicesCat = ProductCategory(uuid: uuid, name: "Gewürze", color: UIColor.flatBrownColor())
        let breadCat = ProductCategory(uuid: uuid, name: "Brot", color: UIColor.flatYellowColorDark())
        
        let product1 = Product(uuid: uuid, name: "Birnen", price: 3, category: fruitsCat, baseQuantity: 1, unit: .None, brand: "")
        let product2 = Product(uuid: uuid, name: "Tomaten", price: 2, category: vegetablesCat, baseQuantity: 1, unit: .None, brand: "")
        let product3 = Product(uuid: uuid, name: "Schwarzer Tee", price: 2, category: drinksCat, baseQuantity: 1, unit: .None, brand: "")
        let product4 = Product(uuid: uuid, name: "Haenchen", price: 5, category: meatCat, baseQuantity: 1, unit: .None, brand: "")
        let product5 = Product(uuid: uuid, name: "Spaguetti", price: 0.8, category: pastaCat, baseQuantity: 1, unit: .None, brand: "")
        let product6 = Product(uuid: uuid, name: "Sahne", price: 1, category: milkCat, baseQuantity: 1, unit: .None, brand: "")
        let product7 = Product(uuid: uuid, name: "Pfefferminz Tee", price: 1, category: drinksCat, baseQuantity: 1, unit: .None, brand: "")
        
        let product8 = Product(uuid: uuid, name: "Kartoffeln", price: 1.2, category: vegetablesCat, baseQuantity: 1, unit: .None, brand: "")
        let product9 = Product(uuid: uuid, name: "Thunfisch", price: 0.9, category: fishCat, baseQuantity: 1, unit: .None, brand: "")
        let product10 = Product(uuid: uuid, name: "Zitronen", price: 1.3, category: fruitsCat, baseQuantity: 1, unit: .None, brand: "")
        let product11 = Product(uuid: uuid, name: "Kidney bohnen", price: 1, category: vegetablesCat, baseQuantity: 1, unit: .None, brand: "")
        let product12 = Product(uuid: uuid, name: "Klopapier", price: 3.4, category: cleaningCat, baseQuantity: 1, unit: .None, brand: "")
        let product13 = Product(uuid: uuid, name: "Putzmittel boden", price: 5.1, category: hygienicCat, baseQuantity: 1, unit: .None, brand: "")
        let product14 = Product(uuid: uuid, name: "Bier", price: 0.8, category: drinksCat, baseQuantity: 1, unit: .None, brand: "")
        let product15 = Product(uuid: uuid, name: "Cola (1L)", price: 1.2, category: drinksCat, baseQuantity: 1, unit: .None, brand: "")
        let product16 = Product(uuid: uuid, name: "Salz", price: 0.7, category: spicesCat, baseQuantity: 1, unit: .None, brand: "")
        let product17 = Product(uuid: uuid, name: "Zucker", price: 0.9, category: spicesCat, baseQuantity: 1, unit: .None, brand: "")
        let product18 = Product(uuid: uuid, name: "Seife", price: 0.8, category: hygienicCat, baseQuantity: 1, unit: .None, brand: "")
        let product19 = Product(uuid: uuid, name: "Toastbrot", price: 0.7, category: breadCat, baseQuantity: 1, unit: .None, brand: "")
        
        
        let inventory1 = Inventory(uuid: uuid, name: "My Home inventory", bgColor: UIColor.flatGreenColor(), order: 0)
        inventoryProvider.saveInventory(inventory1) {[weak self] saved in
            
            func inventoryItem(quantityDelta quantityDelta: Int, product: Product, inventory: Inventory) -> InventoryItem {
                return InventoryItem(uuid: uuid, quantity: quantityDelta, quantityDelta: quantityDelta, product: product, inventory: inventory)
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
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[0], historyItemUuid: uuid, addedDate: NSDate(), user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[1], historyItemUuid: uuid, addedDate: months4Ago, user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[2], historyItemUuid: uuid, addedDate: months2Ago, user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[3], historyItemUuid: uuid, addedDate: NSDate(), user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[4], historyItemUuid: uuid, addedDate: months2Ago, user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[5], historyItemUuid: uuid, addedDate: NSDate(), user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[6], historyItemUuid: uuid, addedDate: NSDate(), user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[7], historyItemUuid: uuid, addedDate: months4Ago, user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[8], historyItemUuid: uuid, addedDate: NSDate(), user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[9], historyItemUuid: uuid, addedDate: months2Ago, user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[10], historyItemUuid: uuid, addedDate: NSDate(), user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[11], historyItemUuid: uuid, addedDate: NSDate(), user: user),
                
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[12], historyItemUuid: uuid, addedDate: NSDate(), user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[13], historyItemUuid: uuid, addedDate: months4Ago, user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[14], historyItemUuid: uuid, addedDate: months2Ago, user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[15], historyItemUuid: uuid, addedDate: NSDate(), user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[16], historyItemUuid: uuid, addedDate: months2Ago, user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[17], historyItemUuid: uuid, addedDate: NSDate(), user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[18], historyItemUuid: uuid, addedDate: NSDate(), user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[19], historyItemUuid: uuid, addedDate: months4Ago, user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[20], historyItemUuid: uuid, addedDate: NSDate(), user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[21], historyItemUuid: uuid, addedDate: months2Ago, user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[22], historyItemUuid: uuid, addedDate: NSDate(), user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[23], historyItemUuid: uuid, addedDate: NSDate(), user: user),
                
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[24], historyItemUuid: uuid, addedDate: NSDate(), user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[25], historyItemUuid: uuid, addedDate: months4Ago, user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[26], historyItemUuid: uuid, addedDate: months2Ago, user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[27], historyItemUuid: uuid, addedDate: NSDate(), user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[28], historyItemUuid: uuid, addedDate: months2Ago, user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[29], historyItemUuid: uuid, addedDate: NSDate(), user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[30], historyItemUuid: uuid, addedDate: NSDate(), user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[31], historyItemUuid: uuid, addedDate: months4Ago, user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[32], historyItemUuid: uuid, addedDate: NSDate(), user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[33], historyItemUuid: uuid, addedDate: months2Ago, user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[34], historyItemUuid: uuid, addedDate: NSDate(), user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[35], historyItemUuid: uuid, addedDate: NSDate(), user: user),
                
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[36], historyItemUuid: uuid, addedDate: NSDate(), user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[37], historyItemUuid: uuid, addedDate: months4Ago, user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[38], historyItemUuid: uuid, addedDate: months2Ago, user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[39], historyItemUuid: uuid, addedDate: NSDate(), user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[40], historyItemUuid: uuid, addedDate: months2Ago, user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[41], historyItemUuid: uuid, addedDate: NSDate(), user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[42], historyItemUuid: uuid, addedDate: NSDate(), user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[43], historyItemUuid: uuid, addedDate: months4Ago, user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[44], historyItemUuid: uuid, addedDate: NSDate(), user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[45], historyItemUuid: uuid, addedDate: months2Ago, user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[46], historyItemUuid: uuid, addedDate: NSDate(), user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[47], historyItemUuid: uuid, addedDate: NSDate(), user: user),
                
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[48], historyItemUuid: uuid, addedDate: NSDate(), user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[49], historyItemUuid: uuid, addedDate: months4Ago, user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[50], historyItemUuid: uuid, addedDate: months2Ago, user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[51], historyItemUuid: uuid, addedDate: NSDate(), user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[52], historyItemUuid: uuid, addedDate: months2Ago, user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[53], historyItemUuid: uuid, addedDate: NSDate(), user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[54], historyItemUuid: uuid, addedDate: NSDate(), user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[55], historyItemUuid: uuid, addedDate: months4Ago, user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[56], historyItemUuid: uuid, addedDate: NSDate(), user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[57], historyItemUuid: uuid, addedDate: months2Ago, user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[58], historyItemUuid: uuid, addedDate: NSDate(), user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[59], historyItemUuid: uuid, addedDate: NSDate(), user: user)
            ]
            
            
            // add more items
//            let moreItems: [InventoryItemWithHistoryEntry] = (0...10000).map{i in
//                let category = ProductCategory(uuid: "111\(i)", name: "111\(i)", color: UIColor.blackColor())
//                let product = Product(uuid: "111\(i)", name: "111\(i)", price: 123, category: category, baseQuantity: 1, unit: .None)
//                let inventoryItem = inventoryItem(quantityDelta: 7, product: product, inventory: inventory1)
//                return InventoryItemWithHistoryEntry(inventoryItem: inventoryItem, historyItemUuid: "111\(i)", addedDate: NSDate(), user: user)
//            }
            
            self?.inventoryProvider.add(inventoryWithHistoryItems/* + moreItems*/) {saved in
                
                let list1 = List(uuid: uuid, name: "My first list", bgColor: RandomFlatColorWithShade(.Dark), order: 0, inventory: inventory1)
                self?.listProvider.saveList(list1) {[weak self] result in
                    
                    guard let weakSelf = self else {return}
                    
                    let section1 = Section(uuid: uuid, name: "Obst", list: list1, order: ListItemStatusOrder(status: .Todo, order: 0))
                    let section2 = Section(uuid: uuid, name: "Gemuese", list: list1, order: ListItemStatusOrder(status: .Todo, order: 1))
                    let section3 = Section(uuid: uuid, name: "Milchprodukte", list: list1, order: ListItemStatusOrder(status: .Todo, order: 2))
                    let section4 = Section(uuid: uuid, name: "Fleisch", list: list1, order: ListItemStatusOrder(status: .Todo, order: 3))
                    let section5 = Section(uuid: uuid, name: "Pasta", list: list1, order: ListItemStatusOrder(status: .Todo, order: 4))
                    let section6 = Section(uuid: uuid, name: "Getraenke", list: list1, order: ListItemStatusOrder(status: .Todo, order: 5))
//                    let cleaning = Section(uuid: uuid, name: "Putzmittel", order: 6)
//                    let hygienic = Section(uuid: uuid, name: "Hygiene", order: 7)
//                    let spices = Section(uuid: uuid, name: "Gewürze", order: 8)
//                    let bread = Section(uuid: uuid, name: "Brot", order: 8)
                    
                    let listItems = [
                        ListItem(uuid: uuid, product: product1, section: section1, list: list1, todoQuantity: 5, todoOrder: 0),
                        ListItem(uuid: uuid, product: product2, section: section2, list: list1, todoQuantity: 2, todoOrder: 0),
                        ListItem(uuid: uuid, product: product3, section: section6, list: list1, todoQuantity: 3, todoOrder: 1),
                        ListItem(uuid: uuid, product: product4, section: section4, list: list1, todoQuantity: 3, todoOrder: 2),
                        ListItem(uuid: uuid, product: product5, section: section5, list: list1, todoQuantity: 4, todoOrder: 3),
                        ListItem(uuid: uuid, product: product6, section: section3, list: list1, todoQuantity: 3, todoOrder: 4),
                        ListItem(uuid: uuid, product: product7, section: section6, list: list1, todoQuantity: 4, todoOrder: 5)
                    ]
                    
                    weakSelf.listProvider.saveListItems(listItems, incrementQuantity: false) {saved in
                        print("Done adding dummy data")
                    }
                }
                
                // add more lists...
                //        let lists = [
                //            List(uuid: uuid, name: "My first list", bgColor: RandomFlatColorWithShade(.Dark)),
                //            List(uuid: uuid, name: "My first list", bgColor: RandomFlatColorWithShade(.Dark)),
                //            List(uuid: uuid, name: "My first list", bgColor: RandomFlatColorWithShade(.Dark)),
                //            List(uuid: uuid, name: "My first list", bgColor: RandomFlatColorWithShade(.Dark)),
                //            List(uuid: uuid, name: "My first list", bgColor: RandomFlatColorWithShade(.Dark)),
                //            List(uuid: uuid, name: "My first list", bgColor: RandomFlatColorWithShade(.Dark)),
                //            List(uuid: uuid, name: "My first list", bgColor: RandomFlatColorWithShade(.Dark)),
                //            List(uuid: uuid, name: "My first list", bgColor: RandomFlatColorWithShade(.Dark)),
                //            List(uuid: uuid, name: "My first list", bgColor: RandomFlatColorWithShade(.Dark)),
                //            List(uuid: uuid, name: "My first list", bgColor: RandomFlatColorWithShade(.Dark)),
                //            List(uuid: uuid, name: "My first list", bgColor: RandomFlatColorWithShade(.Dark)),
                //            List(uuid: uuid, name: "My first list", bgColor: RandomFlatColorWithShade(.Dark)),
                //            List(uuid: uuid, name: "My first list", bgColor: RandomFlatColorWithShade(.Dark)),
                //            List(uuid: uuid, name: "My first list", bgColor: RandomFlatColorWithShade(.Dark)),
                //            List(uuid: uuid, name: "My first list", bgColor: RandomFlatColorWithShade(.Dark)),
                //            List(uuid: uuid, name: "My first list", bgColor: RandomFlatColorWithShade(.Dark)),
                //            List(uuid: uuid, name: "My first list", bgColor: RandomFlatColorWithShade(.Dark)),
                //            List(uuid: uuid, name: "My first list", bgColor: RandomFlatColorWithShade(.Dark)),
                //            List(uuid: uuid, name: "My first list", bgColor: RandomFlatColorWithShade(.Dark)),
                //            List(uuid: uuid, name: "My first list", bgColor: RandomFlatColorWithShade(.Dark)),
                //            List(uuid: uuid, name: "My first list", bgColor: RandomFlatColorWithShade(.Dark)),
                //            List(uuid: uuid, name: "My first list", bgColor: RandomFlatColorWithShade(.Dark))
                //        ]
                //        listProvider.saveLists(lists, update: true) {[weak self] result in
                //        }

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
        checkPing()
    }

    private func checkPing() {
        if let lastTokeUpdateDate: NSDate = PreferencesManager.loadPreference(PreferencesManagerKey.lastTokenUpdate) {
            
            // Refresh the token, max 1 time in <days>
            // If we find a method to guarantee (background service?) that we refresh the token each x days, we can set this to a bigger value. Consult server for more details.
            let days = 1
            let passedDays = lastTokeUpdateDate.daysUntil(NSDate())
            if passedDays >= days {
                QL2("\(passedDays) days passed since last token refresh. Ping")
                userProvider.ping()
            } else {
                QL1("There is a token last update date, but \(days) days not passed yet. Passed days: \(passedDays)")
            }
        } else {
            QL1("No token last update date stored yet")
        }
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.

    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        Providers.userProvider.disconnectWebsocket()
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
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

        QL1("Changed connectivity status: \(remoteHostStatus.rawValue)")

        if remoteHostStatus != .NotReachable { // wifi / wwan
            QL2("Connected")
            
            if userProvider.hasLoginToken {
                QL2("User has login token, start sync")
                window?.defaultProgressVisible(true)
                Providers.globalProvider.sync {[weak self] result in
                    QL2("Sync finished")
                    if !result.success {
                        QL4("Error: AppDelegate.checkForReachability: Sync didn't succeed: \(result)")
                    }

                    if let syncResult = result.sucessResult {
                        if let controller = self?.window?.rootViewController {
                            InvitationsHandler.handleInvitations(syncResult.listInvites, inventoryInvitations: syncResult.inventoryInvites, controller: controller)
                        } else {
                            QL4("Couldn't show popup, either window: \(self?.window) or root controller: \(self?.window?.rootViewController) is nil)")
                        }
                    } else {
                        QL4("Invalid state: result doesn't have sync result")
                    }

                    self?.window?.defaultProgressVisible(false)
                }
            }
        }
    }
    
    // MARK: - RatingPopupDelegate
    
    func onDismissRatingPopup() {
        ratingPopup = nil
    }
    
    // MARK: - Websocket
    
    func onWebsocketList(note: NSNotification) {
        
        if let info = note.userInfo as? Dictionary<String, WSNotification<RemoteListInvitation>> {
            if let notification = info[WSNotificationValue] {
                let invitation = notification.obj
                switch notification.verb {
                case .Invite:
                    if let controller = window?.rootViewController {
                        ListInvitationsHandler.handleInvitation(invitation, controller: controller)
                    } else {
                        QL4("Couldn't show popup, either window: \(window) or root controller: \(window?.rootViewController) is nil)")
                    }
                default: QL4("Not handled case: \(notification.verb))")
                }
            } else {
                QL4("No value")
            }
            
        }
    }
    
    func onWebsocketInventory(note: NSNotification) {
        
        if let info = note.userInfo as? Dictionary<String, WSNotification<RemoteInventoryInvitation>> {
            if let notification = info[WSNotificationValue] {
                let invitation = notification.obj
                switch notification.verb {
                case .Invite:
                    if let controller = window?.rootViewController {
                        InventoryInvitationsHandler.handleInvitation(invitation, controller: controller)
                    } else {
                        QL4("Couldn't show popup, either window: \(window) or root controller: \(window?.rootViewController) is nil)")
                    }
                default: QL4("Not handled case: \(notification.verb))")
                }
            } else {
                QL4("No value")
            }
            
        }
    }
    
    // Process this here in AppDelegate because it's global and we have a controller, which we need to show possible invitations and maybe a progress indicator
    func onWebsocketSharedSync(note: NSNotification) {
        
        if let info = note.userInfo as? Dictionary<String, WSNotification<String>> {
            if let notification = info[WSNotificationValue] {
                let sender = notification.obj
                switch notification.verb {
                case .Sync:
                    if let controller = window?.rootViewController {
                        controller.progressVisible()
                        QL2("Shared items sync request by \(sender)")
                        // text to user "Incoming sync request from x" or "Processing sync request from x" or "Sync request triggered by x" or "Sync request by x" or "x Sync request"
                        
                        Providers.globalProvider.sync(controller.successHandler{invitations in
                            QL3("Are we really expecting invitations here? (not sure if this should be a warning): \(invitations)")
                            InvitationsHandler.handleInvitations(invitations.listInvites, inventoryInvitations: invitations.inventoryInvites, controller: controller)
                            
                            // Broadcast such that controllers can e.g. reload items.
                            NSNotificationCenter.defaultCenter().postNotificationName(WSNotificationName.IncomingGlobalSyncFinished.rawValue, object: nil, userInfo: info)
                        })
                        
                    } else {
                        QL4("Couldn't show popup, either window: \(window) or root controller: \(window?.rootViewController) is nil)")
                    }
                default: QL4("Not handled case: \(notification.verb))")
                }
            } else {
                QL4("No value")
            }
            
        }
    }
}

