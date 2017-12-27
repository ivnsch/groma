//
//  IngredientsControllerNew.swift
//  shoppin
//
//  Created by Ivan Schuetz on 09/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import RealmSwift

import Providers

typealias IngredientsSortOption = (value: InventorySortBy, key: String)

class IngredientsControllerNew: ItemsController, UIPickerViewDataSource, UIPickerViewDelegate, ExplanationViewDelegate, SelectIngredientDataContainerControllerDelegate {

    var recipe: Recipe? {
        didSet {
            if let recipe = recipe {
                topBar.title = recipe.name
                recipeText = NSAttributedString(string: recipe.text)
                spans = recipe.textAttributeSpans.map {
                    TextSpan(start: $0.start, length: $0.length, attribute: TextAttribute(rawValue: $0.attribute)!)
                }
                updateTextView()
                delay(0.2) { // smoother animation when showing controller
                    self.load()
                }
            }
        }
    }
    
    var sortBy: IngredientsSortOption? {
        didSet {
            if let sortBy = sortBy {
                sortByButton.setTitle(sortBy.key, for: UIControlState())
            } else {
                logger.w("sortBy is nil")
            }
        }
    }
    
    @IBOutlet weak var sortByButton: UIButton!
    //    private var sortByPopup: CMPopTipView?
    fileprivate let sortByOptions: [IngredientsSortOption] = [
        (.count, trans("sort_by_count")), (.alphabetic, trans("sort_by_alphabetic"))
    ]
    
    @IBOutlet weak var topControlTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var topMenusHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var boldButton: UIButton!

    fileprivate weak var tableViewController: UITableViewController!
    
    fileprivate var explanationManager: ExplanationManager = ExplanationManager()

    fileprivate var topSelectIngredientControllerManager: ExpandableTopViewController<SelectIngredientDataContainerController>?
    
    override var isAnyTopControllerExpanded: Bool {
        return super.isAnyTopControllerExpanded || (topSelectIngredientControllerManager?.expanded ?? false)
    }
    
    fileprivate var itemsResult: Results<Ingredient>? {
        didSet {
            updateLargestLeftSideWidth()
            tableView.reloadData()
            updateEmptyUI()
        }
    }
    fileprivate var notificationToken: NotificationToken?
    
    fileprivate var maxLeftSideWidth: CGFloat = 0
    
    fileprivate var toggleButtonRotator: ToggleButtonRotator = ToggleButtonRotator()

    fileprivate var pullToAddView: MyRefreshControl?

    // To differenciate from add, etc. We need to disable the animation of top menu to bottom in this case
    fileprivate var triggeredExpandEditIngredient = false

    fileprivate var recipeText = NSAttributedString()

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
    
    fileprivate var initializedTableViewBottomInset = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        initEmptyView(line1: trans("empty_recipe_line1"), line2: trans("empty_recipe_line2"))
        
        enablePullToAdd()
        
        initExplanationManager()
        
        topSelectIngredientControllerManager = initEditIngredientControllerManager()
        
        tableView.allowsSelectionDuringEditing = true
        
        sortBy = (.alphabetic, trans("sort_by_alphabetic"))
        topMenusHeightConstraint.constant = 0

        // Automatic cell height (any value bigger than 0)
        tableView.estimatedRowHeight = 70
    }
    
    override func initTopQuickAddControllerManager() -> ExpandableTopViewController<QuickAddViewController> {
        let top = topBar.frame.height
        let manager: ExpandableTopViewController<QuickAddViewController> = ExpandableTopViewController(top: top, height: DimensionsManager.quickAddHeight, animateTableViewInset: false, parentViewController: self, tableView: tableView) {[weak self] manager in
            let controller = UIStoryboard.quickAddViewController()
            controller.delegate = self
            if let weakSelf = self {
                controller.itemType = weakSelf.quickAddItemType
            }
            controller.modus = .ingredient
            controller.list = self?.list
            manager.onDidSetTopConstraint = { [weak controller] topConstraint in
                controller?.topConstraint = topConstraint
            }
            return controller
        }
        manager.delegate = self
        return manager
    }
    
    func initEditIngredientControllerManager() -> ExpandableTopViewController<SelectIngredientDataContainerController> {
        let top = topBar.frame.height
        let manager: ExpandableTopViewController<SelectIngredientDataContainerController> = ExpandableTopViewController(top: top, height: view.height - topBar.height, animateTableViewInset: false, parentViewController: self, tableView: tableView) {[weak self] _ in
            let controller = UIStoryboard.selectIngredientDataContainerController()
            controller.delegate = self
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        toggleButtonRotator.reset(tableView, topBar: topBar)
        
        // Set inset such that newly added cells can be positioned directly below the quick add controller
        // Before of view did appear final table view height is not set. We also have to execute this only the first time because later it may be that the table view is contracted (quick add is open) which would set an incorrect inset.
        if !initializedTableViewBottomInset {
            initializedTableViewBottomInset = true
            tableView.bottomInset = tableView.height + topMenusHeightConstraint.constant - DimensionsManager.quickAddHeight - DimensionsManager.ingredientsCellHeight
        }
    }
    
    // MARK: - Pull to add
    
    func enablePullToAdd() {
        let refreshControl = PullToAddHelper.createPullToAdd(self, backgroundColor: Theme.lightGreyBackground, tableView: tableView)
        refreshControl.addTarget(self, action: #selector(onPullRefresh(_:)), for: .valueChanged)
        tableViewController.refreshControl = refreshControl
        
        pullToAddView = refreshControl
    }
    
    @objc func onPullRefresh(_ sender: UIRefreshControl) {
        sender.endRefreshing()
        _ = toggleTopAddController(false)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        toggleButtonRotator.rotateForOffset(0, topBar: topBar, scrollView: scrollView)
        pullToAddView?.updateForScrollOffset(offset: scrollView.contentOffset.y, startOffset: -40)
    }
    
    // MARK: -
    
    func load() {
        guard let recipe = recipe else {logger.e("No recipe"); return}
        guard let sortBy = sortBy else {logger.e("No sort by"); return}
        
        Prov.ingredientProvider.ingredients(recipe: recipe, sortBy: sortBy.value, successHandler {[weak self] ingredients in guard let weakSelf = self else {return}
            
            weakSelf.itemsResult = ingredients
            
            weakSelf.notificationToken = weakSelf.itemsResult?.observe {[weak self] changes in
                guard let weakSelf = self else {return}
                switch changes {
                case .initial:
                    //                        // Results are now populated and can be accessed without blocking the UI
                    //                        self.viewController.didUpdateList(reload: true)
                    logger.v("initial")
                    //                    weakSelf.productsWithQuantityController.reload()
                    //
//                    onSuccess() // TODO! productsWithQuantityController should load also lazily
                    
                    
                case .update(_, let deletions, let insertions, let modifications):
                    logger.d("deletions: \(deletions), let insertions: \(insertions), let modifications: \(modifications)")
                    
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
    
    
    override func closeTopControllers(rotateTopBarButton: Bool) {
        super.closeTopControllers(rotateTopBarButton: rotateTopBarButton)
        if topSelectIngredientControllerManager?.expanded ?? false {
            topSelectIngredientControllerManager?.expand(false)
        }
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
        
        guard let itemsResult = itemsResult else {logger.e("No result"); return}
        guard let notificationToken = notificationToken else {logger.e("No notification token"); return}
        guard let recipe = recipe else {logger.e("No recipe"); return}
        
        func onHasUnit(_ unit: Providers.Unit) {
            let quickAddIngredientInput = QuickAddIngredientInput(item: item, quantity: ingredientInput.quantity, unit: unit, fraction: ingredientInput.fraction)
            
            Prov.ingredientProvider.add(quickAddIngredientInput, recipe: recipe, ingredients: itemsResult, notificationToken: notificationToken, successHandler{[weak self] addedItem in guard let weakSelf = self else {return}
                
                guard let itemIndex = weakSelf.itemsResult?.index(of: addedItem.ingredient) else {
                    logger.e("Illegal state: Just added/updated ingredient but didn't find it in results. Or results are not set")
                    return
                }
                
//                let finalItemIndex = weakSelf.explanationManager.showExplanation ? itemIndex + 1 : itemIndex
                let finalItemIndex = false ? itemIndex + 1 : itemIndex
                let indexPath = IndexPath(row: finalItemIndex, section: 0)
                
                if addedItem.isNew {
                    weakSelf.tableView.insertRows(at: [indexPath], with: Theme.defaultRowAnimation)
                    weakSelf.tableView.scrollToRow(at: indexPath, at: .top, animated: false)
                    
                    weakSelf.updateLargestLeftSideWidth()
                    
                    if let cells = weakSelf.tableView.visibleCells as? [IngredientCell] {
                        for cell in cells {
                            cell.setRightSideOffset(offset: weakSelf.maxLeftSideWidth, animated: true)
                        }
                        
                    } else {
                        logger.e("Illegal state: Wrong cell type: \(weakSelf.tableView.visibleCells)")
                    }
                    
                } else {
                    weakSelf.update(item: addedItem.ingredient, scrollToRow: indexPath.row)
                }
                
                weakSelf.updateEmptyUI()
            })
        }
        
        Prov.unitProvider.getOrCreate(name: ingredientInput.unitName, successHandler{unit in
            onHasUnit(unit.unit)
        })
    }
    
    override func onAddRecipe(ingredientModels: [AddRecipeIngredientModel], quickAddController: QuickAddViewController) {
        fatalError("TODO!!!!!!!!!!!!!!!!!!!!")
    }
    
    override func getAlreadyHaveText(ingredient: Ingredient, _ handler: @escaping (String) -> Void) {
        fatalError("TODO!!!!!!!!!!!!!!!!!!!!")
    }
    
    override func onAddProduct(_ product: QuantifiableProduct, quantity: Float, onAddToProvider: @escaping (QuickAddAddProductResult) -> Void) {
        // Not used
    }
    
    override func onSubmitAddEditItem(_ input: ListItemInput, editingItem: Any?) {
        guard let itemsResult = itemsResult else {logger.e("No result"); return}
        guard let notificationToken = notificationToken else {logger.e("No notification token"); return}
        guard let recipe = recipe else {logger.e("No recipe"); return}
        
        
        func onEditItem(_ input: IngredientInput, editingItem: Ingredient) {
//            submittedAddOrEdit.edit = true
            Prov.ingredientProvider.update(editingItem, input: input, ingredients: itemsResult, notificationToken: notificationToken, successHandler{ [weak self] (inventoryItem, replaced) in

                if let index = itemsResult.index(of: inventoryItem) {
                    self?.tableView.updateRow(index)
                } else {
                    logger.w("Item couldn't be found after update: \(inventoryItem), results: \(itemsResult.count)", .ui)
                }
            })
        }
        
        func onAddItem(_ input: IngredientInput) {
//            submittedAddOrEdit.add = true
            
            Prov.ingredientProvider.add(input, recipe: recipe, ingredients: itemsResult, notificationToken: notificationToken, resultHandler (onSuccess: {addedItem in
                
                if addedItem.isNew {
                    self.insert(item: addedItem.ingredient, scrollToRow: true)
                    self.updateEmptyUI()
                    
                } else {
                    if let index = itemsResult.index(of: addedItem.ingredient) { // we could derive "isNew" from this but just to be 100% sure we are consistent with logic of provider
                        self.update(item: addedItem.ingredient, scrollToRow: index)
                    } else {
                        logger.e("Illegal state: Item is not new (it's an update) but was not found in results")
                    }
                }
                
            }, onError: {[weak self] result in
                self?.closeTopController()
                self?.defaultErrorHandler()(result)
            }))
        }
        
        func onHasUnit(_ unit: Providers.Unit) {
            let input = IngredientInput(name: input.name, quantity: input.quantity, category: input.section, categoryColor: input.sectionColor, brand: input.brand, unit: unit, baseQuantity: input.storeProductInput.baseQuantity)
            
            if let editingItem = editingItem as? Ingredient {
                onEditItem(input, editingItem: editingItem)
            } else {
                if editingItem == nil {
                    onAddItem(input)
                } else {
                    logger.e("Cast didn't work: \(String(describing: editingItem))")
                }
            }
        }
        
        Prov.unitProvider.getOrCreate(name: input.storeProductInput.unit, successHandler{unit in
            onHasUnit(unit.unit)
        })
    }
    
    override func onSubmitAddEditItem2(_ input: ListItemInput, editingItem: Any?, onFinish: ((QuickAddItem, Bool) -> Void)?) {
        let itemInput = ItemInput(name: input.name, categoryName: input.section, categoryColor: input.sectionColor, edible: input.edible)
        Prov.itemsProvider.addOrUpdate(input: itemInput, successHandler {item in
            let quickAddItem = QuickAddDBItem(item.0)
            onFinish?(quickAddItem, item.1)
        })
    }

    override func addEditSectionOrCategoryColor(_ name: String, handler: @escaping (UIColor?) -> Void) {
        Prov.productCategoryProvider.categoryWithName(name, successHandler {category in
            handler(category.color)
        })
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)

        guard let recipe = recipe else { logger.e("No recipe"); return }
        guard let notificationToken = notificationToken else { logger.e("No notification token"); return }

        Prov.recipeProvider.update(recipe, recipeText: recipeText.string, spans: spans, notificationToken: notificationToken, successHandler {
            logger.i("Updated recipe!", .ui)
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

    override func onAddedIngredientsSubviews() {
        super.onAddedIngredientsSubviews()
        view.bringSubview(toFront: topBar)
    }
    
    // MARK: - private
    
    // Inserts item in table view, considering the current sortBy
    func insert(item: Ingredient, scrollToRow: Bool) {
        guard let indexPath = findIndexPathForNewItem(item) else {
            logger.v("No index path for: \(item), appending"); return;
        }
        logger.v("Found index path: \(indexPath) for: \(item), sortBy: \(String(describing: sortBy))")
        tableView.insertRows(at: [indexPath], with: .top)
        
        updateEmptyUI()
        
        if scrollToRow {
            tableView.scrollToRow(at: indexPath, at: .top, animated: true)
        }
    }
    
    // TODO!!!!!!!!!!!!!!!! insert at specific place: for realm it's not a problem we just have to append to the list (the results should continue being sorted so we don't need to do anything else). but we have to insert the item in the visible rows of the table - look for its place here using the cells instead of models.
    fileprivate func findIndexPathForNewItem(_ ingredient: Ingredient) -> IndexPath? {
        
        guard let sortBy = sortBy else {logger.e("No sort by"); return nil}
        
        func findRow(_ isAfter: (Ingredient) -> Bool) -> IndexPath? {
            
            let row: Int? = {
                if let firstBiggerItemTuple = findFirstItem({isAfter($0)}) {
                    return firstBiggerItemTuple.index - 1 // insert in above the first biggest item (Note: -1 because our new item is already in the results, so we have to substract it).
                } else {
                    return itemsCount - 1 // no biggest item - our item is the biggest - return end of page (about page see warning in addOrUpdateIncrementUI)
                }
            }()
            
//            let finalRow = row.map{explanationManager.showExplanation ? $0 + 1 : $0}
            let finalRow = row.map{false ? $0 + 1 : $0}
            
            return finalRow.map{IndexPath(row: $0, section: 0)}
        }
        
        
        switch sortBy.value {
        case .count:
            return findRow({
                if $0.quantity == ingredient.quantity {
                    if $0.item.name == ingredient.item.name {
                        return $0.unit.name > ingredient.unit.name
                    } else {
                        return $0.item.name > ingredient.item.name
                    }
                } else {
                    return $0.quantity > ingredient.quantity
                }
            })
        case .alphabetic:
            return findRow({
                if $0.item.name == ingredient.item.name {
                    if $0.quantity == ingredient.quantity {
                        return $0.unit.name > ingredient.unit.name
                    } else {
                        return $0.quantity > ingredient.quantity
                    }
                } else {
                    return $0.item.name > ingredient.item.name
                }
            })
        }
    }
    
    fileprivate func updateLargestLeftSideWidth() {
        maxLeftSideWidth = findLargestLeftSideWidth()
    }
    
    fileprivate func findLargestLeftSideWidth() -> CGFloat {
        
        guard let itemsResult = itemsResult else {logger.e("No result"); return 0}

        // hardcoded numbers (fix)
        
        let quantityLabelFont = Fonts.regular
        let unitLabelFont = quantityLabelFont
        let spacingBetweenLabels: CGFloat = 9
        
        let maxInternalWidth = itemsResult.reduce(CGFloat(0)) {(maxLength, ingredient) in
            
            var length = ingredient.quantity.quantityString.size(quantityLabelFont).width + ingredient.unit.name.size(unitLabelFont).width
            length += (spacingBetweenLabels * 2)
//            length += (ingredient.fraction.isValidAndNotZeroOrOne ? 40 : 0) // TODO fraction also must be calculated using string lengths (numbers could have more than 1 digit). Width for current font and 1 digit is ~30 so hardcoding to 40 for now
            length += 40
            
            return max(maxLength, length)
        }
        
        let leftConstraint: CGFloat = 20
        let trailingConstraint: CGFloat = 20
        let categoryColorWidth: CGFloat = 5
        
        return maxInternalWidth + leftConstraint + trailingConstraint + categoryColorWidth
    }
    
    fileprivate func findFirstItem(_ f: (Ingredient) -> Bool) -> (index: Int, model: Ingredient)? {
        for itemIndex in 0..<itemsCount {
            guard let item = itemForRow(row: itemIndex) else {logger.e("Illegal state: no item for index: \(itemIndex)"); return nil}
            if f(item) {
                return (itemIndex, item)
            }
        }
        return nil
    }
    
    func itemForRow(row: Int) -> Ingredient? {
        guard row < (itemsResult?.count ?? 0) else {logger.e("Out of bounds: row: \(row), result count: \(String(describing: itemsResult?.count)). Returning nil"); return nil}
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
        
        // When top controller is edit, it's larger than the available controller's space which breaks the constraints if we animate the top, so we don't do it in this case. It doesn't make sense anyway as we will see either too litle (when edit controller doesn't have fraction section) or nothing (when it has fraction section) of it.
        if !triggeredExpandEditIngredient {
            topControlTopConstraint.constant = view.frame.height
            //topMenusHeightConstraint.constant = expand ? 0 : DimensionsManager.topMenuBarHeight
            
        } else {
            triggeredExpandEditIngredient = false // clear it
        }
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
    
    func remove(_ indexPath: IndexPath, onSuccess: @escaping VoidFunction, onError: @escaping (ProviderResult<Any>) -> Void) {
        guard let notificationToken = notificationToken else {logger.e("No notification token"); return}
        guard let itemsResult = itemsResult else {logger.e("No result"); return}

//        let row = explanationManager.showExplanation ? indexPath.row + 1 : indexPath.row
        let row = false ? indexPath.row + 1 : indexPath.row
        let updatedIndexPath = IndexPath(row: row, section: 0)
        
        Prov.ingredientProvider.delete(itemsResult[updatedIndexPath.row], ingredients: itemsResult, notificationToken: notificationToken, resultHandler(onSuccess: {[weak self] in
            self?.tableView.deleteRows(at: [updatedIndexPath], with: Theme.defaultRowAnimation)
            self?.updateEmptyUI()
            onSuccess()
            
        }, onError: {result in
            onError(result)
        }))
    }
    
    override func setEditing(_ editing: Bool, animated: Bool, tryCloseTopViewController: Bool = true) {
        super.setEditing(editing, animated: animated, tryCloseTopViewController: tryCloseTopViewController)
        tableViewController.setEditing(editing, animated: animated)

        // Switch between editable and non editable cell
        if let itemsResult = itemsResult {
            tableView.reloadRows(at: [IndexPath(row: itemsResult.count, section: 0)], with: .none)
        }
    }

    
    // MARK: - UIPicker
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return sortByOptions.count
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        sortBy = sortByOptions[row]
        load()
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = view as? UILabel ?? UILabel()
        label.font = Fonts.regularLight
        label.text = sortByOptions[row].key
        return label
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return DimensionsManager.pickerRowHeight
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
    
    
    // MARK: - SelectIngredientDataContainerControllerDelegate
        
    func onSelectIngrentTapOutsideOfContent() {
        // do nothing - for now there's no outside here (controller covers complete view)
    }
    
    func parentViewForSelectIngredientControllerAddButton() -> UIView? {
        return view
    }
    
    func onSubmitIngredientInputs(item: Item, inputs: SelectIngredientDataControllerInputs) {
        onAddIngredient(item: item, ingredientInput: inputs)
        
        topSelectIngredientControllerManager?.expand(false)
        topBar.setRightButtonModels(rightButtonsOpeningQuickAdd())
    }
    
    func submitButtonBottomOffset(parent: UIView, buttonHeight: CGFloat) -> CGFloat {
        return -(tabBarController?.tabBar.height ?? 0)
    }

    // MARK: Text editor

    fileprivate var currentTextViewSelection: NSRange?
    fileprivate var spans = [TextSpan]()
//    fileprivate let defaultRecipeTextFontSize: CGFloat = 12

    fileprivate func onTapTextViewBold() {
        if let range = currentTextViewSelection {
            updateAttribute(in: range, attribute: .bold)
        }
    }

    func updateTextView() {
        recipeText = buildAttributedString()

        if let itemsResult = itemsResult {
            if let cell = tableView.cellForRow(at: IndexPath(row: itemsResult.count, section: 0)) as? RecipeEditableTextCell {
                cell.recipeTextView.attributedText = recipeText
            }
        }
    }

    func buildAttributedString() -> NSAttributedString {
        return buildAttributedString(spans: spans, text: recipeText.string)
    }

    func buildAttributedString(spans: [TextSpan], text: String) -> NSAttributedString {
        let attributedText = NSMutableAttributedString(string: text)

        // Default attributes
        // Note: text size from storyboard
        let fullRange = NSRange(location: 0, length: text.count)
        attributedText.setAttributes([
            .font: UIFont.systemFont(ofSize: 17),
            .foregroundColor: UIColor.white
        ], range: fullRange)

        for span in spans {
            switch span.attribute {
            case .bold:
                attributedText.addAttributes([.font: UIFont.boldSystemFont(ofSize: 19)], range: span.nsRange)
//            case .fontSize(let size):
//                attributedText.setAttributes([.font: UIFont.systemFont(ofSize: size)], range: span.nsRange)
            }
        }
        return attributedText
    }

    fileprivate func updateAttribute(in selection: NSRange, attribute: TextAttribute) {

        getSpansInRange(range: selection, attributedText: recipeText, handler: { foundSpans in

            // No spans in selection! Make selection bold
            if foundSpans.isEmpty {
                spans.append(TextSpan(range: selection, attribute: attribute))
                updateTextView()
            }

            for (i, span) in spans.enumerated().reversed() {
                for foundSpan in foundSpans {
                    // Selection == span: Remove span (Note: assumes that 1. "Regular" has no spans, 2. There's only one possible attribute). In current use case this means: Selected text is bold, unbold it.
                    if foundSpan == span {
                        spans.remove(at: i)
                        updateTextView()
                    } else {
                        // No intersection between the span and the selection - nothing to do (performance - code works correctly also without this)
                        guard span.nsRange.myIntersection(range: selection).length > 0 else { return }

                        let res = span.substract(subrange: selection)
                        switch res {
                        // The selection is at the start, the end, or is the complete span
                        case .one(let range):
                            if range != span.nsRange {
                                // Remove original span
                                spans.remove(at: i)
                                // Insert shortened (or equal if selection == span) span
                                spans.insert(TextSpan(range: range, attribute: span.attribute), at: i)

                                updateTextView()
                            }
                        //The selection is in the middle - this divides the span in 2 parts, one before the selection (range1) and another after the selection (range2)
                        case .two(let range1, let range2):
                            // Remove original span
                            spans.remove(at: i)
                            // Insert part 1
                            spans.insert(TextSpan(range: range1, attribute: span.attribute), at: i)
                            // Insert part 2
                            spans.insert(TextSpan(range: range2, attribute: span.attribute), at: i)

                            updateTextView()

                        case .somethingWentWrong:
                            print("Unexpected: span: \(span), selection: \(selection)")
                            break
                        }
                    }
                }
            }
        })
    }

    // Creates subranges with found attributes in given range
    func getSpansInRange(range: NSRange, attributedText: NSAttributedString, handler: ([TextSpan]) -> Void) {
        var spans: [TextSpan] = []
        attributedText.enumerateAttribute(.font, in: range, options: []) { (font, range, stop) in
            if let f = font as? UIFont {
                if f.fontName.contains("bold") {
                    spans.append(TextSpan(start: range.location, length: range.length, attribute: .bold))
                }
            }
        }
        handler(spans)
    }

    @IBAction func onBoldTap(_ sender: UIButton) {
        onTapTextViewBold()
    }

    override func openQuickAdd(rotateTopBarButton: Bool, itemToEdit: AddEditItem?) {
        topQuickAddControllerManager?.height = DimensionsManager.quickAddHeight
        super.openQuickAdd(rotateTopBarButton: rotateTopBarButton, itemToEdit: itemToEdit)
    }
    // MARK: -
    
    deinit {
        logger.v("Deinit ingredients")
    }
}


extension IngredientsControllerNew: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return itemsCount + (explanationManager.showExplanation ? 1 : 0)
        return itemsCount + (false ? 1 : 0) + 1 // (+ 1 recipe text row)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
//        if explanationManager.showExplanation && indexPath.row == explanationManager.row { // Explanation cell
        if false && indexPath.row == explanationManager.row { // Explanation cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "defaultCell", for: indexPath)
            
            let explanationView = explanationManager.generateExplanationView()
            cell.contentView.addSubview(explanationView)
            explanationView.frame = cell.contentView.bounds
            explanationView.fillSuperview()
            explanationView.delegate = self
            explanationView.imageView.startAnimating()
            return cell
            
        } else if (itemsResult.map { $0.count == indexPath.row } ?? false) { // Recipe text cell
            if isEditing {
                let cell = tableView.dequeueReusableCell(withIdentifier: "recipeTextView", for: indexPath) as! RecipeEditableTextCell
                cell.config(recipeText: recipeText, onTextChangeHandler: { [weak self] text in
                    self?.recipeText = text
                }, onTextFocusHandler: { [weak self] focused in
                    self?.boldButton.setHiddenAnimated(!focused)
                }, selectionChangeHandler: { [weak self] range in
                    self?.currentTextViewSelection = range
                })
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "recipeTextCell", for: indexPath) as! RecipeTextCell
                cell.config(recipeText: recipeText)
                return cell
            }
        } else { // Normal cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "ingredientCell", for: indexPath) as! IngredientCell
            
//            let row = explanationManager.showExplanation ? indexPath.row - 1 : indexPath.row
            let row = false ? indexPath.row - 1 : indexPath.row
            
            if let itemsResult = itemsResult {
                cell.ingredient = itemsResult[row]
                cell.setRightSideOffset(offset: maxLeftSideWidth, animated: false)
            } else {
                logger.e("Illegal state: No item for row: \(row)")
            }
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        if explanationManager.showExplanation && indexPath.row == explanationManager.row { // Explanation cell
        if false && indexPath.row == explanationManager.row { // Explanation cell
            return explanationManager.rowHeight
        } else if indexPath.row == itemsResult?.count {
            return UITableViewAutomaticDimension
        } else {
            return DimensionsManager.ingredientsCellHeight
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            remove(indexPath, onSuccess: {}, onError: {_ in })
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isEditing {
            if itemsResult.map ({ indexPath.row == $0.count }) ?? false { // Recipe text row
                // Do nothing

            } else { // Ingredient row
                guard let itemsResult = itemsResult else {logger.e("No result"); return}

                let ingredient = itemsResult[indexPath.row]

                topQuickAddControllerManager?.height = 120
                super.openQuickAdd(itemToEdit: AddEditItem(item: ingredient))
                topBar.setRightButtonModels(rightButtonsOpeningQuickAdd())
            }

        }
    }

}
