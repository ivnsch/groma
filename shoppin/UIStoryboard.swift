//
//  Storyboard.swift
//  shoppin
//
//  Created by ischuetz on 25.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import Foundation
import UIKit

extension UIStoryboard {
    private class func mainStoryboard() -> UIStoryboard { return UIStoryboard(name: "Main", bundle: NSBundle.mainBundle()) }
    private class func listItemGroupsStoryboard() -> UIStoryboard { return UIStoryboard(name: "ListItemGroups", bundle: NSBundle.mainBundle()) }
    private class func introStoryboard() -> UIStoryboard { return UIStoryboard(name: "Intro", bundle: NSBundle.mainBundle()) }
    private class func loginStoryboard() -> UIStoryboard { return UIStoryboard(name: "Login", bundle: NSBundle.mainBundle()) }
    private class func registerStoryboard() -> UIStoryboard { return UIStoryboard(name: "Register", bundle: NSBundle.mainBundle()) }
    private class func userDetailsStoryboard() -> UIStoryboard { return UIStoryboard(name: "UserDetails", bundle: NSBundle.mainBundle()) }
    private class func forgotPasswordStoryboard() -> UIStoryboard { return UIStoryboard(name: "ForgotPassword", bundle: NSBundle.mainBundle()) }
    private class func choiceStoryboard() -> UIStoryboard { return UIStoryboard(name: "EditableChoiceModal", bundle: NSBundle.mainBundle()) }
    private class func quickAddListItemStoryboard() -> UIStoryboard { return UIStoryboard(name: "QuickAddListItem", bundle: NSBundle.mainBundle()) }
    
    // MARK: - List items
    
    class func todoItemsViewController() -> ViewController {
        return mainStoryboard().instantiateViewControllerWithIdentifier("ViewController") as! ViewController
    }
    
    class func listItemsTableViewController() -> ListItemsTableViewController {
        return mainStoryboard().instantiateViewControllerWithIdentifier("ListItemsTableViewController") as! ListItemsTableViewController
    }
    
    class func createListItemsViewController() -> AddEditListItemController {
        return mainStoryboard().instantiateViewControllerWithIdentifier("CreateListItemViewController") as! AddEditListItemController
    }
    
    
    // MARK: - Groups
    
    class func listItemsGroupsNavigationController() -> UINavigationController {
        return listItemGroupsStoryboard().instantiateViewControllerWithIdentifier("ListItemGroupsNavigationController") as! UINavigationController
    }
    
    // MARK: - General
    
    class func navigationController() -> UINavigationController {
        return mainStoryboard().instantiateViewControllerWithIdentifier("NavigationController") as! UINavigationController
    }

    class func mainTabController() -> UIViewController {
        return mainStoryboard().instantiateViewControllerWithIdentifier("MainTabController") 
    }
    
    
    // MARK: - Intro

    class func introNavController() -> UINavigationController {
        return introStoryboard().instantiateViewControllerWithIdentifier("IntroNavController") as! UINavigationController
    }
    
    class func introViewController() -> IntroViewController {
        return introStoryboard().instantiateViewControllerWithIdentifier("IntroController") as! IntroViewController
    }

    // MARK: - User
    
    class func loginViewController() -> LoginViewController {
        return loginStoryboard().instantiateViewControllerWithIdentifier("LoginController") as! LoginViewController
    }
    
    class func registerViewController() -> RegisterViewController {
        return registerStoryboard().instantiateViewControllerWithIdentifier("RegisterController") as! RegisterViewController
    }
    
    class func userDetailsViewController() -> UserDetailsViewController {
        return userDetailsStoryboard().instantiateViewControllerWithIdentifier("UserDetailsController") as! UserDetailsViewController
    }
    
    class func forgotPasswordViewController() -> ForgotPasswordViewController {
        return forgotPasswordStoryboard().instantiateViewControllerWithIdentifier("ForgotPasswordViewController") as! ForgotPasswordViewController
    }
    
    // MARK: - Modal
    class func choiceViewController() -> EditableChoiceModal {
        return choiceStoryboard().instantiateViewControllerWithIdentifier("editableChoiceModal") as! EditableChoiceModal
    }
    
    // MARK: - Lists
    class func editListsViewController() -> EditListViewController {
        return mainStoryboard().instantiateViewControllerWithIdentifier("editListsViewController") as! EditListViewController
    }
    
    // MARK: - Inventory
    class func editInventoriesViewController() -> EditInventoryViewController {
        return mainStoryboard().instantiateViewControllerWithIdentifier("editInventoriesViewController") as! EditInventoryViewController
    }

    // MARK: - History
    
    class func historyViewController() -> HistoryViewController {
        return mainStoryboard().instantiateViewControllerWithIdentifier("HistoryViewController") as! HistoryViewController
    }
    
    // MARK: - Stats
    
    class func statsViewController() -> StatsViewController {
        return mainStoryboard().instantiateViewControllerWithIdentifier("StatsViewController") as! StatsViewController
    }
    
    class func aggrByTypeTableViewController() -> AggrByTypeTableViewController {
        return mainStoryboard().instantiateViewControllerWithIdentifier("AggrByTypeTableViewController") as! AggrByTypeTableViewController
    }

    class func aggrByTypeChartViewController() -> AggrByTypeChartViewController {
        return mainStoryboard().instantiateViewControllerWithIdentifier("AggrByTypeChartViewController") as! AggrByTypeChartViewController
    }
    
    class func aggrByDateTableViewController() -> AggrByDateTableViewController {
        return mainStoryboard().instantiateViewControllerWithIdentifier("AggrByDateTableViewController") as! AggrByDateTableViewController
    }
    
    class func aggrByDateChartViewController() -> AggrByDateChartViewController {
        return mainStoryboard().instantiateViewControllerWithIdentifier("AggrByDateChartViewController") as! AggrByDateChartViewController
    }
    
    // MARK: Quick add

    class func quickAddListItemViewController() -> QuickAddListItemViewController {
        return quickAddListItemStoryboard().instantiateViewControllerWithIdentifier("QuickAddListItemViewController") as! QuickAddListItemViewController
    }
    
}