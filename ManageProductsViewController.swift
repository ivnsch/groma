//
//  ManageProductsViewController.swift
//  shoppin
//
//  Created by ischuetz on 27/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import SwiftValidator
import CMPopTipView
import QorumLogs
import RealmSwift
import Providers

class ManageProductsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, QuickAddDelegate, ExpandableTopViewControllerDelegate, UIPickerViewDataSource, UIPickerViewDelegate, UIGestureRecognizerDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var searchBoxHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var topControlTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var searchBoxMarginTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var searchBoxMarginBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var searchBar: UITextField!

    
    fileprivate var searchText: String = "" {
        didSet {
            loadProducts()
        }
    }
    
    fileprivate var products: Results<QuantifiableProduct>? // For now quantifiable products - maybe later we should show only products and quantifiable products grouped inside
    fileprivate var notificationToken: NotificationToken?

    var sortBy: ProductSortBy = .fav {
        didSet {
            if sortBy != oldValue {
                if let option = sortByOption(sortBy) {
                    sortByButton.setTitle(option.key, for: UIControlState())
                } else {
                    QL3("No option for \(sortBy)")
                }
                loadProducts()
            }
        }
    }
    @IBOutlet weak var sortByButton: UIButton!
    fileprivate var sortByPopup: CMPopTipView?
    fileprivate let sortByOptions: [(value: ProductSortBy, key: String)] = [
        (.fav, trans("sort_by_usage")), (.alphabetic, trans("sort_by_alphabetic"))
    ]
    
    fileprivate let toggleButtonInactiveAction = FLoatingButtonAttributedAction(action: .toggle, alpha: 0.05, rotation: 0, xRight: 20)
    fileprivate let toggleButtonAvailableAction = FLoatingButtonAttributedAction(action: .toggle, alpha: 1, rotation: 0, xRight: 20)
    fileprivate let toggleButtonActiveAction = FLoatingButtonAttributedAction(action: .toggle, alpha: 1, rotation: CGFloat(-M_PI_4))
    
    fileprivate var topQuickAddControllerManager: ExpandableTopViewController<QuickAddViewController>?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        loadProducts()
    }
    
    func sortByOption(_ sortBy: ProductSortBy) -> (value: ProductSortBy, key: String)? {
        return sortByOptions.findFirst{$0.value == sortBy}
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = trans("title_products")
        
        tableView.allowsSelectionDuringEditing = true
        tableView.backgroundColor = Theme.defaultTableViewBGColor
        
        topQuickAddControllerManager = initTopQuickAddControllerManager()

        initNavBar([.edit])
        
        searchBar.addTarget(self, action: #selector(ManageProductsViewController.textFieldDidChange(_:)), for: UIControlEvents.editingChanged)

        navigationItem.backBarButtonItem?.title = ""
        
        layout()

        let recognizer = UITapGestureRecognizer(target: self, action: #selector(ManageProductsViewController.handleTap(_:)))
        recognizer.delegate = self
        recognizer.cancelsTouchesInView = false
        view.addGestureRecognizer(recognizer)
    }
    
    fileprivate func layout() {
        searchBoxHeightConstraint.constant = DimensionsManager.searchBarHeight
    }
    
    deinit {
        QL1("Deinit manage products controller")
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    func handleTap(_ recognizer: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    
    func onEditTap(_ sender: UIBarButtonItem) {
        toggleEditing()
    }
    
    // We have to do this programmatically since our storyboard does not contain the nav controller, which is in the main storyboard ("more"), thus the nav bar in our storyboard is not used. Maybe there's a better solution - no time now
    fileprivate func initNavBar(_ actions: [UIBarButtonSystemItem]) {
        navigationItem.title = trans("title_products")
        
        var buttons: [UIBarButtonItem] = []
        
        for action in actions {
            switch action {
            case .edit:
                let button = UIBarButtonItem(image: UIImage(named: "tb_edit")!, style: .plain, target: self, action: #selector(ManageProductsViewController.onEditTap(_:)))
                buttons.append(button)
            default: break
            }
        }
        navigationItem.rightBarButtonItems = buttons
    }
    
    fileprivate func initTopQuickAddControllerManager() -> ExpandableTopViewController<QuickAddViewController> {
//        let top: CGFloat = 55
        let top: CGFloat = 0
        let manager: ExpandableTopViewController<QuickAddViewController> = ExpandableTopViewController(top: top, height: DimensionsManager.quickAddManageProductsHeight, animateTableViewInset: false, parentViewController: self, tableView: tableView) {[weak self] in
            let controller = UIStoryboard.quickAddViewController()
            controller.delegate = self
            controller.modus = .product
            return controller
        }
        manager.delegate = self
        return manager
    }
    
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return products?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "productCell", for: indexPath) as! ManageProductsCell

        if let product = products?[indexPath.row] {
            cell.setProduct(product: product, bold: searchText)
            cell.contentView.addBottomBorderWithColor(Theme.cellBottomBorderColor, width: 1)
            
        } else {
            QL4("Invalid state: No product")
        }

        return cell
    }
    
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            guard let product = products?[(indexPath as NSIndexPath).row] else {QL4("No product"); return}
            Prov.productProvider.deleteQuantifiableProduct(uuid: product.uuid, remote: true, successHandler{
            })
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return DimensionsManager.defaultCellHeight
    }
    
    // MARK: - Filter
    
    
    func textFieldDidChange(_ textField: UITextField) {
        filter(textField.text ?? "")
    }
    
    fileprivate func filter(_ searchText: String) {
        self.searchText = searchText
    }
    
    
    // MARK: -
    
    fileprivate func onUpdatedProducts() {
        if let searchText = searchBar.text {
            filter(searchText)
        }
    }
    
    func textFieldShouldReturn(_ sender: UITextField) -> Bool {
        view.endEditing(true)
        return false
    }
 
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.isEditing {
            guard let product = products?[(indexPath as NSIndexPath).row] else {QL4("No product"); return}
            
            let productEditData = AddEditProductControllerEditingData(product: product, indexPath: indexPath)
            topQuickAddControllerManager?.expand(true)
            topQuickAddControllerManager?.controller?.initContent(AddEditItem(item: productEditData))
            initNavBar([.edit, .save])
            tableView.scrollToRow(at: indexPath, at: .top, animated: true)
        }
    }
    
    // MARK: - QuickAddDelegate
    
    func onCloseQuickAddTap() {
        topQuickAddControllerManager?.expand(false)
        topQuickAddControllerManager?.controller?.onClose()
    }
    
    func onAddGroup(_ group: ProductGroup, onFinish: VoidFunction?) {
    }
    
    func onAddProduct(_ product: QuantifiableProduct, quantity: Float, onAddToProvider: @escaping (QuickAddAddProductResult) -> Void) {
    }
    
    func onAddItem(_ item: Item) {
        // Do nothing - No Item quick add in this controller
    }
    
    func onAddIngredient(item: Item, ingredientInput: SelectIngredientDataControllerInputs) {
        // Do nothing - No ingredients in this controller
    }
    
    internal func onAddRecipe(ingredientModels: [AddRecipeIngredientModel], quickAddController: QuickAddViewController) {
        // TODO!!!!!!!!!!!!!!!!! disable recipes from quick add
        fatalError("Not supported") // It doesn't make sense to add recipes to products
    }
    
    func getAlreadyHaveText(ingredient: Ingredient, _ handler: @escaping (String) -> Void) {
        // TODO!!!!!!!!!!!!!!!!! disable recipes from quick add
        fatalError("Not supported") // It doesn't make sense to add recipes to products
    }
    
    func onSubmitAddEditItem(_ input: ListItemInput, editingItem: Any?) {
        
        func onEditItem(_ input: ListItemInput, editingItem: AddEditProductControllerEditingData) {
            
            // Assumption: When user edits a product in product screen, they want to modify the product itself. So for example, if they enter a new category, all items in the app referencing this product will also change their category. Or if they enter a new unit (say "box" instead of "packet") all items in the app using this quantifiable product, will now use "box". This maybe should be made clear to the user in some form, e.g. by explaining this when entering the product screen or when submitting an edit.
            // This is different to when user edits items (list, inventory, etc) - in this case we assume the intention is to change data *of the item*, and not altering the referenced (store/quantifiable)products. If they e.g. enter a new category for an item, we assume they want only this item to be categorized differently, not manipulate the underlaying product, which would affect other items in the app.
            // TODO!!!!!!!!!!!!!!!!!!!! this is WRONG - ONLY the product should be updated! objects referenced by product (unit, item) should not be directly updated but first get/create with the entered uniques and then update. Otherwise we can e.g. change here the name of a category everywhere in the app and this is not what we want to do when editing a product!
            // Note also that it's currently not possible to update e.g. the name of an item everywhere in the app - if we wanted to e.g. correct "srawberriz" into "strawberriews" we'd have to change the name for each possible quantifiable product and ingredient that references the item "strawberriz" - this also means that the item "strawberriz" is not deleted at the end, whch also means that we will continue seeing it in the ingredients quick-add. So we will need functionality to allow to edit items directly, somehow (at least update, delete) (TODO!!!!!!!!!!!!!!!!!!) we can either provide a separate screen for this, or have a single screen with a multilevel accordion - 1) item 1.1) products 1.1.1) quantifiable-products 1.1.1.1) store products. And in this accordion user can update or delete items at each level they want. ----> Replace manage products with this
            let updatedCategory = editingItem.product.product.item.category.copy(name: input.section, color: input.sectionColor)
            let updatedItem = editingItem.product.product.item.copy(name: input.name, category: updatedCategory)
            let updatedProduct = editingItem.product.product.copy(item: updatedItem, brand: input.brand)
            // TODO!!!!!! unit
            let updatedQuantifiableProduct = editingItem.product.copy(baseQuantity: input.storeProductInput.baseQuantity, product: updatedProduct)
            
            Prov.productProvider.update(updatedQuantifiableProduct, remote: true, successHandler{
            })
        }
        
        func onAddItem(_ input: ListItemInput) {
            let product = ProductInput(name: input.name, category: input.section, categoryColor: input.sectionColor, brand: input.brand)
            
            Prov.productProvider.countProducts(successHandler {[weak self] count in
                if let weakSelf = self {
                    SizeLimitChecker.checkInventoryItemsSizeLimit(count, controller: weakSelf) {
                        Prov.productProvider.add(product, weakSelf.successHandler {product in
                        })
                    }
                }
            })
        }
        
        if let editingItem = editingItem as? AddEditProductControllerEditingData {
            onEditItem(input, editingItem: editingItem)
        } else {
            if editingItem == nil {
                onAddItem(input)
            } else {
                QL4("Cast didn't work: \(editingItem)")
            }
        }
    }
    
    func onQuickListOpen() {
    }
    
    func onAddProductOpen() {
    }
    
    func onAddGroupOpen() {
    }
    
    func onAddGroupItemsOpen() {
    }
    
    func parentViewForAddButton() -> UIView {
        // this is a hack, with view the button shows below to where it should be. With super view it works. Not time to find out. Defaulting to view because superview is optional and prefer to avoid ! TODO improve this
        return view.superview ?? view
    }
    
    func addEditSectionOrCategoryColor(_ name: String, handler: @escaping (UIColor?) -> Void) {
        Prov.productCategoryProvider.categoryWithName(name, successHandler {category in
            handler(category.color)
        })
    }
    
    func onRemovedSectionCategoryName(_ name: String) {
        loadProducts()
    }
    
    func onRemovedBrand(_ name: String) {
        loadProducts()
    }
    
    func onFinishAddCellAnimation(addedItem: AnyObject) {
    }
    
    // MARK: -
    
    fileprivate func indexPathForProduct(_ product: QuantifiableProduct) -> IndexPath? {
        let indexMaybe = products?.enumerated().filter{$0.element.same(product)}.first?.offset
        return indexMaybe.map{IndexPath(row: $0, section: 0)}
    }

    fileprivate func setAddEditProductControllerOpen(_ open: Bool) {
        topQuickAddControllerManager?.expand(open)
        initNavBar([.edit])
    }

    fileprivate func loadProducts() {
        Prov.productProvider.productsRes(searchText, sortBy: sortBy, successHandler{[weak self] (substring: String?, products: Results<QuantifiableProduct>) in guard let weakSelf = self else {return}
            weakSelf.products = products
            
            weakSelf.notificationToken = weakSelf.products?.addNotificationBlock { changes in
                switch changes {
                case .initial:
                    //                        // Results are now populated and can be accessed without blocking the UI
                    //                        self.viewController.didUpdateList(reload: true)
                    QL1("initial")
                    
                case .update(_, let deletions, let insertions, let modifications):
                    QL2("deletions: \(deletions), let insertions: \(insertions), let modifications: \(modifications)")
                    
                    weakSelf.tableView.beginUpdates()
                    
//                    weakSelf.models = weakSelf.inventoriesResult!.map{ExpandableTableViewInventoryModelRealm(inventory: $0)}
                    weakSelf.tableView.insertRows(at: insertions.map { IndexPath(row: $0, section: 0) }, with: .automatic)
                    weakSelf.tableView.deleteRows(at: deletions.map { IndexPath(row: $0, section: 0) }, with: .automatic)
                    weakSelf.tableView.reloadRows(at: modifications.map { IndexPath(row: $0, section: 0) }, with: .none)
                    weakSelf.tableView.endUpdates()
                    
                    // TODO close only when receiving own notification, not from someone else (possible?)
                    weakSelf.topQuickAddControllerManager?.expand(false)
                    weakSelf.topQuickAddControllerManager?.controller?.onClose()
                    
                case .error(let error):
                    // An error occurred while opening the Realm file on the background worker thread
                    fatalError(String(describing: error))
                }
            }
            
            self?.tableView.reloadData()
        })
    }
    
    fileprivate func toggleEditing() {
        tableView.setEditing(!tableView.isEditing, animated: true)
    }
    
    
    // MARK: - ExpandableTopViewControllerDelegate
    
    func animationsForExpand(_ controller: UIViewController, expand: Bool, view: UIView) {
        topControlTopConstraint.constant = expand ? view.frame.height : 10
        searchBoxHeightConstraint.constant = expand ? 0 : DimensionsManager.searchBarHeight
        searchBoxMarginTopConstraint.constant = expand ? 0 : 10
//        searchBoxMarginBottomConstraint.constant = expand ? 0 : 10
        self.view.layoutIfNeeded()
    }
    
    func onExpandableClose() {
        topQuickAddControllerManager?.controller?.onClose()
    }
    
    func onCenterTitleAnimComplete(_ center: Bool) {
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
        if let popup = self.sortByPopup {
            popup.dismiss(animated: true)
        } else {
            let picker = createPicker()
            let popup = MyTipPopup(customView: picker)
            if let row = (sortByOptions.index{$0.value == sortBy}) {
                picker.selectRow(row, inComponent: 0, animated: false)
            }
            popup.presentPointing(at: sortByButton, in: view, animated: true)
        }
    }
    
    fileprivate func createPicker() -> UIPickerView {
        let picker = UIPickerView(frame: CGRect(x: 0, y: 0, width: 150, height: 100))
        picker.delegate = self
        picker.dataSource = self
        return picker
    }
}

struct AddEditProductControllerEditingData {
    let product: QuantifiableProduct
    let indexPath: IndexPath
    init(product: QuantifiableProduct, indexPath: IndexPath) {
        self.product = product
        self.indexPath = indexPath
    }
}
