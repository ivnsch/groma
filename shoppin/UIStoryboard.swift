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
    private class func addEditListItemStoryboard() -> UIStoryboard { return UIStoryboard(name: "AddEditListItem", bundle: NSBundle.mainBundle()) }
    private class func quickAddGroupStoryboard() -> UIStoryboard { return UIStoryboard(name: "QuickAddGroup", bundle: NSBundle.mainBundle()) }
    private class func manageProductsStoryboard() -> UIStoryboard { return UIStoryboard(name: "ManageProducts", bundle: NSBundle.mainBundle()) }
    private class func manageGroupsStoryboard() -> UIStoryboard { return UIStoryboard(name: "ManageGroups", bundle: NSBundle.mainBundle()) }
    private class func statsStoryboard() -> UIStoryboard { return UIStoryboard(name: "Stats", bundle: NSBundle.mainBundle()) }
    
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

    // MARK: Quick add

    class func quickAddViewController() -> QuickAddViewController {
        return quickAddListItemStoryboard().instantiateViewControllerWithIdentifier("QuickAddViewController") as! QuickAddViewController
    }

    // MARK: Add edit list item
    
    class func addEditListItemViewController() -> AddEditListItemViewController {
        return addEditListItemStoryboard().instantiateViewControllerWithIdentifier("AddEditListItem") as! AddEditListItemViewController
    }
    
    
    // MARK: Quick add group
    
    class func quickAddGroupViewController() -> QuickAddGroupViewController {
        return quickAddGroupStoryboard().instantiateViewControllerWithIdentifier("QuickAddGroupViewController") as! QuickAddGroupViewController
    }
    
    class func quickAddGroupItemsViewController() -> QuickAddGroupItemsViewController {
        return quickAddGroupStoryboard().instantiateViewControllerWithIdentifier("QuickAddGroupItemsViewController") as! QuickAddGroupItemsViewController
    }

    class func quickAddListItemViewController() -> QuickAddListItemViewController {
        return quickAddListItemStoryboard().instantiateViewControllerWithIdentifier("QuickAddListItemViewController") as! QuickAddListItemViewController
    }
    
    // MARK: Manage products
    
    class func manageProductsViewController() -> ManageProductsViewController {
        return manageProductsStoryboard().instantiateViewControllerWithIdentifier("ManageProductsController") as! ManageProductsViewController
    }

    class func addEditProductController() -> AddEditProductController {
        return manageProductsStoryboard().instantiateViewControllerWithIdentifier("AddEditProductController") as! AddEditProductController
    }
    
    // MARK: Manage groups
    
    class func manageGroupsController() -> ManageGroupsViewController {
        return manageGroupsStoryboard().instantiateViewControllerWithIdentifier("ManageGroupsViewController") as! ManageGroupsViewController
    }
    
    class func manageGroupsAddEditController() -> ManageGroupsAddEditController {
        return manageGroupsStoryboard().instantiateViewControllerWithIdentifier("ManageGroupsAddEditController") as! ManageGroupsAddEditController
    }
    
    class func manageGroupsSelectItemsController() -> ManageGroupsSelectItemsController {
        return manageGroupsStoryboard().instantiateViewControllerWithIdentifier("ManageGroupsSelectItemsController") as! ManageGroupsSelectItemsController
    }
    
    
    class func statsDetailsViewController() -> StatsDetailsViewController {
        return statsStoryboard().instantiateViewControllerWithIdentifier("StatsDetailsViewController") as! StatsDetailsViewController
    }
}