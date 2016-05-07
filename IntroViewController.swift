//
//  IntroViewController.swift
//  shoppin
//
//  Created by ischuetz on 26/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved/≥.
//

import UIKit
import SwipeView
import QorumLogs

class IntroViewController: UIViewController, RegisterDelegate, LoginDelegate, SwipeViewDataSource, SwipeViewDelegate {

    @IBOutlet weak var swipeView: SwipeView!
    @IBOutlet weak var pageControl: UIPageControl!
    
    @IBOutlet weak var skipButton: UIButton!
    // This works but for now disabled, no signup in intro
//    @IBOutlet weak var loginButton: UIButton!
//    @IBOutlet weak var registerButton: UIButton!
    
    private let pageModels: [(key: String, imageName: String)] = [
        ("Manage shopping lists comfortably", "intro_lists"),
        ("Connect lists with inventories to keep track of your items", "intro_inventory"),
        ("Share with other users in real time", "intro_sharing"),
        ("Analyse your shopping behaviour and expenses", "intro_stats")
    ]
    
    private var finishedSlider = false {
        didSet {
            skipButton.setTitle("Start", forState: .Normal)
            skipButton.setTitleColor(UIColor(hexString: "222222"), forState: .Normal)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pageControl.numberOfPages = pageModels.count
        
        let initActions =  PreferencesManager.loadPreference(PreferencesManagerKey.isFirstLaunch) ?? false
//        let initActions = true
        
        QL1("Will init database: \(initActions)")
        
        if initActions {
            setButtonsEnabled(false)
            initDatabase {[weak self] in
                self?.setButtonsEnabled(true)
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        self.navigationController?.navigationBarHidden = true
    }
    
    private func setButtonsEnabled(enabled: Bool) {
        skipButton.enabled = enabled
//        loginButton.enabled = enabled
//        registerButton.enabled = enabled
    }
    
//    @IBAction func loginTapped(sender: UIButton) {
//        startLogin(.Normal)
//    }
    
    private func startLogin(mode: LoginControllerMode) {
        let loginController = UIStoryboard.loginViewController()
        loginController.delegate = self
        loginController.onUIReady = {
            loginController.mode = mode
        }

        self.navigationController?.pushViewController(loginController, animated: true)
    }

    private func initDatabase(onComplete: VoidFunction) {

        func prefillDatabase(onFinish: VoidFunction? = nil) {
            let lang = LangManager().appLang // note that the prefill items are left permanently in whatever lang the device was when the user installed the app
            
            SuggestionsPrefiller().prefill(lang) {success in
                QL1("Finish initialising database, success: \(success)")
                onFinish?()
            }
        }
        
        func initDefaultInventory(onFinish: VoidFunction? = nil) {
            Providers.inventoryProvider.inventories(false, successHandler{[weak self] inventories in
                if let weakSelf = self {
                    if inventories.isEmpty {
                        let inventory = Inventory(uuid: NSUUID().UUIDString, name: "Home", bgColor: UIColor.flatBlueColor(), order: 0)
                        Providers.inventoryProvider.addInventory(inventory, remote: true, weakSelf.resultHandler(onSuccess: {
                            onFinish?()
                            }, onError: {result in
                                // let the user start if there's an error (we don't expect any, but just in case!)
                                // it would be very bad if user can't get past intro for whatever reason. Both adding default inventory and default products (TODO) are not critical for the app to be usable.
                                onFinish?()
                        }))
                    } else {
                        onFinish?()
                    }
                }
            })
        }

        prefillDatabase {
            QL2("Finished copying prefill database")
            initDefaultInventory {
                QL2("Finished adding default inventory")
                onComplete()
            }
        }
    }

//    @IBAction func registerTapped(sender: UIButton) {
//        let registerController = UIStoryboard.registerViewController()
//        registerController.delegate = self
//        self.navigationController?.pushViewController(registerController, animated: true)
//    }

    
    @IBAction func skipTapped(sender: UIButton) {
        PreferencesManager.savePreference(PreferencesManagerKey.showIntro, value: false)
        self.startMainStoryboard()
    }
    
    // MARK: - RegisterDelegate
    
    func onRegisterSuccess(email: String) {
        self.navigationController?.popViewControllerAnimated(true)
        startLogin(.AfterRegister)
    }
    
    func onSocialSignupInRegisterScreenSuccess() {
        // TODO review this - not tested. For now no signup buttons in intro so we let it like this, maybe we want to reenable it later.
        self.navigationController?.popViewControllerAnimated(true)
        startLogin(.AfterRegister)
    }
    
    // MARK: -
    
    private func startMainStoryboard() {
        self.navigationController?.navigationBarHidden = true // otherwise it overlays the navigation of the nested view controllers (not sure if this structure is ok, maybe all should use the same navigation controller?)

        let tabController = UIStoryboard.mainTabController()
        self.navigationController?.setViewControllers([tabController], animated: true)
    }
    
    func onLoginSuccess() {
        PreferencesManager.savePreference(PreferencesManagerKey.showIntro, value: false)
        self.startMainStoryboard()
    }
    
    func onRegisterFromLoginSuccess() {
    }
    
    // MARK: - SwipeViewDataSource
    
    func numberOfItemsInSwipeView(swipeView: SwipeView!) -> Int {
        return pageModels.count
    }
    
    func swipeView(swipeView: SwipeView!, viewForItemAtIndex index: Int, reusingView view: UIView!) -> UIView! {
    
        let v = (view ?? NSBundle.loadView("IntroPageView", owner: self)!) as! IntroPageView
        
        let pageModel = pageModels[index]
        
        let image = UIImage(named: pageModel.imageName)!
        v.imageView.image = image
        v.label.text = pageModel.key

        return v
    }

    // MARK: - SwipeViewDelegate
    
    func swipeViewCurrentItemIndexDidChange(swipeView: SwipeView!) {
        pageControl.currentPage = swipeView.currentItemIndex
        if swipeView.currentItemIndex == pageModels.count - 1 {
            if !finishedSlider {
                finishedSlider = true
            }
        }
    }
    
    func swipeViewItemSize(swipeView: SwipeView!) -> CGSize {
        return swipeView.frame.size
    }
}