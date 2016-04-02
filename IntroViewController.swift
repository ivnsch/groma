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
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var registerButton: UIButton!
    
    private let pageCount = 5 // later replace with array of images
    
    private let pageModels: [(key: String, imageName: String)] = [
        ("Manage shopping lists comfortably", "empty_shelf"),
        ("Connect lists with inventories to keep track of your items", "empty_shelf"),
        ("Share with other users in real time", "empty_shelf"),
        ("Analyse your shopping behaviour and expenses", "empty_shelf"),
        ("Browse your shopping history", "empty_shelf")
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pageControl.numberOfPages = pageCount
        
//        let initActions =  PreferencesManager.loadPreference(PreferencesManagerKey.isFirstLaunch) ?? false
        let initActions = true
        
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
        loginButton.enabled = enabled
        registerButton.enabled = enabled
    }
    
    @IBAction func loginTapped(sender: UIButton) {
        startLogin(.Normal)
    }
    
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
            background({
                let p = NSHomeDirectory() + "/Documents/default.realm"
                let lang = LangManager().appLang
                if let prefillPath = NSBundle.mainBundle().pathForResource("prefill\(lang)", ofType: "realm") {
                    QL2("Copying prefill database for lang: \(lang) to: \(p)")
                    do {
//                        try NSFileManager.defaultManager().removeItemAtPath(p)
                        try NSFileManager.defaultManager().copyItemAtPath(prefillPath, toPath: p)
                        QL1("Copied prefill database")
                        return true
                        
                    } catch let error as NSError {
                        QL4("Error copying prefill database: \(error)")
                        return false
                    }
                } else {
                    QL4("Prefill database was not found")
                    return false
                }
                }) {(success: Bool) in
                    if !success {
                        QL4("Not success prefilling database")
                    }
                    onFinish?() // don't return anything, if prefill fails we still start the app normally
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

    @IBAction func registerTapped(sender: UIButton) {
        let registerController = UIStoryboard.registerViewController()
        registerController.delegate = self
        self.navigationController?.pushViewController(registerController, animated: true)
    }

    
    @IBAction func skipTapped(sender: UIButton) {
        PreferencesManager.savePreference(PreferencesManagerKey.showIntro, value: false)
        self.startMainStoryboard()
    }
    
    // MARK: - RegisterDelegate
    
    func onRegisterSuccess() {
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
        return pageCount
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
    }
    
    func swipeViewItemSize(swipeView: SwipeView!) -> CGSize {
        return swipeView.frame.size
    }
}