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
    private class func quickAddGroupItemStoryboard() -> UIStoryboard { return UIStoryboard(name: "QuickAddGroupItems", bundle: NSBundle.mainBundle()) }
    private class func addEditListItemStoryboard() -> UIStoryboard { return UIStoryboard(name: "AddEditListItem", bundle: NSBundle.mainBundle()) }
    private class func quickAddGroupStoryboard() -> UIStoryboard { return UIStoryboard(name: "QuickAddGroup", bundle: NSBundle.mainBundle()) }
    private class func manageProductsStoryboard() -> UIStoryboard { return UIStoryboard(name: "ManageProducts", bundle: NSBundle.mainBundle()) }
    private class func manageGroupsStoryboard() -> UIStoryboard { return UIStoryboard(name: "ManageGroups", bundle: NSBundle.mainBundle()) }
    private class func statsStoryboard() -> UIStoryboard { return UIStoryboard(name: "Stats", bundle: NSBundle.mainBundle()) }
    private class func reorderSectionsStoryboard() -> UIStoryboard { return UIStoryboard(name: "ReorderSectionTableViewController", bundle: NSBundle.mainBundle()) }
    private class func addEditListStoryboard() -> UIStoryboard { return UIStoryboard(name: "AddEditList", bundle: NSBundle.mainBundle()) }
    private class func addEditInventoryStoryboard() -> UIStoryboard { return UIStoryboard(name: "AddEditInventory", bundle: NSBundle.mainBundle()) }
    private class func addEditGroupStoryboard() -> UIStoryboard { return UIStoryboard(name: "AddEditGroupViewController", bundle: NSBundle.mainBundle()) }
    
    // TODO not used, remove
    private class func addEditSharedUsersStoryboard() -> UIStoryboard { return UIStoryboard(name: "SharedUsersViewController", bundle: NSBundle.mainBundle()) }
    
    private class func addEditInventoryItemStoryboard() -> UIStoryboard { return UIStoryboard(name: "AddEditInventoryItem", bundle: NSBundle.mainBundle()) }
    private class func scaleStoryboard() -> UIStoryboard { return UIStoryboard(name: "Scale", bundle: NSBundle.mainBundle()) }
    private class func productsWithQuantityStoryboard() -> UIStoryboard { return UIStoryboard(name: "ProductsWithQuantity", bundle: NSBundle.mainBundle()) }
    private class func shareAppStoryboard() -> UIStoryboard { return UIStoryboard(name: "ShareApp", bundle: NSBundle.mainBundle()) }
    private class func simpleInputStoryboard() -> UIStoryboard { return UIStoryboard(name: "SimpleInputPopup", bundle: NSBundle.mainBundle()) }
    private class func ratingPopupStoryboard() -> UIStoryboard { return UIStoryboard(name: "RatingPopup", bundle: NSBundle.mainBundle()) }
    private class func sharedUsersStoryboard() -> UIStoryboard { return UIStoryboard(name: "SharedUsers", bundle: NSBundle.mainBundle()) }
    private class func listItemsStoryboard() -> UIStoryboard { return UIStoryboard(name: "ListItemsControllers", bundle: NSBundle.mainBundle()) }
    
    // MARK: - List items
    
    class func todoItemsViewController() -> TodoListItemsController {
        return listItemsStoryboard().instantiateViewControllerWithIdentifier("TodoListItemsController") as! TodoListItemsController
    }
    
    class func listItemsTableViewController() -> ListItemsTableViewController {
        return listItemsStoryboard().instantiateViewControllerWithIdentifier("ListItemsTableViewController") as! ListItemsTableViewController
    }
    
    // MARK: - Groups
    
    class func listItemsGroupsNavigationController() -> UINavigationController {
        return listItemGroupsStoryboard().instantiateViewControllerWithIdentifier("ListItemGroupsNavigationController") as! UINavigationController
    }
    
    // MARK: - General
    
    class func navigationController() -> UINavigationController {
        return mainStoryboard().instantiateViewControllerWithIdentifier("NavigationController") as! UINavigationController
    }

    class func mainTabController() -> UITabBarController {
        return mainStoryboard().instantiateViewControllerWithIdentifier("MainTabController") as! UITabBarController
    }
    
    
    // MARK: - Intro
    
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

    class func userTabItemViewController() -> UserTabItemViewController {
        return mainStoryboard().instantiateViewControllerWithIdentifier("UserTabItemViewController") as! UserTabItemViewController
    }
    
    // MARK: - Modal
    class func choiceViewController() -> EditableChoiceModal {
        return choiceStoryboard().instantiateViewControllerWithIdentifier("editableChoiceModal") as! EditableChoiceModal
    }
    
//    // MARK: - Lists
//    class func editListsViewController() -> EditListViewController {
//        return mainStoryboard().instantiateViewControllerWithIdentifier("editListsViewController") as! EditListViewController
//    }
    
    
    class func inventoryItemsViewController() -> InventoryItemsController {
        return mainStoryboard().instantiateViewControllerWithIdentifier("InventoryItemsController") as! InventoryItemsController
    }
    
    class func addEditInventory() -> AddEditInventoryController {
        return addEditInventoryStoryboard().instantiateViewControllerWithIdentifier("AddEditInventoryController") as! AddEditInventoryController
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

    class func quickAddListItemViewController() -> QuickAddListItemViewController {
        return quickAddListItemStoryboard().instantiateViewControllerWithIdentifier("QuickAddListItemViewController") as! QuickAddListItemViewController
    }
    
    class func quickAddPageController() -> QuickAddPageController {
        return quickAddListItemStoryboard().instantiateViewControllerWithIdentifier("QuickAddPageController") as! QuickAddPageController
    }
    
    // MARK: Add edit list item
    
    class func addEditListItemViewController() -> AddEditListItemViewController {
        return addEditListItemStoryboard().instantiateViewControllerWithIdentifier("AddEditListItem") as! AddEditListItemViewController
    }
    
    // MARK: Manage products
    
    class func manageProductsViewController() -> ManageProductsViewController {
        return manageProductsStoryboard().instantiateViewControllerWithIdentifier("ManageProductsController") as! ManageProductsViewController
    }
    
    class func manageProductsSelectionController() -> ManageProductsSelectionController {
        return manageProductsStoryboard().instantiateViewControllerWithIdentifier("ManageProductsSelectionController") as! ManageProductsSelectionController
    }
    
    // MARK: Manage groups
    
    class func addEditGroup() -> AddEditGroupViewController {
        return addEditGroupStoryboard().instantiateViewControllerWithIdentifier("AddEditGroupController") as! AddEditGroupViewController
    }
    
    class func statsDetailsViewController() -> StatsDetailsViewController {
        return statsStoryboard().instantiateViewControllerWithIdentifier("StatsDetailsViewController") as! StatsDetailsViewController
    }
    
    class func groupItemsController() -> GroupItemsController {
        return mainStoryboard().instantiateViewControllerWithIdentifier("GroupItemsController") as! GroupItemsController
    }
    
    
    // MARK: Reorder sections
    
    class func reorderSectionTableViewController() -> ReorderSectionTableViewController {
        return reorderSectionsStoryboard().instantiateViewControllerWithIdentifier("ReorderSectionTableViewController") as! ReorderSectionTableViewController
    }
    
    // MARK: Add edit list
    
    class func addEditList() -> AddEditListController {
        return addEditListStoryboard().instantiateViewControllerWithIdentifier("AddEditListController") as! AddEditListController
    }
    
    class func listColorPicker() -> FlatColorPickerController {
        return addEditListStoryboard().instantiateViewControllerWithIdentifier("FlatColorPickerController") as! FlatColorPickerController
    }
 
    
    // MARK: Shared users
    
    // TODO not used - remove
    class func sharedUsersViewController() -> SharedUsersViewController {
        return addEditSharedUsersStoryboard().instantiateViewControllerWithIdentifier("SharedUsersViewController") as! SharedUsersViewController
    }

    class func sharedUsersController() -> SharedUsersController {
        return sharedUsersStoryboard().instantiateViewControllerWithIdentifier("SharedUsersController") as! SharedUsersController
    }
    
    // MARK: ScaleViewController
    
    class func scaleViewController() -> ScaleViewController {
        return scaleStoryboard().instantiateViewControllerWithIdentifier("ScaleViewController") as! ScaleViewController
    }
    
    // MARK: ProductsWithQuantityViewController
    
    class func productsWithQuantityViewController() -> ProductsWithQuantityViewController {
        return productsWithQuantityStoryboard().instantiateViewControllerWithIdentifier("ProductsWithQuantityViewController") as! ProductsWithQuantityViewController
    }
    
    // MARK: Share app
    
    class func shareAppViewController() -> ShareAppViewController {
        return shareAppStoryboard().instantiateViewControllerWithIdentifier("ShareAppViewController") as! ShareAppViewController
    }
    
    // MARK: Simple input
    
    class func simpleInputStoryboard() -> SimpleInputPopupController {
        return simpleInputStoryboard().instantiateViewControllerWithIdentifier("SimpleInputPopupController") as! SimpleInputPopupController
    }
    
    // MARK: Rating popup
    
    class func ratingPopupController() -> RatingPopupController {
        return ratingPopupStoryboard().instantiateViewControllerWithIdentifier("RatingPopupController") as! RatingPopupController
    }
    
    
    class func ratingProvideFeedbackController() -> RatingProvideFeedbackController {
        return ratingPopupStoryboard().instantiateViewControllerWithIdentifier("RatingProvideFeedbackController") as! RatingProvideFeedbackController
    }
    
    // MARK: Help
    // TODO now that we don't use the segues in the main storyboard for more items anymore we should put them in their own storyboards
    class func helpViewController() -> HelpViewController {
        return mainStoryboard().instantiateViewControllerWithIdentifier("HelpViewController") as! HelpViewController
    }

    // MARK: About
    // TODO now that we don't use the segues in the main storyboard for more items anymore we should put them in their own storyboards
    class func aboutViewController() -> UIViewController {
        return mainStoryboard().instantiateViewControllerWithIdentifier("AboutViewController")
    }
    
    // MARK: Settings
    // TODO now that we don't use the segues in the main storyboard for more items anymore we should put them in their own storyboards
    class func settingsViewController() -> SettingsViewController {
        return mainStoryboard().instantiateViewControllerWithIdentifier("SettingsViewController") as! SettingsViewController
    }
}