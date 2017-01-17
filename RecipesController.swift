//
//  GroupsController.swift
//  shoppin
//
//  Created by ischuetz on 28/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import SwiftValidator
import QorumLogs
import RealmSwift
import Providers

class ExpandableTableViewRecipeModel: ExpandableTableViewModel {
    
    let recipe: Recipe
    
    init (recipe: Recipe) {
        self.recipe = recipe
    }
    
    override var name: String {
        return recipe.name
    }
    
    override var bgColor: UIColor {
        return recipe.color
    }
    
    override var users: [DBSharedUser] {
        return []
    }
    
    override func same(_ rhs: ExpandableTableViewModel) -> Bool {
        return recipe.same((rhs as! ExpandableTableViewRecipeModel).recipe)
    }
    
    override var debugDescription: String {
        return recipe.debugDescription
    }
}

extension Recipe: SimpleFirstLevelListItem {
}

class RecipesController: ExpandableItemsTableViewController, AddEditGroupControllerDelegate, ExpandableTopViewControllerDelegate {
    
    fileprivate var editButton: UIBarButtonItem!
    
    var expandDelegate: Foo?
    
    fileprivate var topAddEditListControllerManager: ExpandableTopViewController<AddEditGroupViewController>?
    
    fileprivate var itemsResult: RealmSwift.List<Recipe>?
    fileprivate var notificationToken: NotificationToken?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setNavTitle(trans("title_recipes"))
        
        topAddEditListControllerManager = initTopAddEditListControllerManager()
    }
    
    deinit {
        QL1("Deinit recipes controller")
        NotificationCenter.default.removeObserver(self)
    }
    
    fileprivate func initTopAddEditListControllerManager() -> ExpandableTopViewController<AddEditGroupViewController> {
        let top = topBar.frame.height
        let expandableTopViewController: ExpandableTopViewController<AddEditGroupViewController> = ExpandableTopViewController(top: top, height: Constants.topAddContainerViewHeight, parentViewController: self, tableView: tableView) {[weak self] in
            let controller = UIStoryboard.addEditGroup()
            controller.delegate = self
            controller.view.clipsToBounds = false
            return controller
        }
        expandableTopViewController.delegate = self
        return expandableTopViewController
    }
    
    
    override func initModels() {
        Prov.recipeProvider.recipes(sortBy: .order, successHandler{[weak self] recipes in guard let weakSelf = self else {return}
            
            weakSelf.itemsResult = recipes
            
            self?.notificationToken = recipes.addNotificationBlock { changes in
                switch changes {
                case .initial:
                    //                        // Results are now populated and can be accessed without blocking the UI
                    //                        self.viewController.didUpdateList(reload: true)
                    QL1("initial")
                    
                case .update(_, let deletions, let insertions, let modifications):
                    QL2("deletions: \(deletions), let insertions: \(insertions), let modifications: \(modifications), count: \(weakSelf.itemsResult?.count)")
                    
                    weakSelf.tableView.beginUpdates()
                    
                    weakSelf.models = weakSelf.itemsResult!.map{ExpandableTableViewRecipeModel(recipe: $0)}
                    weakSelf.tableView.insertRows(at: insertions.map { IndexPath(row: $0, section: 0) }, with: .top)
                    weakSelf.tableView.deleteRows(at: deletions.map { IndexPath(row: $0, section: 0) }, with: .top)
                    weakSelf.tableView.reloadRows(at: modifications.map { IndexPath(row: $0, section: 0) }, with: .none)
                    weakSelf.tableView.endUpdates()
                    
                    // TODO close only when receiving own notification, not from someone else (possible?)
                    weakSelf.topAddEditListControllerManager?.expand(false)
                    weakSelf.setTopBarState(.normalFromExpanded)
                    
                    
                case .error(let error):
                    // An error occurred while opening the Realm file on the background worker thread
                    fatalError(String(describing: error))
                }
            }
            
            weakSelf.models = recipes.map{ExpandableTableViewRecipeModel(recipe: $0)} // TODO use results!
            self?.debugItems()
        })
    }
    
    override func onSubmitTap() {
        topAddEditListControllerManager?.controller?.submit()
    }
    
    
    override func onSelectCellInEditMode(_ model: ExpandableTableViewModel, index: Int) {
        super.onSelectCellInEditMode(model, index: index)
        topAddEditListControllerManager?.expand(true)
        topAddEditListControllerManager?.controller?.modelToEdit = ((model as! ExpandableTableViewRecipeModel).recipe, index)
    }
    
    override func topControllerIsExpanded() -> Bool {
        return topAddEditListControllerManager?.expanded ?? false
    }
    
    override func onReorderedModels(from: Int, to: Int) {
        guard let itemsResult = itemsResult else {QL4("No result"); return}
        guard let notificationToken = notificationToken else {QL4("No notification token"); return}
        
        Prov.recipeProvider.move(from: from, to: to, recipes: itemsResult, notificationToken: notificationToken, successHandler {
        })
    }
    
    override func onRemoveModel(_ model: ExpandableTableViewModel, index: Int) {
        guard let itemsResult = itemsResult else {QL4("No result"); return}
        guard let notificationToken = notificationToken else {QL4("No notification token"); return}
        
        Prov.recipeProvider.delete(index: index, recipes: itemsResult, notificationToken: notificationToken, resultHandler(onSuccess: {
        }, onErrorAdditional: {[weak self] result in
            self?.initModels()
            }
        ))
    }
    
    override func initDetailController(_ cell: UITableViewCell, model: ExpandableTableViewModel) -> UIViewController {
         return UIViewController()
        
        
//        let listItemsController = UIStoryboard.groupItemsController()
//        listItemsController.view.frame = view.frame
//        addChildViewController(listItemsController)
//        listItemsController.expandDelegate = self
//        listItemsController.view.clipsToBounds = true
//        
//        listItemsController.onViewWillAppear = {[weak listItemsController, weak cell] in guard let weakCell = cell else {return} // FIXME crash here once when tapped on "edit"
//            // Note: order of lines important here, group has to be set first for topbar dot to be positioned correctly right of the title
//            listItemsController?.group = (model as! ExpandableTableViewRecipeModel).recipe //change
//            listItemsController?.setThemeColor(weakCell.backgroundColor!)
//            listItemsController?.onExpand(true)
//        }
//        
//        listItemsController.onViewDidAppear = {[weak listItemsController] in
//            listItemsController?.onExpand(true)
//        }
//        
//        return listItemsController
    }
    
    override func animationsComplete(_ wasExpanding: Bool, frontView: UIView) {
        super.animationsComplete(wasExpanding, frontView: frontView)
        if !wasExpanding {
            removeChildViewControllers()
        }
    }
    
    override func onAddTap(_ rotateTopBarButton: Bool = true) {
        super.onAddTap()
        SizeLimitChecker.checkGroupsSizeLimit(models.count, controller: self) {[weak self] in
            if let weakSelf = self {
                let expand = !(weakSelf.topAddEditListControllerManager?.expanded ?? true) // toggle - if for some reason variable isn't set, set expanded false (!true)
                weakSelf.topAddEditListControllerManager?.expand(expand)
                if rotateTopBarButton { // HACK - don't reset the buttons when we don't want to rotate because this causes the toggle button animation to "jump" (this is used on pull to add - in order to show also the submit button we would have to reset the buttons, but this causes a little jump in the X since when the table view goes a little up because of the pull anim, the X animates back a little and when we reset the buttons, setting it to its final state there's a jump). TODO We need to adjust the general logic for this, we don't need multiple nav bar buttons on each side anyways anymore so maybe we can remove all this?
                    weakSelf.setTopBarStateForAddTap(expand, rotateTopBarButtonOnExpand: rotateTopBarButton)
                }
            }
        }
    }
    
    func setThemeColor(_ color: UIColor) {
        topBar.backgroundColor = color
        view.backgroundColor = UIColor.white
    }
    
    fileprivate func debugItems() {
        if QorumLogs.minimumLogLevelShown < 2 {
            print("Recipes:")
            (models as! [ExpandableTableViewRecipeModel]).forEach{print("\($0.recipe.debugDescription)")}
        }
    }
    
    // We have to do this programmatically since our storyboard does not contain the nav controller, which is in the main storyboard ("more"), thus the nav bar in our storyboard is not used. Maybe there's a better solution - no time now
    fileprivate func initNavBar(_ actions: [UIBarButtonSystemItem]) {
        navigationItem.title = trans("title_products")
        
        var buttons: [UIBarButtonItem] = []
        
        for action in actions {
            switch action {
            case .add:
                let button = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(ExpandableItemsTableViewController.onAddTap(_:)))
                buttons.append(button)
            case .edit:
                let button = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(ExpandableItemsTableViewController.onEditTap(_:)))
                self.editButton = button
                buttons.append(button)
            default: break
            }
        }
        navigationItem.rightBarButtonItems = buttons
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func onPullToAdd() {
        onAddTap(false)
    }
    
    // MARK: - EditListViewController
    //change
    func onAddGroup(_ input: AddEditSimpleItemInput) {
        guard let results = itemsResult else {QL4("No result"); return}
        guard let notificationToken = notificationToken else {QL4("No notification token"); return}

        tableView.insertRows(at: [IndexPath(row: results.count, section: 0)], with: .top)
        
        let recipe = Recipe(uuid: NSUUID().uuidString, name: input.name, color: input.color)

        Prov.recipeProvider.add(recipe, recipes: results, notificationToken: notificationToken, resultHandler(onSuccess: {
        }, onErrorAdditional: {[weak self] result in
            self?.onGroupAddOrUpdateError(recipe)
            }
        ))
    }
    
    func onUpdateGroup(_ input: AddEditSimpleItemInput, item: SimpleFirstLevelListItem, index: Int) {
        guard let results = itemsResult else {QL4("No result"); return}
        guard let notificationToken = notificationToken else {QL4("No notification token"); return}
        
        let recipe = item as! Recipe
        let recipeInput = RecipeInput(name: input.name, color: input.color)
        
        Prov.recipeProvider.update(recipe, input: recipeInput, recipes: results, notificationToken: notificationToken, resultHandler(onSuccess: {
        }, onErrorAdditional: {[weak self] result in
            self?.onGroupAddOrUpdateError(recipe)
            }
        ))
    }
    
    fileprivate func onGroupAddOrUpdateError(_ recipe: Recipe) {
        initModels()
        // If the user quickly after adding the group opened its group items controller, close it.
        for childViewController in childViewControllers {
            // TODO ingredients controller
//            if let groupItemsController = childViewController as? GroupItemsController {
//                if (groupItemsController.group.map{$0.same(group)}) ?? false {
//                    groupItemsController.back()
//                }
//            }
        }
    }
    
    // MARK: - ExpandableTopViewControllerDelegate
    
    func animationsForExpand(_ controller: UIViewController, expand: Bool, view: UIView) {
    }
    
    override func onExpandableClose() {
        super.onExpandableClose()
        setTopBarState(.normalFromExpanded)
    }
}

