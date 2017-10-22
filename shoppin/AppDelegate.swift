//
//  AppDelegate.swift
//  shoppin
//
//  Created by ischuetz on 06.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import UIKit
import CoreData
import Reachability
import ChameleonFramework
import HockeySDK
import GoogleSignIn
import RealmSwift
import Providers
import FBSDKLoginKit

@objc
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, RatingAlertDelegate {

    fileprivate let debugAddDummyData = false
    fileprivate let debugGeneratePrefillDatabases = false // remove this?
    fileprivate let debugForceShowIntro = false
    fileprivate let debugForceIsFirstAppLaunch = false
    
    var window: UIWindow?
    
    fileprivate var reachability: Reachability!
    
    fileprivate let userProvider = ProviderFactory().userProvider // arc

    fileprivate var suggestionsPrefiller: SuggestionsPrefiller? // arc

    fileprivate var ratingAlert: RatingAlert? // arc
    
    fileprivate let websocketVisualNotificationDuration: Double = 2

    override init() {

        logger.configure()

        super.init()
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        initIsFirstLaunch()
        
        ifDebugLaunchActions()
        
        showController()

        initReachability()

        initGlobalAppearance()
        
        // Facebook sign-in
        let initFb = FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        
        initHockey()
        
        checkPing()
        
        checkRatePopup()

//        initWebsocket()

        configRealm()
        
        Notification.subscribe(.LoginTokenExpired, selector: #selector(AppDelegate.onLoginTokenExpired(_:)), observer: self)
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.onWebsocketConnectionChange(_:)), name: NSNotification.Name(rawValue: WSNotificationName.Connection.rawValue), object: nil)
        
        // Temporarily disabled as this is crashing the app ("unrecognized selector" though the selector definitely exists) and current functionality in UserTabItemViewController.onLogoutNotification (show the login controller) doesn't seem to be needed.
//        NotificationCenter.default.addObserver(self, selector: #selector(UserTabItemViewController.onLogoutNotification(_:)), name: NSNotification.Name(rawValue: Notification.Logout.rawValue), object: nil)
        
        checkClearHistory()
        
        return initFb
    }
    var notificationToken: NotificationToken!
    
    fileprivate func configRealm() {
        Realm.Configuration.defaultConfiguration = RealmConfig.config

        logger.i("Realm path: \(String(describing: Realm.Configuration.defaultConfiguration.fileURL))", .db)
    }
    
    fileprivate func checkRatePopup() {
        if let controller = window?.rootViewController {
            ratingAlert = RatingAlert()
            ratingAlert?.delegate = self
            ratingAlert?.checkShow(controller)
        } else {
            logger.e("Couldn't show rating popup, either window: \(String(describing: window)) or root controller: \(String(describing: window?.rootViewController)) is nil)")
        }
    }
    
    fileprivate func initWebsocket() {
        _ = WebsocketHelper.tryConnectWebsocket()
        
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.onWebsocketReceptionNotification(_:)), name: NSNotification.Name(rawValue: WSNotificationName.Reception.rawValue), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.onWebsocketProcessingError(_:)), name: NSNotification.Name(rawValue: WSNotificationName.ProcessingError.rawValue), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.onWebsocketList(_:)), name: NSNotification.Name(rawValue: WSNotificationName.List.rawValue), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.onWebsocketInventory(_:)), name: NSNotification.Name(rawValue: WSNotificationName.Inventory.rawValue), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.onWebsocketSharedSync(_:)), name: NSNotification.Name(rawValue: WSNotificationName.SyncShared.rawValue), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.onShowShouldUpdateAppDialog(_:)), name: NSNotification.Name(rawValue: Notification.ShowShouldUpdateAppDialog.rawValue), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.onShowMustUpdateAppDialog(_:)), name: NSNotification.Name(rawValue: Notification.ShowMustUpdateAppDialog.rawValue), object: nil)
    }
    
    fileprivate func initHockey() {
        BITHockeyManager.shared().configure(withIdentifier: "589348069297465892087104a6337407")
        // Do some additional configuration if needed here
        BITHockeyManager.shared().start()
        BITHockeyManager.shared().authenticator.authenticateInstallation()
    }
    
    fileprivate func showController() {
        
        let controller = UIStoryboard.mainTabController()
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.rootViewController = controller
        self.window?.makeKeyAndVisible()
        
        if (isDebug() && debugForceShowIntro) || PreferencesManager.loadPreference(PreferencesManagerKey.showIntro) ?? true {
            let introController = UIStoryboard.introViewController()

            let listController = (controller.viewControllers?.first as? UINavigationController)?.viewControllers.first as? ListsTableViewController
            listController?.allowedToLoadModelsOnWillAppear = false

            // On first launch make lists view controller update immediately after create example list, such that when user exits intro there's not a little delay where they see empty image while the example list is loaded. The reason the empty image shows is that the first view controller is loaded immediately - not after intro controller, and it fetches lists which are empty at this point.
            introController.onCreateExampleList = {[weak listController] in
                listController?.initModels()
                listController?.allowedToLoadModelsOnWillAppear = true
            }
            
            introController.mode = .launch
            
            let navController = UINavigationController()
            navController.viewControllers = [introController]
            
            self.window?.rootViewController?.present(navController, animated: false, completion: nil)
        }
    }
    
    fileprivate func initIsFirstLaunch() {
        
        if debugForceIsFirstAppLaunch {
            PreferencesManager.savePreference(PreferencesManagerKey.hasLaunchedBefore, value: false)
        }
        
        if !(PreferencesManager.loadPreference(PreferencesManagerKey.hasLaunchedBefore) ?? false) { // first launch
            logger.d("Initialising first app launch preferences")
            PreferencesManager.savePreference(PreferencesManagerKey.hasLaunchedBefore, value: true)
            PreferencesManager.savePreference(PreferencesManagerKey.isFirstLaunch, value: true)
            PreferencesManager.savePreference(PreferencesManagerKey.firstLaunchDate, value: Date())
            
            // Ensure there's no login token from a previous app installation (token is stored in the keychain, which is not deleted when the app is uninstalled).
            AccessTokenHelper.removeToken()

        } else { // after first launch
            logger.v("Not first launch")
            PreferencesManager.savePreference(PreferencesManagerKey.isFirstLaunch, value: false)
        }
    }
    
    fileprivate func initGlobalAppearance() {
        
        let regularFont: UIFont = {
            if let fontSize = LabelMore.mapToFontSize(50) {
                return UIFont.systemFont(ofSize: fontSize)
            } else {
                logger.e("Not supported font size")
                return UIFont.systemFont(ofSize: 18)
            }
        }()
        
//        UITabBarItem.appearance().setTitleTextAttributes([NSFontAttributeName: Fonts.superSmallLight, NSForegroundColorAttributeName: Theme.navigationBarTextColor], forState: .Normal)
        UINavigationBar.appearance().titleTextAttributes = [NSAttributedStringKey.font: regularFont, NSAttributedStringKey.foregroundColor: Theme.tabBarTextColor]
        UIBarButtonItem.appearance().setTitleTextAttributes([NSAttributedStringKey.font: regularFont, NSAttributedStringKey.foregroundColor: Theme.navigationBarTextColor], for: UIControlState())
//        UISegmentedControl.appearance().setTitleTextAttributes([NSFontAttributeName: Fonts.verySmallLight], forState: .Normal)
        
        UITabBar.appearance().tintColor = Theme.tabBarSelectedColor
        UITabBar.appearance().barTintColor = Theme.tabBarBackgroundColor
        UITabBar.appearance().isTranslucent = false

        // Hide hairline
        UINavigationBar.appearance().shadowImage = UIImage()
        UINavigationBar.appearance().setBackgroundImage(UIImage(), for: .default)
        
        UINavigationBar.appearance().barTintColor = Theme.navigationBarBackgroundColor
        UINavigationBar.appearance().tintColor = Theme.navigationBarTextColor
        UINavigationBar.appearance().isTranslucent = false
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        
//        print("AppDelegate open url: \(url)")
        
        if (url.scheme?.contains("fb335124139955932"))! {
            return FBSDKApplicationDelegate.sharedInstance().application(application, open: url, sourceApplication: sourceApplication, annotation: annotation)
        } else if (url.scheme?.contains("google"))! {
            return GIDSignIn.sharedInstance().handle(url, sourceApplication: sourceApplication, annotation: annotation)
        } else {
            return false
        }
    }

    // MARK: - Debug
    
    fileprivate func isDebug() -> Bool {
        #if DEBUG
            return true
            #else
            return false
        #endif
    }
    
    // Actions executed if app is in debug mode
    fileprivate func ifDebugLaunchActions() {
        #if DEBUG
//            if debugGeneratePrefillDatabases {
//                generatePrefillDatabase()
//            }
////            if debugAddDummyData || !(PreferencesManager.loadPreference(PreferencesManagerKey.hasLaunchedBefore) ?? false) { // first launch
//////                addDummyData()
////            }
            #else
        #endif
    }
    
//    /**
//    * Create database which we embed in the app in order to prefill the app's database
//    * TODO try to use test for this (PrefillDatabase - not working because sth with Realm). This should not be in of the app.
//    */
//    fileprivate func generatePrefillDatabase() {
//        print("Creating prefilled databases")
//        self.suggestionsPrefiller = SuggestionsPrefiller()
//        self.suggestionsPrefiller?.prefill {
//            print("Finished creating prefilled databases")
//        }
//    }

//    // A minimal dummy data setup with 1 inventory, 1 list and 1 list item (with corresponding product and category)
//    fileprivate func addDummyData() {
//        
//        var uuid: String {
//            return UUID().uuidString
//        }
//        let fruitsCat = ProductCategory(uuid: uuid, name: "Obst", color: UIColor.flatRed)
//        let product1 = Product(uuid: uuid, name: "Birnen", category: fruitsCat, brand: "")
//
//        let inventory1 = DBInventory(uuid: uuid, name: "My Home inventory", bgColor: UIColor.flatGreen, order: 0)
//        DBProv.inventoryProvider.saveInventory(inventory1, dirty: true) {saved in
//            
//            let list1 = List(uuid: uuid, name: "My first list", color: RandomFlatColorWithShade(.dark), order: 0, inventory: inventory1, store: nil)
//            DBProv.listProvider.saveList(list1) {result in
//                
//                let section1 = Section(uuid: uuid, name: "Obst", color: UIColor.flatRed, list: list1, order: ListItemStatusOrder(status: .todo, order: 0))
//                let storeProduct1 = StoreProduct(uuid: uuid, price: 1, baseQuantity: 1, unit: .none, store: "my store", product: product1)
//                let listItems = [
//                    ListItem(uuid: uuid, product: storeProduct1, section: section1, list: list1, todoQuantity: 5, todoOrder: 0)
//                ]
//                
//                DBProv.listItemProvider.addOrIncrementListItems(listItems) {saved in
//                    logger.v("Done adding dummy data (mini)")
//                }
//            }
//        }
//    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        logger.d("applicationDidBecomeActive")
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        logger.d("applicationWillResignActive")
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.

    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        logger.d("applicationWillEnterForeground")
        checkPing() // TODO!!!! applicationWillEnterForeground seems not to be called on launch - is this intended?
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        logger.d("applicationDidEnterBackground")
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    fileprivate func checkPing() {
        if let lastTokeUpdateDate: Date = PreferencesManager.loadPreference(PreferencesManagerKey.lastTokenUpdate) {
            
            // Refresh the token, max 1 time in <days>
            // If we find a method to guarantee (background service?) that we refresh the token each x days, we can set this to a bigger value. Consult server for more details.
            let days = 1
            let passedDays = lastTokeUpdateDate.daysUntil(Date())
            if passedDays >= days {
                logger.d("\(passedDays) days passed since last token refresh. Ping")
                userProvider.ping()
            } else {
                logger.v("There is a token last update date, but \(days) days not passed yet. Passed days: \(passedDays)")
            }
        } else {
            logger.v("No token last update date stored yet")
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
        logger.d("applicationWillTerminate")
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        Prov.userProvider.disconnectWebsocket()
        
        NotificationCenter.default.removeObserver(self)
    }
    
    // Remove history entries older than 1 year
    fileprivate func checkClearHistory() {
        Prov.historyProvider.removeHistoryItemsOlderThan(Date.inMonths(-12)) {providerResult in
            // Do nothing, it there's an error it's already logged in the provider. It doesn't make sense to show this to the user
        }
    }
    
    
    // MARK: - Reachability
    
    fileprivate func initReachability() {
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.checkForReachability(_:)), name: NSNotification.Name.reachabilityChanged, object: nil)
        self.reachability = Reachability.forInternetConnection()
        self.reachability.startNotifier()
    }
    
    @objc func checkForReachability(_ notification: Foundation.Notification) {
        
        let networkReachability = notification.object as! Reachability
        let remoteHostStatus = networkReachability.currentReachabilityStatus()

        logger.v("Changed connectivity status: \(remoteHostStatus.rawValue)")

        if remoteHostStatus != .NotReachable { // wifi / wwan
            logger.d("Connected")
            
            if userProvider.hasLoginToken {
                logger.d("User has login token, start sync")
                window?.defaultProgressVisible(true)
                Prov.globalProvider.sync(false) {[weak self] result in
                    logger.d("Sync finished")
                    if !result.success {
                        logger.e("Error: AppDelegate.checkForReachability: Sync didn't succeed: \(result)")
                    }

                    if let syncResult = result.sucessResult {
                        if let controller = self?.window?.rootViewController {
                            InvitationsHandler.handleInvitations(syncResult.listInvites, inventoryInvitations: syncResult.inventoryInvites, controller: controller)
                        } else {
                            logger.e("Couldn't show popup, either window: \(String(describing: self?.window)) or root controller: \(String(describing: self?.window?.rootViewController)) is nil)")
                        }
                    } else {
                        logger.e("Invalid state: result doesn't have sync result")
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
    
    @objc func onLoginTokenExpired(_ note: Foundation.Notification) {
        // Disabled to not have to declare mock as public in Prov.(we also don't need this functionality now)
//        guard let controller = window?.rootViewController else {logger.e("Can't show login modal, either window: \(window) or root controller: \(window?.rootViewController) is nil)"); return}
//        if !(Prov.userProvider is UserProviderMock) {
//            let loginController = ModalLoginController()
//            controller.present(loginController, animated: true, completion: nil)
//        }
    }

    // MARK: - Logout
    
    
    func logout(_ note: Foundation.Notification) {
        FBSDKLoginManager().logOut()
        GIDSignIn.sharedInstance().signOut()
        GIDSignIn.sharedInstance().disconnect()
    }
    
    
    // MARK: - Websocket
    
    @objc func onWebsocketConnectionChange(_ note: Foundation.Notification) {
        
        if let info = (note as NSNotification).userInfo as? Dictionary<String, Bool> {
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
                                logger.d("Websocket reconnected. Starting sync...")
                                
                                Prov.globalProvider.sync(false, handler: controller.successHandler{invitations in
                                    logger.w("Sync complete")
                                    // Broadcast such that controllers can e.g. reload items.
                                    NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: WSNotificationName.IncomingGlobalSyncFinished.rawValue), object: nil, userInfo: info)
                                })
                                
                            } else {
                                logger.e("Couldn't do sync, root controller: \(String(describing: window.rootViewController)) is nil)")
                            }
                        }
                    } else {
                        logger.e("Couldn't show popup, is nil)")
                    }
                case false:
                    if window?.viewWithTag(ViewTags.ConnectionLabel) == nil {
                        _ = showBottomNotification("No server connection. Trying to connect...", textColor: UIColor.flatRed, tag: ViewTags.ConnectionLabel)
                    }
                }
            } else {
                logger.e("No value")
            }
            
        }
    }

    fileprivate func isShowingBottomNotification(_ tag: Int) -> Bool {
        return window?.viewWithTag(tag) != nil
    }
    
    fileprivate func removeBottomNotification() {
        window?.viewWithTag(ViewTags.ConnectionLabel)?.removeFromSuperview()
    }
    
    fileprivate func showBottomNotification(_ text: String, textColor: UIColor, tag: Int) -> UIView? {
        if let window = window
            //                        ,controller = window.rootViewController
            //                        , tabBarHeight = controller.tabBarController?.tabBar.frame.height // nil
        {
            
            let tabBarHeight: CGFloat = 49
            let labelHeight: CGFloat = 20
            let label = UILabel(frame: CGRect(x: 0, y: window.frame.height - tabBarHeight - labelHeight, width: window.frame.width, height: labelHeight))
            label.tag = tag
            label.font = Fonts.smaller
            label.textAlignment = .center
            label.backgroundColor = UIColor.white
            label.textColor = textColor
            label.text = text
            window.addSubview(label)
            return label
            
        } else {
            logger.e("Couldn't show popup, is nil)")
            return nil
        }
    }
    
    @objc func onWebsocketReceptionNotification(_ note: Foundation.Notification) {
        if let info = (note as NSNotification).userInfo as? Dictionary<String, String> {
            if let sender = info["sender"], let _ = info["category"], let _ = info["verb"] {
                
//                let categoryText = category.capitalizedString
                let msg = "\(sender) updated."
                
                let notificationView = showBottomNotification(msg, textColor: UIColor.black, tag: ViewTags.WebsocketSenderNotification)
                delay(websocketVisualNotificationDuration) {
                    notificationView?.removeFromSuperview()
                }
            } else {
                logger.e("Invalid dictionary format: \(info)")
            }
        } else {
            logger.e("No userInfo")
        }
    }
    
    @objc func onWebsocketProcessingError(_ note: Foundation.Notification) {
        let notificationView = showBottomNotification("Error processing incoming update", textColor: UIColor.white, tag: ViewTags.WebsocketErrorNotification)
        delay(websocketVisualNotificationDuration) {
            notificationView?.removeFromSuperview()
        }
    }
    
    @objc func onWebsocketList(_ note: Foundation.Notification) {
        
        if let info = (note as NSNotification).userInfo as? Dictionary<String, WSNotification<RemoteListInvitation>> {
            if let notification = info[WSNotificationValue] {
                let invitation = notification.obj
                switch notification.verb {
                case .Invite:
                    if let controller = window?.rootViewController {
                        ListInvitationsHandler.handleInvitation(invitation, controller: controller)
                    } else {
                        logger.e("Couldn't show popup, either window: \(String(describing: window)) or root controller: \(String(describing: window?.rootViewController)) is nil)")
                    }
                default: logger.e("Not handled case: \(notification.verb))")
                }
            } else {
                logger.e("No value")
            }
            
        }
    }
    
    @objc func onWebsocketInventory(_ note: Foundation.Notification) {
        
        if let info = (note as NSNotification).userInfo as? Dictionary<String, WSNotification<RemoteInventoryInvitation>> {
            if let notification = info[WSNotificationValue] {
                let invitation = notification.obj
                switch notification.verb {
                case .Invite:
                    if let controller = window?.rootViewController {
                        InventoryInvitationsHandler.handleInvitation(invitation, controller: controller)
                    } else {
                        logger.e("Couldn't show popup, either window: \(String(describing: window)) or root " +
                            "controller: \(String(describing: window?.rootViewController)) is nil)")
                    }
                default: logger.e("Not handled case: \(notification.verb))")
                }
            } else {
                logger.e("No value")
            }
            
        }
    }
    
    // Process this here in AppDelegate because it's global and we have a controller, which we need to show possible invitations and maybe a progress indicator
    @objc func onWebsocketSharedSync(_ note: Foundation.Notification) {
        
        if let info = (note as NSNotification).userInfo as? Dictionary<String, WSNotification<String>> {
            if let notification = info[WSNotificationValue] {
                let sender = notification.obj
                switch notification.verb {
                case .Sync:
                    if let controller = window?.rootViewController {
                        controller.progressVisible()
                        logger.d("Shared items sync request by \(sender)")
                        // text to user "Incoming sync request from x" or "Processing sync request from x" or "Sync request triggered by x" or "Sync request by x" or "x Sync request"
                        
                        Prov.globalProvider.sync(true, handler: controller.successHandler{invitations in
                            logger.w("Are we really expecting invitations here? (not sure if this should be a warning): \(invitations)")
                            InvitationsHandler.handleInvitations(invitations.listInvites, inventoryInvitations: invitations.inventoryInvites, controller: controller)
                            
                            // Broadcast such that controllers can e.g. reload items.
                            NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: WSNotificationName.IncomingGlobalSyncFinished.rawValue), object: nil, userInfo: info)
                        })
                        
                    } else {
                        logger.e("Couldn't show popup, either window: \(String(describing: window)) or root controller: \(String(describing: window?.rootViewController)) is nil)")
                    }
                default: logger.e("Not handled case: \(notification.verb))")
                }
            } else {
                logger.e("No value")
            }
            
        }
    }
    
    @objc func onShowShouldUpdateAppDialog(_ note: Foundation.Notification) {
        guard window?.rootViewController?.presentedViewController == nil else {logger.w("Root controller already showing a popup, return"); return}

        if let controller = window?.rootViewController {
            
            func appInstallDate() -> Date {
                return PreferencesManager.loadPreference(PreferencesManagerKey.firstLaunchDate) ?? {
                    logger.e("Invalid state: There's no app first launch date stored.")
                    return Date() // just to return something - note that with this we will never show the popup as the time offset will be ~0
                }()
            }
            
            // last time the we shown the dialog to the user, if it was never shown we return distant past such that it will be shown
            let referenceDate = PreferencesManager.loadPreference(PreferencesManagerKey.lastShouldUpdateAppDialogDate).map {(date: Date) in
                return date
            } ?? Date.distantPast
            
            let now = Date()

            let showAfterDays = Constants.dayCountShouldUpdatAppDialog
            let passedDays = referenceDate.daysUntil(now)
            logger.v("\(passedDays) days passed since last time we showed should update dialog. Showing if >= \(showAfterDays)")
            if passedDays >= showAfterDays {
                
                // Save current date, to be used as reference date next time. Note that this doesn't have to be cleared - 
                PreferencesManager.savePreference(PreferencesManagerKey.lastShouldUpdateAppDialogDate, value: now)
                
                ConfirmationPopup.show(title: "Update", message: "You haven't updated the app in a while.\nTo continue accessing your user account, it's recommended to update.\nThe server will stop supporting this version soon, and you will not be able to log in with it anymore.", okTitle: "Update", cancelTitle: "Not now", controller: controller, onOk: {
                    
                    if let url = URL(string: Constants.appStoreLink) {
                        
                        if UIApplication.shared.openURL(url) {
                            logger.v("Update dialog: opened app store")
                            
                        } else {
                            logger.v("Rating dialog: Couldn't open app store url")
                            AlertPopup.show(message: trans("popup_couldnt_open_app_store_url"), controller: controller)
                        }
                    } else {
                        logger.e("Url is nil, can't go to app store")
                    }
                    
                }, onCancel: nil)
            }
        }
    }
    
    @objc func onShowMustUpdateAppDialog(_ note: Foundation.Notification) {
        guard window?.rootViewController?.presentedViewController == nil else {logger.w("Root controller already showing a popup, return"); return}
        
        if let controller = window?.rootViewController {
            
            Prov.userProvider.logout(controller.successHandler{
                logger.d("Logout success")
                Notification.send(Notification.LogoutUI) // in case we are currently in user screens
            })
            
            ConfirmationPopup.show(title: trans("popup_title_required_update"), message: trans("popup_please_update_app_to_use_account"), okTitle: trans("popup_button_update"), cancelTitle: trans("popup_button_log_out"), controller: controller, onOk: {
                
                if let url = URL(string: Constants.appStoreLink) {
                    
                    if UIApplication.shared.openURL(url) {
                        logger.v("Update dialog: opened app store")
                        
                    } else {
                        logger.v("Rating dialog: Couldn't open app store url")
                        AlertPopup.show(message: trans("popup_couldnt_open_app_store_url"), controller: controller)
                    }
                } else {
                    logger.e("Url is nil, can't go to app store")
                }
                
                }, onCancel: nil)
        }
    }
}
