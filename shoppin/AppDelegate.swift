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
import RealmSwift

@objc
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, RatingAlertDelegate {

    private let debugAddDummyData = false
    private let debugGeneratePrefillDatabases = false
    private let debugForceShowIntro = false
    
    var window: UIWindow?
    
    private var reachability: Reachability!
    
    private let userProvider = ProviderFactory().userProvider // arc

    private var suggestionsPrefiller: SuggestionsPrefiller? // arc

    private var ratingAlert: RatingAlert? // arc
    
    private let websocketVisualNotificationDuration: Double = 2
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

        configLog()
        
        initIsFirstLaunch()
        
        ifDebugLaunchActions()
        
        showController(firstController())

        initReachability()

        initGlobalAppearance()
        
        // Facebook sign-in
        let initFb = FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        
        initHockey()
        
        checkPing()
        
        checkRatePopup()
        
        initWebsocket()

        checkMigrateRealm()
        
        Notification.subscribe(.LoginTokenExpired, selector: "onLoginTokenExpired:", observer: self)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsocketConnectionChange:", name: WSNotificationName.Connection.rawValue, object: nil)

        return initFb
    }

    private func checkMigrateRealm() {
        let config = Realm.Configuration(
            // Set the new schema version. This must be greater than the previously used
            // version (if you've never set a schema version before, the version is 0).
            schemaVersion: 0,
            
            // Set the block which will be called automatically when opening a Realm with
            // a schema version lower than the one set above
            migrationBlock: { migration, oldSchemaVersion in
                // We haven’t migrated anything yet, so oldSchemaVersion == 0
                if (oldSchemaVersion < 1) {
                    // Nothing to do!
                    // Realm will automatically detect new properties and removed properties
                    // And will update the schema on disk automatically
                }
        })
        
        // Tell Realm to use this new configuration object for the default Realm
        Realm.Configuration.defaultConfiguration = config
        
        // Now that we've told Realm how to handle the schema change, opening the file
        // will automatically perform the migration
//        let realm = try! Realm()
    }
    
    private func checkRatePopup() {
        if let controller = window?.rootViewController {
            ratingAlert = RatingAlert()
            ratingAlert?.delegate = self
            ratingAlert?.checkShow(controller)
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
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsocketReceptionNotification:", name: WSNotificationName.Reception.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsocketProcessingError:", name: WSNotificationName.ProcessingError.rawValue, object: nil)
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
            
            // Ensure there's no login token from a previous app installation (token is stored in the keychain, which is not deleted when the app is uninstalled).
            AccessTokenHelper.removeToken()

        } else { // after first launch
            QL1("Not first launch")
            PreferencesManager.savePreference(PreferencesManagerKey.isFirstLaunch, value: false)
        }
    }
    
    private func initGlobalAppearance() {
        UITabBarItem.appearance().setTitleTextAttributes([NSFontAttributeName: Fonts.superSmallLight, NSForegroundColorAttributeName: Theme.navigationBarTextColor], forState: .Normal)
        UINavigationBar.appearance().titleTextAttributes = [NSFontAttributeName: Fonts.regular, NSForegroundColorAttributeName: Theme.tabBarTextColor]
        UIBarButtonItem.appearance().setTitleTextAttributes([NSFontAttributeName: Fonts.regular, NSForegroundColorAttributeName: Theme.navigationBarTextColor], forState: .Normal)
        UISegmentedControl.appearance().setTitleTextAttributes([NSFontAttributeName: Fonts.verySmallLight], forState: .Normal)
        
        UITabBar.appearance().tintColor = Theme.tabBarSelectedColor
        UITabBar.appearance().barTintColor = Theme.tabBarBackgroundColor
        UITabBar.appearance().translucent = false

        UINavigationBar.appearance().shadowImage = UIImage()
        UINavigationBar.appearance().setBackgroundImage(UIImage(), forBarMetrics: .Default)
        UINavigationBar.appearance().barTintColor = Theme.navigationBarBackgroundColor
        UINavigationBar.appearance().tintColor = Theme.navigationBarTextColor
        UINavigationBar.appearance().translucent = false
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
//                addDummyData()
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
        let product1 = Product(uuid: uuid, name: "Birnen", category: fruitsCat, brand: "")

        let inventory1 = Inventory(uuid: uuid, name: "My Home inventory", bgColor: UIColor.flatGreenColor(), order: 0)
        DBProviders.inventoryProvider.saveInventory(inventory1, dirty: true) {saved in
        
            let list1 = List(uuid: uuid, name: "My first list", bgColor: RandomFlatColorWithShade(.Dark), order: 0, inventory: inventory1, store: nil)
            DBProviders.listProvider.saveList(list1) {result in
                
                let section1 = Section(uuid: uuid, name: "Obst", color: UIColor.flatRedColor(), list: list1, order: ListItemStatusOrder(status: .Todo, order: 0))
                let storeProduct1 = StoreProduct(uuid: uuid, price: 1, baseQuantity: 1, unit: .None, store: "my store", product: product1)
                let listItems = [
                    ListItem(uuid: uuid, product: storeProduct1, section: section1, list: list1, todoQuantity: 5, todoOrder: 0)
                ]
                
                DBProviders.listItemProvider.saveListItems(listItems, incrementQuantity: false) {saved in
                    QL1("Done adding dummy data (mini)")
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
        
        let product1 = Product(uuid: uuid, name: "Birnen", category: fruitsCat, brand: "")
        let product2 = Product(uuid: uuid, name: "Tomaten", category: vegetablesCat, brand: "")
        let product3 = Product(uuid: uuid, name: "Schwarzer Tee", category: drinksCat, brand: "")
        let product4 = Product(uuid: uuid, name: "Haenchen", category: meatCat, brand: "")
        let product5 = Product(uuid: uuid, name: "Spaguetti", category: pastaCat, brand: "")
        let product6 = Product(uuid: uuid, name: "Sahne", category: milkCat, brand: "")
        let product7 = Product(uuid: uuid, name: "Pfefferminz Tee", category: drinksCat, brand: "")
        
        let product8 = Product(uuid: uuid, name: "Kartoffeln", category: vegetablesCat, brand: "")
        let product9 = Product(uuid: uuid, name: "Thunfisch", category: fishCat, brand: "")
        let product10 = Product(uuid: uuid, name: "Zitronen", category: fruitsCat, brand: "")
        let product11 = Product(uuid: uuid, name: "Kidney bohnen", category: vegetablesCat, brand: "")
        let product12 = Product(uuid: uuid, name: "Klopapier", category: cleaningCat, brand: "")
        let product13 = Product(uuid: uuid, name: "Putzmittel boden", category: hygienicCat, brand: "")
        let product14 = Product(uuid: uuid, name: "Bier", category: drinksCat, brand: "")
        let product15 = Product(uuid: uuid, name: "Cola (1L)", category: drinksCat, brand: "")
        let product16 = Product(uuid: uuid, name: "Salz", category: spicesCat, brand: "")
        let product17 = Product(uuid: uuid, name: "Zucker", category: spicesCat, brand: "")
        let product18 = Product(uuid: uuid, name: "Seife", category: hygienicCat, brand: "")
        let product19 = Product(uuid: uuid, name: "Toastbrot", category: breadCat, brand: "")
        
        let storeProduct1 = StoreProduct(uuid: uuid, price: 3, baseQuantity: 1, unit: .None, store: "", product: product1)
        let storeProduct2 = StoreProduct(uuid: uuid, price: 2, baseQuantity: 1, unit: .None, store: "", product: product2)
        let storeProduct3 = StoreProduct(uuid: uuid, price: 2, baseQuantity: 1, unit: .None, store: "", product: product3)
        let storeProduct4 = StoreProduct(uuid: uuid, price: 5, baseQuantity: 1, unit: .None, store: "", product: product4)
        let storeProduct5 = StoreProduct(uuid: uuid, price: 0.8, baseQuantity: 1, unit: .None, store: "", product: product5)
        let storeProduct6 = StoreProduct(uuid: uuid, price: 1, baseQuantity: 1, unit: .None, store: "", product: product6)
        let storeProduct7 = StoreProduct(uuid: uuid, price: 1, baseQuantity: 1, unit: .None, store: "", product: product7)
        
        let storeProduct8 = StoreProduct(uuid: uuid, price: 1.2, baseQuantity: 1, unit: .None, store: "", product: product8)
        let storeProduct9 = StoreProduct(uuid: uuid, price: 0.9, baseQuantity: 1, unit: .None, store: "", product: product9)
        let storeProduct10 = StoreProduct(uuid: uuid, price: 1.3, baseQuantity: 1, unit: .None, store: "", product: product10)
        let storeProduct11 = StoreProduct(uuid: uuid, price: 1, baseQuantity: 1, unit: .None, store: "", product: product11)
        let storeProduct12 = StoreProduct(uuid: uuid, price: 3.4, baseQuantity: 1, unit: .None, store: "", product: product12)
        let storeProduct13 = StoreProduct(uuid: uuid, price: 5.1, baseQuantity: 1, unit: .None, store: "", product: product13)
        let storeProduct14 = StoreProduct(uuid: uuid, price: 0.8, baseQuantity: 1, unit: .None, store: "", product: product14)
        let storeProduct15 = StoreProduct(uuid: uuid, price: 1.2, baseQuantity: 1, unit: .None, store: "", product: product15)
        let storeProduct16 = StoreProduct(uuid: uuid, price: 0.7, baseQuantity: 1, unit: .None, store: "", product: product16)
        let storeProduct17 = StoreProduct(uuid: uuid, price: 0.9, baseQuantity: 1, unit: .None, store: "", product: product17)
        let storeProduct18 = StoreProduct(uuid: uuid, price: 0.8, baseQuantity: 1, unit: .None, store: "", product: product18)
        let storeProduct19 = StoreProduct(uuid: uuid, price: 0.7, baseQuantity: 1, unit: .None, store: "", product: product19)
        
        let inventory1 = Inventory(uuid: uuid, name: "My Home inventory", bgColor: UIColor.flatGreenColor(), order: 0)
        DBProviders.inventoryProvider.saveInventory(inventory1, dirty: true) {[weak self] saved in
            
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
            let months2Ago = calendar.dateByAddingComponents(components, toDate: today, options: .WrapComponents)!.toMillis()
            components.month = -4
            let months4Ago = calendar.dateByAddingComponents(components, toDate: today, options: .WrapComponents)!.toMillis()
            
            
            // TODO !! why items with date before today not stored in the database? why server has after sync 75 items and client db 60 (correct count)?
            let inventoryWithHistoryItems = [
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[0], storeProduct: storeProduct8, historyItemUuid: uuid, addedDate: NSDate().toMillis(), user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[1], storeProduct: storeProduct9, historyItemUuid: uuid, addedDate: months4Ago, user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[2], storeProduct: storeProduct10, historyItemUuid: uuid, addedDate: months2Ago, user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[3], storeProduct: storeProduct11, historyItemUuid: uuid, addedDate: NSDate().toMillis(), user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[4], storeProduct: storeProduct12, historyItemUuid: uuid, addedDate: months2Ago, user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[5], storeProduct: storeProduct13, historyItemUuid: uuid, addedDate: NSDate().toMillis(), user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[6], storeProduct: storeProduct14, historyItemUuid: uuid, addedDate: NSDate().toMillis(), user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[7], storeProduct: storeProduct15, historyItemUuid: uuid, addedDate: months4Ago, user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[8], storeProduct: storeProduct16, historyItemUuid: uuid, addedDate: NSDate().toMillis(), user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[9], storeProduct: storeProduct17, historyItemUuid: uuid, addedDate: months2Ago, user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[10], storeProduct: storeProduct18, historyItemUuid: uuid, addedDate: NSDate().toMillis(), user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[11], storeProduct: storeProduct19, historyItemUuid: uuid, addedDate: NSDate().toMillis(), user: user),
                
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[12], storeProduct: storeProduct8, historyItemUuid: uuid, addedDate: NSDate().toMillis(), user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[13], storeProduct: storeProduct9, historyItemUuid: uuid, addedDate: months4Ago, user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[14], storeProduct: storeProduct10, historyItemUuid: uuid, addedDate: months2Ago, user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[15], storeProduct: storeProduct11, historyItemUuid: uuid, addedDate: NSDate().toMillis(), user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[16], storeProduct: storeProduct12, historyItemUuid: uuid, addedDate: months2Ago, user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[17], storeProduct: storeProduct13, historyItemUuid: uuid, addedDate: NSDate().toMillis(), user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[18], storeProduct: storeProduct14, historyItemUuid: uuid, addedDate: NSDate().toMillis(), user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[19], storeProduct: storeProduct15, historyItemUuid: uuid, addedDate: months4Ago, user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[20], storeProduct: storeProduct16, historyItemUuid: uuid, addedDate: NSDate().toMillis(), user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[21], storeProduct: storeProduct17, historyItemUuid: uuid, addedDate: months2Ago, user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[22], storeProduct: storeProduct18, historyItemUuid: uuid, addedDate: NSDate().toMillis(), user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[23], storeProduct: storeProduct19, historyItemUuid: uuid, addedDate: NSDate().toMillis(), user: user),
                
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[24], storeProduct: storeProduct8, historyItemUuid: uuid, addedDate: NSDate().toMillis(), user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[25], storeProduct: storeProduct9, historyItemUuid: uuid, addedDate: months4Ago, user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[26], storeProduct: storeProduct10, historyItemUuid: uuid, addedDate: months2Ago, user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[27], storeProduct: storeProduct11, historyItemUuid: uuid, addedDate: NSDate().toMillis(), user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[28], storeProduct: storeProduct12, historyItemUuid: uuid, addedDate: months2Ago, user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[29], storeProduct: storeProduct13, historyItemUuid: uuid, addedDate: NSDate().toMillis(), user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[30], storeProduct: storeProduct14, historyItemUuid: uuid, addedDate: NSDate().toMillis(), user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[31], storeProduct: storeProduct15, historyItemUuid: uuid, addedDate: months4Ago, user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[32], storeProduct: storeProduct16, historyItemUuid: uuid, addedDate: NSDate().toMillis(), user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[33], storeProduct: storeProduct17, historyItemUuid: uuid, addedDate: months2Ago, user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[34], storeProduct: storeProduct18, historyItemUuid: uuid, addedDate: NSDate().toMillis(), user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[35], storeProduct: storeProduct19, historyItemUuid: uuid, addedDate: NSDate().toMillis(), user: user),
                
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[36], storeProduct: storeProduct8, historyItemUuid: uuid, addedDate: NSDate().toMillis(), user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[37], storeProduct: storeProduct9, historyItemUuid: uuid, addedDate: months4Ago, user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[38], storeProduct: storeProduct10, historyItemUuid: uuid, addedDate: months2Ago, user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[39], storeProduct: storeProduct11, historyItemUuid: uuid, addedDate: NSDate().toMillis(), user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[40], storeProduct: storeProduct12, historyItemUuid: uuid, addedDate: months2Ago, user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[41], storeProduct: storeProduct13, historyItemUuid: uuid, addedDate: NSDate().toMillis(), user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[42], storeProduct: storeProduct14, historyItemUuid: uuid, addedDate: NSDate().toMillis(), user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[43], storeProduct: storeProduct15, historyItemUuid: uuid, addedDate: months4Ago, user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[44], storeProduct: storeProduct16, historyItemUuid: uuid, addedDate: NSDate().toMillis(), user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[45], storeProduct: storeProduct17, historyItemUuid: uuid, addedDate: months2Ago, user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[46], storeProduct: storeProduct18, historyItemUuid: uuid, addedDate: NSDate().toMillis(), user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[47], storeProduct: storeProduct19, historyItemUuid: uuid, addedDate: NSDate().toMillis(), user: user),
                
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[48], storeProduct: storeProduct8, historyItemUuid: uuid, addedDate: NSDate().toMillis(), user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[49], storeProduct: storeProduct9, historyItemUuid: uuid, addedDate: months4Ago, user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[50], storeProduct: storeProduct10, historyItemUuid: uuid, addedDate: months2Ago, user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[51], storeProduct: storeProduct11, historyItemUuid: uuid, addedDate: NSDate().toMillis(), user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[52], storeProduct: storeProduct12, historyItemUuid: uuid, addedDate: months2Ago, user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[53], storeProduct: storeProduct13, historyItemUuid: uuid, addedDate: NSDate().toMillis(), user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[54], storeProduct: storeProduct14, historyItemUuid: uuid, addedDate: NSDate().toMillis(), user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[55], storeProduct: storeProduct15, historyItemUuid: uuid, addedDate: months4Ago, user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[56], storeProduct: storeProduct16, historyItemUuid: uuid, addedDate: NSDate().toMillis(), user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[57], storeProduct: storeProduct17, historyItemUuid: uuid, addedDate: months2Ago, user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[58], storeProduct: storeProduct18, historyItemUuid: uuid, addedDate: NSDate().toMillis(), user: user),
                InventoryItemWithHistoryEntry(inventoryItem: inventoryItems[59], storeProduct: storeProduct19, historyItemUuid: uuid, addedDate: NSDate().toMillis(), user: user)
            ]
            
            
            // add more items
//            let moreItems: [InventoryItemWithHistoryEntry] = (0...10000).map{i in
//                let category = ProductCategory(uuid: "111\(i)", name: "111\(i)", color: UIColor.blackColor())
//                let product = Product(uuid: "111\(i)", name: "111\(i)", price: 123, category: category, baseQuantity: 1, unit: .None)
//                let inventoryItem = inventoryItem(quantityDelta: 7, product: product, inventory: inventory1)
//                return InventoryItemWithHistoryEntry(inventoryItem: inventoryItem, historyItemUuid: "111\(i)", addedDate: NSDate().toMillis(), user: user)
//            }
            
            DBProviders.inventoryItemProvider.add(inventoryWithHistoryItems/* + moreItems*/, dirty: true) {saved in
                
                let list1 = List(uuid: uuid, name: "My first list", bgColor: RandomFlatColorWithShade(.Dark), order: 0, inventory: inventory1, store: nil)
                DBProviders.listProvider.saveList(list1) {result in
                    
                    let section1 = Section(uuid: uuid, name: "Obst", color: UIColor.flatRedColor(),list: list1, order: ListItemStatusOrder(status: .Todo, order: 0))
                    let section2 = Section(uuid: uuid, name: "Gemuese", color: UIColor.flatGreenColor(), list: list1, order: ListItemStatusOrder(status: .Todo, order: 1))
                    let section3 = Section(uuid: uuid, name: "Milchprodukte", color: UIColor.flatWhiteColor(), list: list1, order: ListItemStatusOrder(status: .Todo, order: 2))
                    let section4 = Section(uuid: uuid, name: "Fleisch", color: UIColor.flatRedColorDark(), list: list1, order: ListItemStatusOrder(status: .Todo, order: 3))
                    let section5 = Section(uuid: uuid, name: "Pasta", color: UIColor.flatWhiteColorDark(), list: list1, order: ListItemStatusOrder(status: .Todo, order: 4))
                    let section6 = Section(uuid: uuid, name: "Getraenke", color: UIColor.flatBlueColor(), list: list1, order: ListItemStatusOrder(status: .Todo, order: 5))
//                    let cleaning = Section(uuid: uuid, name: "Putzmittel", order: 6)
//                    let hygienic = Section(uuid: uuid, name: "Hygiene", order: 7)
//                    let spices = Section(uuid: uuid, name: "Gewürze", order: 8)
//                    let bread = Section(uuid: uuid, name: "Brot", order: 8)
                    
                    let listItems = [
                        ListItem(uuid: uuid, product: storeProduct1, section: section1, list: list1, todoQuantity: 5, todoOrder: 0),
                        ListItem(uuid: uuid, product: storeProduct2, section: section2, list: list1, todoQuantity: 2, todoOrder: 0),
                        ListItem(uuid: uuid, product: storeProduct3, section: section6, list: list1, todoQuantity: 3, todoOrder: 1),
                        ListItem(uuid: uuid, product: storeProduct4, section: section4, list: list1, todoQuantity: 3, todoOrder: 2),
                        ListItem(uuid: uuid, product: storeProduct5, section: section5, list: list1, todoQuantity: 4, todoOrder: 3),
                        ListItem(uuid: uuid, product: storeProduct6, section: section3, list: list1, todoQuantity: 3, todoOrder: 4),
                        ListItem(uuid: uuid, product: storeProduct7, section: section6, list: list1, todoQuantity: 4, todoOrder: 5)
                    ]
                    
                    DBProviders.listItemProvider.saveListItems(listItems, incrementQuantity: false) {saved in
                        QL1("Done adding dummy data")
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
    
    
    func applicationDidBecomeActive(application: UIApplication) {
        QL2("applicationDidBecomeActive")
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillResignActive(application: UIApplication) {
        QL2("applicationWillResignActive")
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.

    }

    func applicationWillEnterForeground(application: UIApplication) {
        QL2("applicationWillEnterForeground")
        checkPing() // TODO!!!! applicationWillEnterForeground seems not to be called on launch - is this intended?
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        QL2("applicationDidEnterBackground")
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
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

    func applicationWillTerminate(application: UIApplication) {
        QL2("applicationWillTerminate")
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
                Providers.globalProvider.sync(false) {[weak self] result in
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
    
    func onDismissRatingAlert() {
        ratingAlert = nil
    }
    
    func onLoginTokenExpired(note: NSNotification) {
        guard let controller = window?.rootViewController else {"Can't show login modal, either window: \(window) or root controller: \(window?.rootViewController) is nil)"; return}

        let loginController = ModalLoginController()
        controller.presentViewController(loginController, animated: true, completion: nil)
    }
    
    // MARK: - Websocket
    
    func onWebsocketConnectionChange(note: NSNotification) {
        
        if let info = note.userInfo as? Dictionary<String, Bool> {
            if let notification = info[WSNotificationValue] {
                switch notification {
                case true:
                    if let window = window {
                        if isShowingBottomNotification(ViewTags.ConnectionLabel) {
                            removeBottomNotification()
                            
                            // Do sync
                            // The fact that we check first if we are showing the no-connection label to be here, means that we do sync only after:
                            // 1. The websocket connection was refused - (server was down when we started the app and tried to establish a connection, for example)
                            // 2. The connection was interrupted - (server was stopped after having established a connection)
                            // In these cases the time between the interruption and restoring of connection is arbitrary we have to sync possible actions of user during this time.
                            // The normal flow of the app is that if we have an internet connection and have a (valid) login token the websocket connection should also work. So in these cases, we don't need a sync as there is a connection from the beginning (TODO check if it's possible that user can do some actions in the short time between app start and the connection is done?)
                            // If there's no connection or no login token, there will be no attempt to establish a websocket connection. In these cases the sync is done when the connection status changes or the user logs in.
                            // If the login token is expired, the websocket connection returns ----> ???? in this case we delete the login token just like when we call a rest service with an expired token.  Here the next sync will happen when the user logs in again. TODO: handle the not auth response of websocket: 1. delete token like in service, 2. show login screen (this is also a TODO!!!! for service)
                            if let controller = window.rootViewController {
                                controller.progressVisible()
                                QL2("Websocket reconnected. Starting sync...")
                                
                                Providers.globalProvider.sync(false, handler: controller.successHandler{invitations in
                                    QL3("Sync complete")
                                    // Broadcast such that controllers can e.g. reload items.
                                    NSNotificationCenter.defaultCenter().postNotificationName(WSNotificationName.IncomingGlobalSyncFinished.rawValue, object: nil, userInfo: info)
                                })
                                
                            } else {
                                QL4("Couldn't do sync, root controller: \(window.rootViewController) is nil)")
                            }
                        }
                    } else {
                        QL4("Couldn't show popup, is nil)")
                    }
                case false:
                    if window?.viewWithTag(ViewTags.ConnectionLabel) == nil {
                        showBottomNotification("No server connection. Trying to connect...", textColor: UIColor.flatRedColor(), tag: ViewTags.ConnectionLabel)
                    }
                }
            } else {
                QL4("No value")
            }
            
        }
    }

    private func isShowingBottomNotification(tag: Int) -> Bool {
        return window?.viewWithTag(tag) != nil
    }
    
    private func removeBottomNotification() {
        window?.viewWithTag(ViewTags.ConnectionLabel)?.removeFromSuperview()
    }
    
    private func showBottomNotification(text: String, textColor: UIColor, tag: Int) -> UIView? {
        if let window = window
            //                        ,controller = window.rootViewController
            //                        , tabBarHeight = controller.tabBarController?.tabBar.frame.height // nil
        {
            
            let tabBarHeight: CGFloat = 49
            let labelHeight: CGFloat = 20
            let label = UILabel(frame: CGRectMake(0, window.frame.height - tabBarHeight - labelHeight, window.frame.width, labelHeight))
            label.tag = tag
            label.font = Fonts.smaller
            label.textAlignment = .Center
            label.backgroundColor = UIColor.whiteColor()
            label.textColor = textColor
            label.text = text
            window.addSubview(label)
            return label
            
        } else {
            QL4("Couldn't show popup, is nil)")
            return nil
        }
    }
    
    func onWebsocketReceptionNotification(note: NSNotification) {
        if let info = note.userInfo as? Dictionary<String, String> {
            if let sender = info["sender"], category = info["category"], _ = info["verb"] {
                
                let categoryText = category.capitalizedString
                let msg = "\(sender) updated."
                
                let notificationView = showBottomNotification(msg, textColor: UIColor.blackColor(), tag: ViewTags.WebsocketSenderNotification)
                delay(websocketVisualNotificationDuration) {
                    notificationView?.removeFromSuperview()
                }
            } else {
                QL4("Invalid dictionary format: \(info)")
            }
        } else {
            QL4("No userInfo")
        }
    }
    
    func onWebsocketProcessingError(note: NSNotification) {
        let notificationView = showBottomNotification("Error processing incoming update", textColor: UIColor.whiteColor(), tag: ViewTags.WebsocketErrorNotification)
        delay(websocketVisualNotificationDuration) {
            notificationView?.removeFromSuperview()
        }
    }
    
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
                        
                        Providers.globalProvider.sync(true, handler: controller.successHandler{invitations in
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

