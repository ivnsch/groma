//
//  GroupsController.swift
//  shoppin
//
//  Created by ischuetz on 28/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import SwiftValidator

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
    
    override var isAnyTopControllerExpanded: Bool {
        return topAddEditListControllerManager?.expanded ?? false
    }
    
    fileprivate var itemsResult: RealmSwift.List<Recipe>? {
        didSet {
            tableView.reloadData()
            updateEmptyUI()
        }
    }
    fileprivate var notificationToken: NotificationToken?
    
    override var emptyViewLabels: (label1: String, label2: String) {
        return (label1: trans("empty_recipes_line1"), label2: trans("empty_recipes_line2"))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setNavTitle(trans("title_recipes"))
        
        topAddEditListControllerManager = initTopAddEditListControllerManager()

        Notification.subscribe(.realmSwapped, selector: #selector(ListsTableViewController.onRealmSwapped(_:)), observer: self)
    }

    @objc func onRealmSwapped(_ note: Foundation.Notification) {
        closeIngredientsController()
        initModels()
    }

    deinit {
        logger.v("Deinit recipes controller")
        NotificationCenter.default.removeObserver(self)
    }
    
    fileprivate func initTopAddEditListControllerManager() -> ExpandableTopViewController<AddEditGroupViewController> {
        let top = topBar.frame.height
        let expandableTopViewController: ExpandableTopViewController<AddEditGroupViewController> = ExpandableTopViewController(top: top, height: Constants.topAddContainerViewHeight, parentViewController: self, tableView: tableView) {[weak self] _ in
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
            
            self?.notificationToken = recipes.observe { changes in
                switch changes {
                case .initial:
                    //                        // Results are now populated and can be accessed without blocking the UI
                    //                        self.viewController.didUpdateList(reload: true)
                    logger.v("initial")
                    
                case .update(_, let deletions, let insertions, let modifications):
                    logger.d("deletions: \(deletions), let insertions: \(insertions), let modifications: \(modifications), count: \(String(describing: weakSelf.itemsResult?.count))")
                    
                    weakSelf.tableView.beginUpdates()
                    weakSelf.tableView.insertRows(at: insertions.map { IndexPath(row: $0, section: 0) }, with: .top)
                    weakSelf.tableView.deleteRows(at: deletions.map { IndexPath(row: $0, section: 0) }, with: .top)
                    weakSelf.tableView.reloadRows(at: modifications.map { IndexPath(row: $0, section: 0) }, with: .none)
                    weakSelf.tableView.endUpdates()
                    
//                    // TODO close only when receiving own notification, not from someone else (possible?)
//                    weakSelf.topAddEditListControllerManager?.expand(false)
//                    weakSelf.setTopBarState(.normalFromExpanded)

                    
                case .error(let error):
                    // An error occurred while opening the Realm file on the background worker thread
                    fatalError(String(describing: error))
                }
            }            
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
    
    override func initDetailController(_ cell: UITableViewCell, model: ExpandableTableViewModel) -> UIViewController {
        
        let listItemsController = UIStoryboard.ingredientsController()
        listItemsController.view.frame = view.frame
        addChildViewController(listItemsController)
        listItemsController.expandDelegate = self
        listItemsController.view.clipsToBounds = true
        
        listItemsController.onViewWillAppear = {[weak listItemsController, weak cell] in guard let weakCell = cell else {return} // FIXME crash here once when tapped on "edit"
            // Note: order of lines important here, group has to be set first for topbar dot to be positioned correctly right of the title
            listItemsController?.recipe = (model as! ExpandableTableViewRecipeModel).recipe //change
            listItemsController?.setThemeColor(weakCell.backgroundColor!)
            listItemsController?.onExpand(true)
            // This has to be after onExpand so it gets the updated navbar frame height! (which is set in positionTitleLabelLeft...)
            listItemsController?.topQuickAddControllerManager = listItemsController?.initTopQuickAddControllerManager()
        }

        return listItemsController
    }
    
    override func animationsComplete(_ wasExpanding: Bool, frontView: UIView) {
        super.animationsComplete(wasExpanding, frontView: frontView)
        if !wasExpanding {
            removeChildViewControllers()
        }
    }
    
    override func openTopController(rotateTopBarButton: Bool = true) {
        super.openTopController(rotateTopBarButton: rotateTopBarButton)
        showAddEditController(rotateTopBarButton: rotateTopBarButton)
    }
    
    override func closeTopControllers(rotateTopBarButton: Bool = true) {
        if topAddEditListControllerManager?.expanded ?? false {
            
            if topAddEditListControllerManager?.controller?.requestClose() ?? true {
                topAddEditListControllerManager?.expand(false)
                onCloseTopControllers(rotateTopBarButton: rotateTopBarButton)
            }
        }
    }
    
    // This is called after close with topbar's x as well as tapping semi transparent overlay. After everything else (rotate top button, close top controllers etc.) was done. Override for custom logic to be executed after closing top controller.
    func onFinishCloseTopControllers() {
        // optional override
    }
    
    fileprivate func showAddEditController(rotateTopBarButton: Bool = true) {
        //        SizeLimitChecker.checkGroupsSizeLimit(models.count, controller: self) {[weak self] in
        //            if let weakSelf = self {
        let expand = !(topAddEditListControllerManager?.expanded ?? true) // toggle - if for some reason variable isn't set, set expanded false (!true)
        topAddEditListControllerManager?.expand(expand)
        if rotateTopBarButton { // HACK - don't reset the buttons when we don't want to rotate because this causes the toggle button animation to "jump" (this is used on pull to add - in order to show also the submit button we would have to reset the buttons, but this causes a little jump in the X since when the table view goes a little up because of the pull anim, the X animates back a little and when we reset the buttons, setting it to its final state there's a jump). TODO We need to adjust the general logic for this, we don't need multiple nav bar buttons on each side anyways anymore so maybe we can remove all this?
            setTopBarStateForAddTap(expand, rotateTopBarButtonOnExpand: rotateTopBarButton)
        }
        //            }
        //        }
    }
    
    
    func setThemeColor(_ color: UIColor) {
        topBar.backgroundColor = color
        view.backgroundColor = UIColor.white
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func onPullToAdd() {
        showAddEditController(rotateTopBarButton: false)
    }
    
    // MARK: - EditListViewController
    //change
    func onAddGroup(_ input: AddEditSimpleItemInput) {
        guard let results = itemsResult else {logger.e("No result"); return}
        guard let notificationToken = notificationToken else {logger.e("No notification token"); return}

        let recipe = Recipe(uuid: NSUUID().uuidString, name: input.name, color: input.color)

        Prov.recipeProvider.add(recipe, recipes: results, notificationToken: notificationToken, resultHandler(onSuccess: {[weak self] in

            self?.tableView.insertRows(at: [IndexPath(row: results.count - 1, section: 0)], with: .top) // Note -1 as at this point the new item is already inserted in results

            self?.topAddEditListControllerManager?.expand(false)
            self?.setTopBarState(.normalFromExpanded)
            self?.updateEmptyUI()

            }, onError: {[weak self] result in guard let weakSelf = self else { return }
                if result.status == .nameAlreadyExists {
                    AlertPopup.show(title: trans("popup_title_error"), message: trans("error_recipe_already_exists", recipe.name), controller: weakSelf)
                } else {
                    weakSelf.defaultErrorHandler()(result)
                }
                weakSelf.onGroupAddOrUpdateError(recipe)
            }
        ))
    }
    
    func onUpdateGroup(_ input: AddEditSimpleItemInput, item: SimpleFirstLevelListItem, index: Int) {
        guard let results = itemsResult else {logger.e("No result"); return}
        guard let notificationToken = notificationToken else {logger.e("No notification token"); return}
        
        let recipe = item as! Recipe
        let recipeInput = RecipeInput(name: input.name, color: input.color)
        
        Prov.recipeProvider.update(recipe, input: recipeInput, recipes: results, notificationToken: notificationToken, resultHandler(onSuccess: {
            
            var row: Int?
            for (index, item) in results.enumerated() {
                if item.uuid == recipe.uuid {
                    row = index
                }
            }
            
            if let row = row {
                self.tableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .none)
            } else {
                logger.e("Invalid state: can't find list: \(recipe)")
            }
            
        }, onErrorAdditional: {[weak self] result in
            self?.onGroupAddOrUpdateError(recipe)
            }
        ))
        
        topAddEditListControllerManager?.expand(false)
        setTopBarState(.normalFromExpanded)
    }
    
    fileprivate func onGroupAddOrUpdateError(_ recipe: Recipe) {
        initModels()
        // If the user quickly after adding the group opened its group items controller, close it.
        for childViewController in childViewControllers {
            if let ingredientsController = childViewController as? IngredientsControllerNew {
                if (ingredientsController.recipe.map{$0.same(recipe)}) ?? false {
                    ingredientsController.back()
                }
            }
        }
    }

    fileprivate func closeIngredientsController() {
        for childViewController in childViewControllers {
            if let todoListItemController = childViewController as? IngredientsControllerNew {
                todoListItemController.back()
            }
        }
    }

    // MARK: - ExpandableTopViewControllerDelegate
    
    func animationsForExpand(_ controller: UIViewController, expand: Bool, view: UIView) {
    }
    
    override func onExpandableClose() {
        super.onExpandableClose()
        setTopBarState(.normalFromExpanded)
    }
    
    
    // New
    
    override func loadModels(onSuccess: @escaping () -> Void) {
        // TODO!!!!!!!!!!!!! on success. Is also this method actually necessary?
        initModels()
    }
    
    override func itemForRow(row: Int) -> ExpandableTableViewModel? {
        guard let itemsResult = itemsResult else {logger.e("No result"); return nil}
        
        return ExpandableTableViewRecipeModel(recipe: itemsResult[row])
    }
    
    override var itemsCount: Int? {
        guard let itemsResult = itemsResult else { return nil }
        
        return itemsResult.count
    }
    
    override func deleteItem(index: Int) {
        guard let itemsResult = itemsResult else {logger.e("No result"); return}
        guard let notificationToken = notificationToken else {logger.e("No notification token"); return}
        
        Prov.recipeProvider.delete(index: index, recipes: itemsResult, notificationToken: notificationToken, resultHandler(onSuccess: {[weak self] in
            self?.updateEmptyUI()
        }, onErrorAdditional: {[weak self] result in
            self?.initModels()
            }
        ))
    }
    
    override func moveItem(from: Int, to: Int) {
        guard let itemsResult = itemsResult else {logger.e("No result"); return}
        guard let notificationToken = notificationToken else {logger.e("No notification token"); return}
        
        Prov.recipeProvider.move(from: from, to: to, recipes: itemsResult, notificationToken: notificationToken, successHandler {
        })
    }
}

