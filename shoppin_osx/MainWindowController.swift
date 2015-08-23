//
//  MainWindowController.swift
//  shoppin
//
//  Created by ischuetz on 12/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Cocoa
import Valet

class MainWindowController: NSWindowController, LoginDelegate {

    override func windowDidLoad() {
        
//        let valet = VALValet(identifier: KeychainKeys.ValetIdentifier, accessibility: VALAccessibility.AfterFirstUnlock)
//        valet?.removeObjectForKey(KeychainKeys.token) ?? {
//            print("Error: No valet instance available, can't remove token")
//            return false
//            }()
        
        if ProviderFactory().userProvider.loggedIn {
            self.onHasUserToken()
        } else {
            let loginController = NSStoryboard.loginViewController()
            loginController.delegate = self
            self.contentViewController = loginController
        }
    }
    
    private func onHasUserToken() {
        let tabViewController = NSStoryboard.tabViewController()
        tabViewController.selectedTabViewItemIndex = 0
        self.contentViewController = tabViewController
    }
    
    func onLoginSuccess() {
        self.onHasUserToken()
    }
    
    func onRegisterFromLoginSuccess() {
        self.onHasUserToken()
    }
}
