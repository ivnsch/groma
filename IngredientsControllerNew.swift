//
//  IngredientsControllerNew.swift
//  shoppin
//
//  Created by Ivan Schuetz on 09/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import RealmSwift
import QorumLogs
import Providers

class IngredientsControllerNew: ItemsController, IngredientCellDelegate, UIPickerViewDataSource, UIPickerViewDelegate, ExplanationViewDelegate {

    var recipe: Recipe? {
        didSet {
            if let recipe = recipe {
                topBar.title = recipe.name
                load()
            }
        }
    }
    
    var sortBy: InventorySortBy = .count
    @IBOutlet weak var sortByButton: UIButton!
    //    private var sortByPopup: CMPopTipView?
    fileprivate let sortByOptions: [(value: InventorySortBy, key: String)] = [
        (.count, trans("sort_by_count")), (.alphabetic, trans("sort_by_alphabetic"))
    ]
    
    @IBOutlet weak var topControlTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var topMenusHeightConstraint: NSLayoutConstraint!

    fileprivate weak var tableViewController: UITableViewController!
    
    fileprivate var explanationManager: ExplanationManager = ExplanationManager()

    
    fileprivate var itemsResult: Results<Ingredient>?
    fileprivate var notificationToken: NotificationToken?
    
    
    override var tableView: UITableView {
        return tableViewController.tableView
    }
    
    override var isEmpty: Bool {
        return itemsResult?.count == 0
    }
    
    var itemsCount: Int {
        return itemsResult?.count ?? 0
    }
    
    override var quickAddItemType: QuickAddItemType {
        return .ingredients
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initExplanationManager()

    }
    
    override func initTopQuickAddControllerManager() -> ExpandableTopViewController<QuickAddViewController> {
        let top = topBar.frame.height
        let manager: ExpandableTopViewController<QuickAddViewController> = ExpandableTopViewController(top: top, height: DimensionsManager.quickAddHeight, animateTableViewInset: false, parentViewController: self, tableView: tableView) {[weak self] in
            let controller = UIStoryboard.quickAddViewController()
            controller.delegate = self
            if let weakSelf = self {
                controller.itemType = weakSelf.quickAddItemType
            }
            controller.list = self?.list
            return controller
        }
        manager.delegate = self
        return manager
    }
    
    fileprivate func initExplanationManager() {
        let contents = ExplanationContents(title: "Did you know?", text: "You can press and hold\nto set individual items in edit mode", imageName: "longpressedit", buttonTitle: "Got it!", frameCount: 210)
        let checker = SwipeToIncrementAlertHelperNew()
        checker.preference = .showedLongTapToEditCounter
        explanationManager.explanationContents = contents
        explanationManager.checker = checker
    }
    
    
    func load() {
        guard let recipe = recipe else {QL4("No recipe"); return}
        
        Prov.ingredientProvider.ingredients(recipe: recipe, sortBy: sortBy, successHandler {[weak self] ingredients in guard let weakSelf = self else {return}
            
            weakSelf.itemsResult = ingredients
            
            weakSelf.notificationToken = weakSelf.itemsResult?.addNotificationBlock {[weak self] changes in guard let weakSelf = self else {return}
                switch changes {
                case .initial:
                    //                        // Results are now populated and can be accessed without blocking the UI
                    //                        self.viewController.didUpdateList(reload: true)
                    QL1("initial")
                    //                    weakSelf.productsWithQuantityController.reload()
                    //
//                    onSuccess() // TODO! productsWithQuantityController should load also lazily
                    
                    
                case .update(_, let deletions, let insertions, let modifications):
                    QL2("deletions: \(deletions), let insertions: \(insertions), let modifications: \(modifications)")
                    
//                    onSuccess() // TODO! productsWithQuantityController should load also lazily
                    
                    
                    weakSelf.tableView.beginUpdates()
                    
                    //                weakSelf.productsWithQuantityController.models = recipe.ingredients.toArray() // TODO! productsWithQuantityController should load also lazily
                    
                    weakSelf.tableView.insertRows(at: insertions.map { IndexPath(row: $0, section: 0) }, with: .top)
                    weakSelf.tableView.deleteRows(at: deletions.map { IndexPath(row: $0, section: 0) }, with: .top)
                    weakSelf.tableView.reloadRows(at: modifications.map { IndexPath(row: $0, section: 0) }, with: .none)
                    weakSelf.tableView.endUpdates()
                    
                    weakSelf.updateEmptyUI()
                    
//                    if !modifications.isEmpty && weakSelf.submittedAddOrEdit.edit == true { // close only if it's an update (of current user) (explicit update, not increment which is internally also an update) (for add user may want to add multiple products)
//                        weakSelf.topQuickAddControllerManager?.expand(false)
//                        weakSelf.topQuickAddControllerManager?.controller?.onClose()
//                    }
//                    weakSelf.submittedAddOrEdit = (false, false) // now that we have processed the notification, reset flags
//                    
//                    if let firstInsertion = insertions.first { // when add, scroll to added item
//                        weakSelf.productsWithQuantityController.tableView.scrollToRow(at: IndexPath(row: firstInsertion, section: 0), at: .top, animated: true)
//                    }
                    
                case .error(let error):
                    // An error occurred while opening the Realm file on the background worker thread
                    fatalError(String(describing: error))
                }
            }
        })
        
        //                weakSelf.productsWithQuantityController.models = weakSelf.results?.toArray() ?? [] // TODO!! use generic Results in productsWithQuantityController to not have to map to array
        

    }
    
    // MARK: - QuickAddDelegate
    
    override func onCloseQuickAddTap() {
        closeTopControllers(rotateTopBarButton: true)
    }
    
    override func onAddGroup(_ group: ProductGroup, onFinish: VoidFunction?) {
        fatalError("Override")
    }
    
    override func onAddItem(_ item: Item) {
    }
    
    override func onAddIngredient(item: Item, ingredientInput: SelectIngredientDataControllerInputs) {
        
        guard let itemsResult = itemsResult else {QL4("No result"); return}
        guard let notificationToken = notificationToken else {QL4("No notification token"); return}
        guard let recipe = recipe else {QL4("No recipe"); return}

        // ingredientInput.unitName // TODO custom units
        let unit: ProductUnit = .none
        
        let quickAddIngredientInput = QuickAddIngredientInput(item: item, quantity: ingredientInput.quantity, unit: unit, fraction: ingredientInput.fraction) // for now 1 / .none

        Prov.ingredientProvider.add(quickAddIngredientInput, recipe: recipe, ingredients: itemsResult, notificationToken: notificationToken, successHandler{addedItem in

            if addedItem.isNew {
                self.insert(item: addedItem.ingredient, scrollToRow: true)

            } else {
                if let index = itemsResult.index(of: addedItem.ingredient) { // we could derive "isNew" from this but just to be 100% sure we are consistent with logic of provider
                    self.update(item: addedItem.ingredient, scrollToRow: index)
                } else {
                    QL4("Illegal state: Item is not new (it's an update) but was not found in results")
                }
            }
        })
    }
    
    override func onAddRecipe(ingredientModels: [AddRecipeIngredientModel], quickAddController: QuickAddViewController) {
        fatalError("TODO!!!!!!!!!!!!!!!!!!!!")
    }
    
    override func getAlreadyHaveText(ingredient: Ingredient, _ handler: @escaping (String) -> Void) {
        fatalError("TODO!!!!!!!!!!!!!!!!!!!!")
    }
    
    override func onAddProduct(_ product: QuantifiableProduct, quantity: Float) {
        // Not used
    }
    
    override func onSubmitAddEditItem(_ input: ListItemInput, editingItem: Any?) {
        guard let itemsResult = itemsResult else {QL4("No result"); return}
        guard let notificationToken = notificationToken else {QL4("No notification token"); return}
        guard let recipe = recipe else {QL4("No recipe"); return}
        
        
        func onEditItem(_ input: IngredientInput, editingItem: Ingredient) {
//            submittedAddOrEdit.edit = true
            Prov.ingredientProvider.update(editingItem, input: input, ingredients: itemsResult, notificationToken: notificationToken, successHandler{(inventoryItem, replaced) in
                print("replaced: \(replaced)") // TODO!!!!!!!!!!!!!!!!! do something with this?
            })
        }
        
        func onAddItem(_ input: IngredientInput) {
//            submittedAddOrEdit.add = true
            
            Prov.ingredientProvider.add(input, recipe: recipe, ingredients: itemsResult, notificationToken: notificationToken, resultHandler (onSuccess: {groupItem in
            }, onError: {[weak self] result in
                self?.closeTopController()
                self?.defaultErrorHandler()(result)
            }))
        }
        
        let input = IngredientInput(name: input.name, quantity: input.quantity, category: input.section, categoryColor: input.sectionColor, brand: input.brand, unit: input.storeProductInput.unit, baseQuantity: input.storeProductInput.baseQuantity)
        
        if let editingItem = editingItem as? Ingredient {
            onEditItem(input, editingItem: editingItem)
        } else {
            if editingItem == nil {
                onAddItem(input)
            } else {
                QL4("Cast didn't work: \(editingItem)")
            }
        }
    }

    override func addEditSectionOrCategoryColor(_ name: String, handler: @escaping (UIColor?) -> Void) {
        Prov.productCategoryProvider.categoryWithName(name, successHandler {category in
            handler(category.color)
        })
    }

    override func onRemovedSectionCategoryName(_ name: String) {
        load()
    }
    
    override func onRemovedBrand(_ name: String) {
        load()
    }
    
    override func onTopBarTitleTap() {
        back()
    }
    
    // MARK: - private
    
    // Inserts item in table view, considering the current sortBy
    func insert(item: Ingredient, scrollToRow: Bool) {
        guard let indexPath = findIndexPathForNewItem(item) else {
            QL1("No index path for: \(item), appending"); return;
        }
        QL1("Found index path: \(indexPath) for: \(item), sortBy: \(sortBy)")
        tableView.insertRows(at: [indexPath], with: .top)
        
        updateEmptyUI()
        
        if scrollToRow {
            tableView.scrollToRow(at: indexPath, at: .top, animated: true)
        }
    }
    
    // TODO!!!!!!!!!!!!!!!! insert at specific place: for realm it's not a problem we just have to append to the list (the results should continue being sorted so we don't need to do anything else). but we have to insert the item in the visible rows of the table - look for its place here using the cells instead of models.
    fileprivate func findIndexPathForNewItem(_ ingredient: Ingredient) -> IndexPath? {
        func findRow(_ isAfter: (Ingredient) -> Bool) -> IndexPath? {
            
            let row: Int? = {
                if let firstBiggerItemTuple = findFirstItem({isAfter($0)}) {
                    return firstBiggerItemTuple.index - 1 // insert in above the first biggest item (Note: -1 because our new item is already in the results, so we have to substract it).
                } else {
                    return itemsCount - 1 // no biggest item - our item is the biggest - return end of page (about page see warning in addOrUpdateIncrementUI)
                }
            }()
            return row.map{IndexPath(row: $0, section: 0)}
        }
        
        
        switch sortBy {
        case .count:
            return findRow({
                if $0.quantity == ingredient.quantity {
                    return $0.item.name > ingredient.item.name
                      // no units enabled for ingredients yet
//                        if $0.product.product.item.name == ingredient.item.name {
//                            return $0.product.unit.text > ingredient.product.unit.text
//                        } else {
//                            return $0.product.product.item.name > ingredient.product.product.item.name
//                        }
                    
                } else {
                    return $0.quantity > ingredient.quantity
                }
            })
        case .alphabetic:
            return findRow({
                if $0.item.name == ingredient.item.name {
                    return $0.quantity > ingredient.quantity
                    // no units enabled for ingredients yet
//                        if $0.quantity == ingredient.quantity {
//                            return $0.product.unit.text > ingredient.product.unit.text
//                        } else {
//                            return $0.quantity > ingredient.quantity
//                        }
                } else {
                    return $0.item.name > ingredient.item.name
                }
            })
        }
    }
    
    fileprivate func findFirstItem(_ f: (Ingredient) -> Bool) -> (index: Int, model: Ingredient)? {
        for itemIndex in 0..<itemsCount {
            guard let item = itemForRow(row: itemIndex) else {QL4("Illegal state: no item for index: \(itemIndex)"); return nil}
            if f(item) {
                return (itemIndex, item)
            }
        }
        return nil
    }
    
    func itemForRow(row: Int) -> Ingredient? {
        guard row < (itemsResult?.count ?? 0) else {QL4("Out of bounds: row: \(row), result count: \(itemsResult?.count). Returning nil"); return nil}
        return itemsResult?[row]
    }
    
    
    func update(item: Ingredient, scrollToRow index: Int?) {
        tableView.reloadData() // update with quantity change is tricky, since the sorting (by quantity) can cause the item to change positions. So we just reload the tableview
        
        if let index = index {
            let indexPath = IndexPath(row: index, section: 0)
            tableView.scrollToRow(at: indexPath, at: .top, animated: true)
        }
    }
    
    // MARK: - ExpandableTopViewControllerDelegate
    
    override func animationsForExpand(_ controller: UIViewController, expand: Bool, view: UIView) {
        // Fix top line looks slightly thicker after animation. Problem: We have to animate to min scale of 0.0001 because 0 doesn't work correctly (iOS bug) so the frame height passed here is not exactly 0, which leaves a little gap when we set it in the constraint
        topControlTopConstraint.constant = view.frame.height
        topMenusHeightConstraint.constant = expand ? 0 : DimensionsManager.topMenuBarHeight
        view.layoutIfNeeded()
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "tableViewControllerSegue" {
            tableViewController = segue.destination as? UITableViewController
            tableViewController?.tableView.dataSource = self
            tableViewController?.tableView.delegate = self

            tableViewController?.tableView.backgroundColor = Theme.defaultTableViewBGColor

            tableViewController?.tableView.reloadData()
        }
    }
    
    // MARK: - IngredientCellDelegate
    
    func onIncrementItemTap(_ cell: IngredientCell) {
        changeQuantity(cell, delta: 1)
        SwipeToIncrementAlertHelper.check(self)
    }
    
    func onDecrementItemTap(_ cell: IngredientCell) {
        changeQuantity(cell, delta: -1)
        SwipeToIncrementAlertHelper.check(self)
    }
    
    func onPanQuantityUpdate(_ cell: IngredientCell, newQuantity: Float) {
        if let model = cell.model {
            changeQuantity(cell, delta: newQuantity - model.quantity)
        } else {
            QL4("No model, can't update quantity")
        }
    }
    
    fileprivate func changeQuantity(_ cell: IngredientCell, delta: Float) {
        guard let model = cell.model else {QL4("Invalid state: Cell must have model"); return}
        
        increment(model, delta: delta, onSuccess: {updatedQuantity in
            cell.shownQuantity = updatedQuantity
        })
    }
    
    
    fileprivate func increment(_ model: Ingredient, delta: Float, onSuccess: @escaping (Float) -> Void) {
        guard let itemsResult = itemsResult else {QL4("No result"); return}
        guard let notificationToken = notificationToken else {QL4("No notification token"); return}
        guard let ingredientsRealm = itemsResult.realm else {QL4("No realm"); return}
        
        Prov.ingredientProvider.increment(model, quantity: delta, notificationToken: notificationToken, realm: ingredientsRealm, successHandler({updatedQuantity in
            onSuccess(updatedQuantity)
        }))
    }
    
    func remove(_ model: Ingredient, onSuccess: @escaping VoidFunction, onError: @escaping (ProviderResult<Any>) -> Void) {
        guard let notificationToken = notificationToken else {QL4("No notification token"); return}
        guard let itemsResult = itemsResult else {QL4("No result"); return}

        Prov.ingredientProvider.delete(model, ingredients: itemsResult, notificationToken: notificationToken, resultHandler(onSuccess: {
            onSuccess()
        }, onError: {result in
            onError(result)
        }))
    }

    
    // MARK: - UIPicker
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return sortByOptions.count
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let sortByOption = sortByOptions[row]
        sortBy = sortByOption.value
        sortByButton.setTitle(sortByOption.key, for: UIControlState())
        
        load()
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = view as? UILabel ?? UILabel()
        label.font = Fonts.regularLight
        label.text = sortByOptions[row].key
        return label
    }
    
    @IBAction func onSortByTap(_ sender: UIButton) {
        //        if let popup = self.sortByPopup {
        //            popup.dismissAnimated(true)
        //        } else {
        let popup = MyTipPopup(customView: createPicker())
        popup.presentPointing(at: sortByButton, in: view, animated: true)
        //        }
    }
    
    fileprivate func createPicker() -> UIPickerView {
        let picker = UIPickerView(frame: CGRect(x: 0, y: 0, width: 150, height: 100))
        picker.delegate = self
        picker.dataSource = self
        return picker
    }
    
    // MARK: - ExplanationViewDelegate
    
    func onGotItTap(sender: UIButton) {
        explanationManager.dontShowAgain()
        tableView.deleteRows(at: [IndexPath(row: 0, section: 0)], with: .top)
    }
}


extension IngredientsControllerNew: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return itemsCount + (explanationManager.showExplanation ? 1 : 0)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if explanationManager.showExplanation && indexPath.row == explanationManager.row { // Explanation cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "defaultCell", for: indexPath)
            
            let explanationView = explanationManager.generateExplanationView()
            cell.contentView.addSubview(explanationView)
            explanationView.frame = cell.contentView.bounds
            explanationView.fillSuperview()
            explanationView.delegate = self
            explanationView.imageView.startAnimating()
            return cell
            
        } else { // Normal cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "ingredientCell", for: indexPath) as! IngredientCell
            
            let row = explanationManager.showExplanation ? indexPath.row - 1 : indexPath.row
            
            if let itemsResult = itemsResult {
                cell.model = itemsResult[indexPath.row]
            } else {
                QL4("Illegal state: No item for row: \(row)")
            }
            
            cell.delegate = self
            
            return cell
        }

    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if explanationManager.showExplanation && indexPath.row == explanationManager.row { // Explanation cell
            return explanationManager.rowHeight
        } else {
            return DimensionsManager.defaultCellHeight
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        if isEditing {
            return .delete
        } else {
            return .none
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            guard let itemsResult = itemsResult else {QL4("Illegal state: no result in delete"); return}
            let row = explanationManager.showExplanation ? indexPath.row + 1 : indexPath.row
            remove(itemsResult[row], onSuccess: {}, onError: {_ in })
        }
    }
}
