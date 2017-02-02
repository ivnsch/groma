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
    fileprivate class func mainStoryboard() -> UIStoryboard { return UIStoryboard(name: "Main", bundle: Bundle.main) }
    fileprivate class func listItemGroupsStoryboard() -> UIStoryboard { return UIStoryboard(name: "ProductGroups", bundle: Bundle.main) }
    fileprivate class func introStoryboard() -> UIStoryboard { return UIStoryboard(name: "Intro", bundle: Bundle.main) }
    fileprivate class func loginStoryboard() -> UIStoryboard { return UIStoryboard(name: "Login", bundle: Bundle.main) }
    fileprivate class func registerStoryboard() -> UIStoryboard { return UIStoryboard(name: "Register", bundle: Bundle.main) }
    fileprivate class func userDetailsStoryboard() -> UIStoryboard { return UIStoryboard(name: "UserDetails", bundle: Bundle.main) }
    fileprivate class func forgotPasswordStoryboard() -> UIStoryboard { return UIStoryboard(name: "ForgotPassword", bundle: Bundle.main) }
    fileprivate class func choiceStoryboard() -> UIStoryboard { return UIStoryboard(name: "EditableChoiceModal", bundle: Bundle.main) }
    fileprivate class func quickAddListItemStoryboard() -> UIStoryboard { return UIStoryboard(name: "QuickAddListItem", bundle: Bundle.main) }
    fileprivate class func quickAddGroupItemStoryboard() -> UIStoryboard { return UIStoryboard(name: "QuickAddGroupItems", bundle: Bundle.main) }
    fileprivate class func addEditListItemStoryboard() -> UIStoryboard { return UIStoryboard(name: "AddEditListItem", bundle: Bundle.main) }
    fileprivate class func quickAddGroupStoryboard() -> UIStoryboard { return UIStoryboard(name: "QuickAddGroup", bundle: Bundle.main) }
    fileprivate class func manageProductsStoryboard() -> UIStoryboard { return UIStoryboard(name: "ManageProducts", bundle: Bundle.main) }
    fileprivate class func manageGroupsStoryboard() -> UIStoryboard { return UIStoryboard(name: "ManageGroups", bundle: Bundle.main) }
    fileprivate class func statsStoryboard() -> UIStoryboard { return UIStoryboard(name: "Stats", bundle: Bundle.main) }
    fileprivate class func reorderSectionsStoryboard() -> UIStoryboard { return UIStoryboard(name: "ReorderSectionTableViewController", bundle: Bundle.main) }
    fileprivate class func addEditListStoryboard() -> UIStoryboard { return UIStoryboard(name: "AddEditList", bundle: Bundle.main) }
    fileprivate class func addEditInventoryStoryboard() -> UIStoryboard { return UIStoryboard(name: "AddEditInventory", bundle: Bundle.main) }
    fileprivate class func addEditGroupStoryboard() -> UIStoryboard { return UIStoryboard(name: "AddEditGroupViewController", bundle: Bundle.main) }
    
    // TODO not used, remove
    fileprivate class func addEditSharedUsersStoryboard() -> UIStoryboard { return UIStoryboard(name: "SharedUsersViewController", bundle: Bundle.main) }
    
    fileprivate class func addEditInventoryItemStoryboard() -> UIStoryboard { return UIStoryboard(name: "AddEditInventoryItem", bundle: Bundle.main) }
    fileprivate class func scaleStoryboard() -> UIStoryboard { return UIStoryboard(name: "Scale", bundle: Bundle.main) }
    fileprivate class func productsWithQuantityStoryboard() -> UIStoryboard { return UIStoryboard(name: "ProductsWithQuantity", bundle: Bundle.main) }
    fileprivate class func shareAppStoryboard() -> UIStoryboard { return UIStoryboard(name: "ShareApp", bundle: Bundle.main) }
    fileprivate class func simpleInputStoryboard() -> UIStoryboard { return UIStoryboard(name: "SimpleInputPopup", bundle: Bundle.main) }
    fileprivate class func ratingPopupStoryboard() -> UIStoryboard { return UIStoryboard(name: "RatingPopup", bundle: Bundle.main) }
    fileprivate class func sharedUsersStoryboard() -> UIStoryboard { return UIStoryboard(name: "SharedUsers", bundle: Bundle.main) }
    fileprivate class func listItemsStoryboard() -> UIStoryboard { return UIStoryboard(name: "ListItemsControllers", bundle: Bundle.main) }
    
    // MARK: - List items
    
    class func todoItemsViewController() -> TodoListItemsController {
        return listItemsStoryboard().instantiateViewController(withIdentifier: "TodoListItemsController") as! TodoListItemsController
    }
    class func todoItemsViewControllerNew() -> TodoListItemsControllerNew {
        return listItemsStoryboard().instantiateViewController(withIdentifier: "TodoListItemsController") as! TodoListItemsControllerNew
    }
    
    class func listItemsTableViewController() -> ListItemsTableViewController {
        return listItemsStoryboard().instantiateViewController(withIdentifier: "ListItemsTableViewController") as! ListItemsTableViewController
    }
    class func listItemsTableViewControllerNew() -> ListItemsTableViewControllerNew {
        // TODO
        return listItemsStoryboard().instantiateViewController(withIdentifier: "ListItemsTableViewController") as! ListItemsTableViewControllerNew
    }
    
    // MARK: - Groups
    
    class func listItemsGroupsNavigationController() -> UINavigationController {
        return listItemGroupsStoryboard().instantiateViewController(withIdentifier: "ProductGroupsNavigationController") as! UINavigationController
    }
    
    // MARK: - General
    
    class func navigationController() -> UINavigationController {
        return mainStoryboard().instantiateViewController(withIdentifier: "NavigationController") as! UINavigationController
    }

    class func mainTabController() -> UITabBarController {
        return mainStoryboard().instantiateViewController(withIdentifier: "MainTabController") as! UITabBarController
    }
    
    
    // MARK: - Intro
    
    class func introViewController() -> IntroViewController {
        return introStoryboard().instantiateViewController(withIdentifier: "IntroController") as! IntroViewController
    }

    // MARK: - User
    
    class func loginViewController() -> LoginViewController {
        return loginStoryboard().instantiateViewController(withIdentifier: "LoginController") as! LoginViewController
    }
    
    class func registerViewController() -> RegisterViewController {
        return registerStoryboard().instantiateViewController(withIdentifier: "RegisterController") as! RegisterViewController
    }
    
    class func userDetailsViewController() -> UserDetailsViewController {
        return userDetailsStoryboard().instantiateViewController(withIdentifier: "UserDetailsController") as! UserDetailsViewController
    }
    
    class func forgotPasswordViewController() -> ForgotPasswordViewController {
        return forgotPasswordStoryboard().instantiateViewController(withIdentifier: "ForgotPasswordViewController") as! ForgotPasswordViewController
    }

    class func userTabItemViewController() -> UserTabItemViewController {
        return mainStoryboard().instantiateViewController(withIdentifier: "UserTabItemViewController") as! UserTabItemViewController
    }
    
    // MARK: - Modal
    class func choiceViewController() -> EditableChoiceModal {
        return choiceStoryboard().instantiateViewController(withIdentifier: "editableChoiceModal") as! EditableChoiceModal
    }
    
//    // MARK: - Lists
//    class func editListsViewController() -> EditListViewController {
//        return mainStoryboard().instantiateViewControllerWithIdentifier("editListsViewController") as! EditListViewController
//    }
    
    
    class func inventoryItemsViewController() -> InventoryItemsController {
        return mainStoryboard().instantiateViewController(withIdentifier: "InventoryItemsController") as! InventoryItemsController
    }
    
    class func addEditInventory() -> AddEditInventoryController {
        return addEditInventoryStoryboard().instantiateViewController(withIdentifier: "AddEditInventoryController") as! AddEditInventoryController
    }
    
    // MARK: - History
    
    class func historyViewController() -> HistoryViewController {
        return mainStoryboard().instantiateViewController(withIdentifier: "HistoryViewController") as! HistoryViewController
    }
    
    // MARK: - Stats
    
    class func statsViewController() -> StatsViewController {
        return mainStoryboard().instantiateViewController(withIdentifier: "StatsViewController") as! StatsViewController
    }

    // MARK: Quick add

    class func quickAddViewController() -> QuickAddViewController {
        return quickAddListItemStoryboard().instantiateViewController(withIdentifier: "QuickAddViewController") as! QuickAddViewController
    }

    class func quickAddListItemViewController() -> QuickAddListItemViewController {
        return quickAddListItemStoryboard().instantiateViewController(withIdentifier: "QuickAddListItemViewController") as! QuickAddListItemViewController
    }
    
    class func quickAddPageController() -> QuickAddPageController {
        return quickAddListItemStoryboard().instantiateViewController(withIdentifier: "QuickAddPageController") as! QuickAddPageController
    }
    
    // MARK: Add edit list item
    
    class func addEditListItemViewController() -> AddEditListItemViewController {
        return addEditListItemStoryboard().instantiateViewController(withIdentifier: "AddEditListItem") as! AddEditListItemViewController
    }
    
    // MARK: Manage products
    
    class func manageProductsViewController() -> ManageProductsViewController {
        return manageProductsStoryboard().instantiateViewController(withIdentifier: "ManageProductsController") as! ManageProductsViewController
    }
    
    class func manageProductsSelectionController() -> ManageProductsSelectionController {
        return manageProductsStoryboard().instantiateViewController(withIdentifier: "ManageProductsSelectionController") as! ManageProductsSelectionController
    }
    
    // MARK: Manage groups
    
    class func addEditGroup() -> AddEditGroupViewController {
        return addEditGroupStoryboard().instantiateViewController(withIdentifier: "AddEditGroupController") as! AddEditGroupViewController
    }
    
    class func statsDetailsViewController() -> StatsDetailsViewController {
        return statsStoryboard().instantiateViewController(withIdentifier: "StatsDetailsViewController") as! StatsDetailsViewController
    }
    
    class func groupItemsController() -> GroupItemsController {
        return mainStoryboard().instantiateViewController(withIdentifier: "GroupItemsController") as! GroupItemsController
    }
    
    
    // MARK: Reorder sections
    
    class func reorderSectionTableViewController() -> ReorderSectionTableViewController {
        return reorderSectionsStoryboard().instantiateViewController(withIdentifier: "ReorderSectionTableViewController") as! ReorderSectionTableViewController
    }
    
    class func reorderSectionTableViewControllerNew() -> ReorderSectionTableViewControllerNew {
        return reorderSectionsStoryboard().instantiateViewController(withIdentifier: "ReorderSectionTableViewController") as! ReorderSectionTableViewControllerNew
    }
    
    // MARK: Add edit list
    
    class func addEditList() -> AddEditListController {
        return addEditListStoryboard().instantiateViewController(withIdentifier: "AddEditListController") as! AddEditListController
    }
    
    class func listColorPicker() -> FlatColorPickerController {
        return addEditListStoryboard().instantiateViewController(withIdentifier: "FlatColorPickerController") as! FlatColorPickerController
    }
 
    
    // MARK: Shared users
    
    // TODO not used - remove
    class func sharedUsersViewController() -> SharedUsersViewController {
        return addEditSharedUsersStoryboard().instantiateViewController(withIdentifier: "SharedUsersViewController") as! SharedUsersViewController
    }

    class func sharedUsersController() -> SharedUsersController {
        return sharedUsersStoryboard().instantiateViewController(withIdentifier: "SharedUsersController") as! SharedUsersController
    }
    
    // MARK: ScaleViewController
    
    class func scaleViewController() -> ScaleViewController {
        return scaleStoryboard().instantiateViewController(withIdentifier: "ScaleViewController") as! ScaleViewController
    }
    
    // MARK: ProductsWithQuantityViewController
    
    // TODO: remove
    class func productsWithQuantityViewController() -> ProductsWithQuantityViewController {
        return productsWithQuantityStoryboard().instantiateViewController(withIdentifier: "ProductsWithQuantityViewController") as! ProductsWithQuantityViewController
    }
    
    class func productsWithQuantityViewControllerNew() -> ProductsWithQuantityViewControllerNew {
        return productsWithQuantityStoryboard().instantiateViewController(withIdentifier: "ProductsWithQuantityViewControllerNew") as! ProductsWithQuantityViewControllerNew
    }
    
    // MARK: Share app
    
    class func shareAppViewController() -> ShareAppViewController {
        return shareAppStoryboard().instantiateViewController(withIdentifier: "ShareAppViewController") as! ShareAppViewController
    }
    
    // MARK: Simple input
    
    class func simpleInputStoryboard() -> SimpleInputPopupController {
        return simpleInputStoryboard().instantiateViewController(withIdentifier: "SimpleInputPopupController") as! SimpleInputPopupController
    }
    
    // MARK: Rating popup
    
    class func ratingPopupController() -> RatingPopupController {
        return ratingPopupStoryboard().instantiateViewController(withIdentifier: "RatingPopupController") as! RatingPopupController
    }
    
    
    class func ratingProvideFeedbackController() -> RatingProvideFeedbackController {
        return ratingPopupStoryboard().instantiateViewController(withIdentifier: "RatingProvideFeedbackController") as! RatingProvideFeedbackController
    }
    
    // MARK: Help
    // TODO now that we don't use the segues in the main storyboard for more items anymore we should put them in their own storyboards
    class func helpViewController() -> HelpViewController {
        return mainStoryboard().instantiateViewController(withIdentifier: "HelpViewController") as! HelpViewController
    }

    // MARK: About
    // TODO now that we don't use the segues in the main storyboard for more items anymore we should put them in their own storyboards
    class func aboutViewController() -> UIViewController {
        return mainStoryboard().instantiateViewController(withIdentifier: "AboutViewController")
    }
    
    // MARK: Settings
    // TODO now that we don't use the segues in the main storyboard for more items anymore we should put them in their own storyboards
    class func settingsViewController() -> SettingsViewController {
        return mainStoryboard().instantiateViewController(withIdentifier: "SettingsViewController") as! SettingsViewController
    }
    
    // MARK: Ingredients
    
    class func ingredientsController() -> IngredientsController {
        return mainStoryboard().instantiateViewController(withIdentifier: "IngredientsController") as! IngredientsController
    }
}
