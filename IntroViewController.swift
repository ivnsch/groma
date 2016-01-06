//
//  IntroViewController.swift
//  shoppin
//
//  Created by ischuetz on 26/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved/≥.
//

import UIKit
import SwipeView

class IntroViewController: UIViewController, RegisterDelegate, LoginDelegate, SwipeViewDataSource, SwipeViewDelegate {

    @IBOutlet weak var swipeView: SwipeView!
    @IBOutlet weak var pageControl: UIPageControl!
    
    @IBOutlet weak var skipButton: UIButton!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var registerButton: UIButton!
    
    private let pageCount = 4 // later replace with array of images
    
    private let pageModels: [(key: String, imageName: String)] = [
        ("Manage your shopping lists comfortably", "intro_groceries"),
        ("Manage your inventory, get reminders to buy low stock items", "intro_inventory"),
        ("Analyse your shopping behaviour and get tips to save money", "intro_stats"),
        ("Share with others in real time", "intro_share")
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pageControl.numberOfPages = pageCount
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        self.navigationController?.navigationBarHidden = true
        
        initDatabase()
    }
    
    private func setButtonsEnabled(enabled: Bool) {
        skipButton.enabled = enabled
        loginButton.enabled = enabled
        registerButton.enabled = enabled
    }
    
    @IBAction func loginTapped(sender: UIButton) {
        let loginController = UIStoryboard.loginViewController()
        loginController.delegate = self
        self.navigationController?.pushViewController(loginController, animated: true)
    }

    private func initDatabase() {
        Providers.inventoryProvider.inventories(successHandler{[weak self] inventories in
            if let weakSelf = self {
                if inventories.isEmpty {
                    weakSelf.setButtonsEnabled(false)
                    let inventory = Inventory(uuid: NSUUID().UUIDString, name: "Home", bgColor: UIColor.flatBlueColor(), order: 0)
                    Providers.inventoryProvider.addInventory(inventory, remote: true, weakSelf.resultHandler(onSuccess: {
                        weakSelf.setButtonsEnabled(true)
                        }, onError: {result in
                        // let the user start if there's an error (we don't expect any, but just in case!)
                        // it would be very bad if user can't get past intro for whatever reason. Both adding default inventory and default products (TODO) are not critical for the app to be usable.
                        weakSelf.setButtonsEnabled(true)
                    }))
                }
            }
        })
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
    
    func onRegisterSuccess() {
        self.startMainStoryboard()
    }
    
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
        PreferencesManager.savePreference(PreferencesManagerKey.showIntro, value: false)
        self.startMainStoryboard()
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