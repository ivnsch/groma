//
//  AddEditListItemViewController.swift
//  shoppin
//
//  Created by ischuetz on 20/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import SwiftValidator

import Providers
import RealmSwift

protocol AddEditListItemViewControllerDelegate: class {
    
    // Returns nil if no errors, otherwise dictionary with errors. Important: Empty dictionary is invalid and the form will not be submitted!
    func runAdditionalSubmitValidations() -> ValidatorDictionary<ValidationError>?
    
    func onValidationErrors(_ errors: ValidatorDictionary<ValidationError>)
    
    func onOkTap(_ price: Float, quantity: Float, section: String, sectionColor: UIColor, note: String?, baseQuantity: Float, unit: String, brand: String, edible: Bool, editingItem: Any?)
    
    func parentViewForAddButton() -> UIView?
    
    func addEditSectionOrCategoryColor(_ name: String, handler: @escaping (UIColor?) -> Void)
    
    func onRemovedSectionCategoryName(_ name: String)
    func onRemovedBrand(_ name: String)

    func endEditing()
    func focusSearchBar()

//    func productNameAutocompletions(text: String, handler: [String] -> Void)
//    func sectionNameAutocompletions(text: String, handler: [String] -> Void)
//    func storeNameAutocompletions(text: String, handler: [String] -> Void)
    
    
//    func planItem(productName: String, handler: PlanItem? -> ())
}

// FIXME use instead a "fragment" (custom view) with the common inputs and use this in 2 separate view controllers
// then we can also use different delegates, now the delegate is passed "note" parameter for group item as well where it doesn't exist, not nice
enum AddEditListItemControllerModus {
    case listItem, groupItem, planItem, product, ingredient
}

//typealias AddEditItemInput2 = (name: String, price: Float, quantity: String, category: String, categoryColor: UIColor, sectionName: String, note: String?, baseQuantity: Float, unit: ProductUnit)

struct AddEditItem {
    let product: QuantifiableProduct?
    let storeProduct: StoreProduct? // TODO? no redundancy with product
    let item: Item
    let quantity: Float
    let sectionName: String
    let sectionColor: UIColor
    let note: String?
    let model: Any
    
    init(product: QuantifiableProduct, storeProduct: StoreProduct? = nil, quantity: Float, sectionName: String, sectionColor: UIColor, note: String?, model: Any) {
        self.product = product
        self.storeProduct = storeProduct
        self.item = product.product.item
        self.quantity = quantity
        self.sectionName = sectionName
        self.sectionColor = sectionColor
        self.note = note
        self.model = model
    }
    
    init(item: ListItem, currentStatus: ListItemStatus) {
        self.product = item.product.product
        self.storeProduct = item.product
        self.item = item.product.product.product.item
        self.quantity = item.quantity
        self.sectionName = item.section.name
        self.sectionColor = item.section.color
        self.note = item.note
        self.model = item
    }
    
    init(item: GroupItem) {
        self.product = item.product
        self.storeProduct = nil
        self.item = item.product.product.item
        self.quantity = item.quantity
        self.sectionName = item.product.product.item.category.name
        self.sectionColor = item.product.product.item.category.color
        self.note = nil
        self.model = item
    }
    
    init(item: InventoryItem) {
        self.product = item.product
        self.storeProduct = nil
        self.item = item.product.product.item
        self.quantity = item.quantity
        self.sectionName = item.product.product.item.category.name
        self.sectionColor = item.product.product.item.category.color
        self.note = nil
        self.model = item
    }
    
    init(item: AddEditProductControllerEditingData) {
        self.product = item.product
        self.storeProduct = nil
        self.item = item.product.product.item
        self.quantity = 0
        self.sectionName = item.product.product.item.category.name
        self.sectionColor = item.product.product.item.category.color
        self.note = nil
        self.model = item
    }
    
    init(item: Ingredient) {
        self.product = nil
        self.storeProduct = nil
        self.item = item.item
        self.quantity = item.quantity
        self.sectionName = item.item.category.name
        self.sectionColor = item.item.category.color
        self.note = nil
        self.model = item
    }
}

class AddEditListItemViewController: UIViewController, UITextFieldDelegate, MLPAutoCompleteTextFieldDataSource, MLPAutoCompleteTextFieldDelegate
//, ScaleViewControllerDelegate, SimpleInputPopupControllerDelegate
, FlatColorPickerControllerDelegate, MyAutoCompleteTextFieldDelegate {

    
    @IBOutlet weak var addNewItemLabel: UILabel!
    
    @IBOutlet weak var brandInput: LineAutocompleteTextField!

    @IBOutlet weak var sectionInput: LineAutocompleteTextField!
    @IBOutlet weak var sectionColorButton: LineTextField!

    @IBOutlet weak var priceInput: LineTextField!
    
    @IBOutlet weak var titleLabel: UILabel!

    @IBOutlet weak var edibleButton: UIButton!
    
    @IBOutlet weak var categoryOrSectionTextFieldTopToSuperviewConstraint: NSLayoutConstraint!
    @IBOutlet weak var categoryOrSectionTextFieldTopToBrandEdibleRowConstraint: NSLayoutConstraint!

/////////////////////////////////////////////////////////////////////////
// for now disabled, see comments at the bottom
//    @IBOutlet weak var sectionLabel: UILabel!
//    @IBOutlet weak var priceLabel: UILabel!
//    @IBOutlet weak var quantityLabel: UILabel!
//    @IBOutlet weak var quantityPlusButton: UIButton!
//    @IBOutlet weak var quantityMinusButton: UIButton!
//    @IBOutlet weak var planInfoButton: UIButton!
//    @IBOutlet weak var scaleButton: UIButton!
//    @IBOutlet weak var noteButton: UIButton!
//    private var scaleInputs: ProductScaleData?
//    private var noteInput: String? {
//        didSet {
//            noteButton.imageView?.tintColor = noteInput.map{$0.isEmpty} ?? true ? UIColor.flatGrayColor() : UIColor.flatBlackColor()
//        }
//    }
//    
//    var planItem: PlanItem? {
//        didSet {
//            onQuantityChanged()
//        }
//    }
///////////////////////////////////////////////////////////////////////////
    
    @IBOutlet weak var noteInput: LineTextField!

    @IBOutlet weak var quantitiesContainer: UIView!

    fileprivate var productQuantityController: ProductQuantityController?

    weak var delegate: AddEditListItemViewControllerDelegate?
    
    fileprivate var currentQuantity: Float = 0
    fileprivate var currentUnit: String = ""
    fileprivate var currentUnitId: UnitId = .none
    fileprivate var currentBase: Float = 1

    fileprivate var showingColorPicker: FlatColorPickerController?
//    private var showingNoteInputPopup: SimpleInputPopupController?

    var keyboardHeight: CGFloat?
    
    var edibleSelected: Bool = false {
        didSet {
            if let edibleButton = edibleButton {
                edibleButton.setTitleColor(edibleSelected ? Theme.black : Theme.lightGray, for: .normal)
            } else {
                logger.e("Outlets not initialized yet")
            }
        }
    }
    
    var editingItem: AddEditItem? {
        didSet {
            if let editingItem = editingItem {
                prefill(editingItem)
                addNewItemLabel.text = trans("add_edit_list_item_edit_item")
            } else {
                logger.w("Setting editingItem before outlets are set")
            }
        }
    }

    // when the view controller is used in .PlanItem modus... // FIXME besser structure
    var editingPlanItem: PlanItem? {
        didSet {
            if let editingPlanItem = editingPlanItem {
                prefill(editingPlanItem)
            } else {
                
                logger.w("Setting updatingListItem before outlets are set")
            }
        }
    }
    
    var modus: AddEditListItemControllerModus = .listItem {
        didSet {
            if let noteInput = noteInput {
                
                let isListItem = modus == .listItem
                noteInput.isHidden = !isListItem
                priceInput.isHidden = !isListItem
                
//                let sectionText = "Section"
//                let categoryText = "Category"
                let sectionPlaceHolderText = trans("placeholder_section")
                let categoryPlaceHolderText = trans("placeholder_category")
                
                switch modus {
                case .listItem:
                    sectionInput.placeholder = sectionPlaceHolderText
                case .groupItem:
//                    sectionLabel.text = sectionText
                    sectionInput.placeholder = categoryPlaceHolderText
                case .planItem:
//                    sectionLabel.text = categoryText // plan items don't have section, but we need a category for the new product (note for list and group items we save the section as category - user can change the category later using the product manager. This is for simple usability, mostly section == category otherwise interface may be a bit confusing)
                    sectionInput.placeholder = categoryPlaceHolderText
                case .product:
//                    sectionLabel.text = categoryText
                    sectionInput.placeholder = categoryPlaceHolderText
//                    quantityLabel.hidden = true
//                    quantityInput.isHidden = true
//                    quantityPlusButton.hidden = true
//                    quantityMinusButton.hidden = true
                case .ingredient:
                    
                    sectionInput.placeholder = categoryPlaceHolderText
                    
                    brandInput.isHidden = true // no brand
                    edibleButton.isHidden = true // always edible
                    
                    // After the new item is added there's a second controller (which is also shown when we add using the quick-add) where the user enters unit, quantity, etc. so no need to show quantity/unit inputs here.
                    quantitiesContainer.isHidden = true
                    productQuantityController?.onPickersInitialized = {[weak self] in
                        self?.productQuantityController?.setManagedViewsHidden(hidden: true)
                    }
                    
                    // Move the category row a bit up, since there's no brand/edible row
                    categoryOrSectionTextFieldTopToSuperviewConstraint.isActive = true
                    categoryOrSectionTextFieldTopToBrandEdibleRowConstraint.isActive = false
                    categoryOrSectionTextFieldTopToSuperviewConstraint.constant = 10
                }
                
            } else {
                print("Error: Trying to set modus before outlet is initialised")
            }
        }
    }
    
    var open: Bool = false
    
    fileprivate var validator: Validator?
    
    // TODO improve this, it's finicky.
    var onViewDidLoad: VoidFunction? // Called on view did load before custom logic, use e.g. to set mode from which other methods called in viewDidLoad may depend.
    var onDidLoad: VoidFunction? // Called on view did load at the end
    
    fileprivate var addButtonHelper: AddButtonHelper?

    fileprivate var unitBasePopup: MyPopup?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // order is important in these methods, first the "static" ones (don't depend on anything), then onViewDidLoad, which may be used to set the mode, then the rest...
        
        setInputsDefaultValues()
        initTextFieldPlaceholders()
        initAutocompletionTextFields()
        
        priceInput.delegate = self

        sectionColorButton.textColor = UIColor.gray
        sectionColorButton.text = trans("generic_color") // string from storyboard localization doesn't work, seems to be xcode bug
        
        configQuantifiablesView()
        
        onViewDidLoad?()
        
        initValidator()
        
        view.clipsToBounds = false
        
        initStaticLabels()

        onDidLoad?()
//        updatePlanLeftQuantity(0) // no quantity yet -> 0
        
        initGlobalTap()
    }
    
    fileprivate func initGlobalTap() {
        let tap = UITapGestureRecognizer()
        tap.cancelsTouchesInView = false
        tap.delegate = self
        tap.addTarget(self, action: #selector(onTapView(_:)))
        view.addGestureRecognizer(tap)
    }
    
    func configQuantifiablesView() {
        let productQuantityController = ProductQuantityController()
        
        productQuantityController.delegate = self
        
        productQuantityController.view.translatesAutoresizingMaskIntoConstraints = false
        productQuantityController.view.backgroundColor = UIColor.clear
        addChildViewController(productQuantityController)
        quantitiesContainer.addSubview(productQuantityController.view)
        productQuantityController.view.fillSuperview()
        
        self.productQuantityController = productQuantityController

        productQuantityController.config(
            onTapUnitBase: { [weak self] in guard let weakSelf = self else { return }
                weakSelf.onTapUnitBaseView()
            }
        )
        currentUnitId = .none
        currentUnit = trans("unit_unit")
        currentQuantity = 1
        currentBase = 1

        updateProductQuantityController()
    }

    fileprivate func updateProductQuantityController() {
        productQuantityController?.show(
            base: currentBase,
            unitId: currentUnitId,
            unitName: currentUnit,
            quantity: currentQuantity
        )
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

    }

    func onTapUnitBaseView() {
        // Parent is expected to be list items controller
        guard let parent = self.parent?.parent?.parent else { logger.e("No parent! Can't show popup"); return }
        guard let unitBaseView = productQuantityController?.unitWithBaseView else { logger.e("No unit base view! Can't show popup"); return }

        let height = parent.view.height - Theme.navBarHeight
        let popupFrame = CGRect(x: parent.view.x, y: Theme.navBarHeight, width: parent.view.width, height: height)
        let popup = MyPopup(parent: parent.view, frame: popupFrame)
        popup.contentCenter = popup.bounds.center
        let controller = SelectUnitAndBaseController(nibName: "SelectUnitAndBaseController", bundle: nil)

        let focusedTextField: UITextField? = {
            if sectionInput.isFirstResponder {
                return sectionInput
            } else if brandInput.isFirstResponder {
                return brandInput
            } else if priceInput.isFirstResponder {
                return priceInput
            } else if noteInput.isFirstResponder {
                return noteInput
            } else {
                return nil
            }
        } ()

        delegate?.endEditing()
        dismissKeyboard(nil)

        controller.onSubmit = { [weak self] result in guard let weakSelf = self else { return }
            weakSelf.currentBase = result.baseQuantity
            weakSelf.currentUnit = result.unitName
            weakSelf.currentUnitId = result.unitId

            self?.unitBasePopup?.hide(onFinish: { [weak self] in guard let weakSelf = self else { return }
                self?.unitBasePopup = nil
                self?.productQuantityController?.show(
                    base: weakSelf.currentBase,
                    unitId: weakSelf.currentUnitId,
                    unitName: weakSelf.currentUnit,
                    quantity: weakSelf.currentQuantity
                )

                if let focusedTextField = focusedTextField {
                    focusedTextField.becomeFirstResponder()
                } else {
                    // There must always be a text field focused - if it's none of ours it can be only the search bar
                    self?.delegate?.focusSearchBar()
                }
            })
        }

        parent.addChildViewController(controller)

        controller.view.frame = popup.bounds
        popup.contentView = controller.view
        self.unitBasePopup = popup

        controller.config(selectedUnitId: currentUnitId,
                          selectedUnitName: currentUnit,
                          selectedBaseQuantity: currentBase)
        popup.show(from: unitBaseView, offsetY: -Theme.navBarHeight)
    }
    
    fileprivate func initAddButtonHelper() -> AddButtonHelper? {
        guard let parentViewForAddButton = delegate?.parentViewForAddButton() else {logger.e("No delegate: \(String(describing: delegate))"); return nil}
        guard let tabBarHeight = tabBarController?.tabBar.bounds.size.height else {logger.e("No tabBarController"); return nil}
        
        let overrideCenterY: CGFloat = parentViewForAddButton.height + tabBarHeight

        let addButtonHelper = AddButtonHelper(parentView: parentViewForAddButton, overrideCenterY: overrideCenterY) {[weak self] in guard let weakSelf = self else {return}
            weakSelf.submit()
        }
        return addButtonHelper
    }
    
    func focusFirstTextField() {
        brandInput.becomeFirstResponder()
    }
    
    @objc func onTapView(_ tap: UITapGestureRecognizer) {
        submitUnitOrBasePickers()
    }
    
    
    fileprivate func submitUnitOrBasePickers() {
       // TODO remove?
//        guard let productQuantityController = productQuantityController else {logger.e("No product quantity controller"); return}
//
//        productQuantityController.setUnitPickerOpen(false)
//        productQuantityController.setBasesPickerOpen(false)
//
//        if let currentUnitInput = productQuantityController.currentUnitInput, !currentUnitInput.isEmpty {
//            addUnit(name: currentUnitInput) {(unit, isNew) in
//                if isNew {
//                    productQuantityController.appendNewUnitCell(unit: unit)
//                }
//                productQuantityController.currentUnitInput = nil
//            }
//        }
//
//        if let currentBaseInput = productQuantityController.currentBaseInput {
//            addBaseQuantity(val: currentBaseInput) {isNew in
//                if isNew {
//                    productQuantityController.appendNewBaseCell()
//                }
//                productQuantityController.currentBaseInput = nil
//            }
//        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if addButtonHelper == nil {
            addButtonHelper = initAddButtonHelper()
        }
        addButtonHelper?.addObserver()
        addButtonHelper?.animateVisible(true, overrideKeyboardHeight: keyboardHeight)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        addButtonHelper?.removeObserver()
        addButtonHelper?.animateVisible(false)
    }
    
    fileprivate func initStaticLabels() {
        addNewItemLabel.font = DimensionsManager.font(.regular, fontType: .regular)
        addNewItemLabel.text = trans("add_edit_list_item_add_new_item")
    }
    
    fileprivate func prefill(_ item: AddEditItem) {
        brandInput.text = item.product?.product.brand ?? ""
        sectionInput.text = item.sectionName
        sectionColorButton.textColor = item.sectionColor
        
        // TODO!!!!!!!!!!!!!!!!! redundancy - review if we really need to return quantity in delegate as well as pass here
        currentQuantity = item.quantity
        productQuantityController?.quantity = item.quantity
        
        let price = item.storeProduct?.price ?? 0
        priceInput.text = price > 0 ? price.toString(2) : ""
        noteInput.text = item.note
        // TODO!!!!!!!!!!!!!!! quantifiable product - unit?
        
        edibleSelected = item.item.edible

        currentUnitId = item.product?.unit.id ?? .none
        currentUnit = item.product?.unit.name ?? trans("unit_unit")
        currentQuantity = item.quantity
        currentBase = item.product?.baseQuantity ?? 1

        updateProductQuantityController()

        // TODO remove?
//        productQuantityController?.onPickersInitialized = {[weak productQuantityController] in
//            if let quantifiableproduct = item.product {
//                productQuantityController?.selectUnitWithName(quantifiableproduct.unit.name)
//                productQuantityController?.selectBaseWithValue(quantifiableproduct.baseQuantity)
//            }
//        }
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == priceInput {
            textField.selectAll(nil)
        }
    }
    
    fileprivate func initTextFieldPlaceholders() {
        brandInput.attributedPlaceholder = NSAttributedString(string: brandInput.placeholder!, attributes: [NSAttributedStringKey.foregroundColor: UIColor.gray])
        sectionInput.attributedPlaceholder = NSAttributedString(string: sectionInput.placeholder!, attributes: [NSAttributedStringKey.foregroundColor: UIColor.gray])
        priceInput.attributedPlaceholder = NSAttributedString(string: priceInput.placeholder!, attributes: [NSAttributedStringKey.foregroundColor: UIColor.gray])
        noteInput.attributedPlaceholder = NSAttributedString(string: noteInput.placeholder!, attributes: [NSAttributedStringKey.foregroundColor: UIColor.gray])
        
        edibleButton.setTitle(trans("edible_button_title"), for: .normal)
    }
    
    fileprivate func initAutocompletionTextFields() {
        for textField in [brandInput, sectionInput] {
            textField?.defaultAutocompleteStyle()
            textField?.myDelegate = self
        }
    }

    fileprivate func prefill(_ planItem: PlanItem) {
        brandInput.text = planItem.product.brand
        sectionInput.text = planItem.product.item.category.name
        sectionColorButton.textColor = planItem.product.item.category.color
//        quantityInput.text = String(planItem.quantity)
    }
    
    fileprivate func setInputsDefaultValues() {
//        quantityInput.text = "1"
    }
    
    fileprivate func initValidator() {
        let validator = Validator()
        validator.registerField(sectionInput, rules: [NotEmptyTrimmedRule(message: trans("validation_section_name_not_empty"))])
//        validator.registerField(quantityInput, rules: [NotEmptyTrimmedRule(message: trans("validation_quantity_not_empty"))])

//        if modus == .listItem {
//            validator.registerField(priceInput, rules: [NotEmptyTrimmedRule(message: trans("validation_price_not_empty"))])
//        }
        self.validator = validator
    }
    
    // Parameter action is only relevant for add case - in edit it's expected to be always "Ok" (since edit has only ok button) and ignored.
//    func submit(action: AddEditListItemViewControllerAction) {
    func submit() {
        guard validator != nil else {return}
        
        let formValidationErrors = validator?.validate()
        let externalValidationsErrors = delegate?.runAdditionalSubmitValidations() // name (search bar)
        
        if formValidationErrors != nil || externalValidationsErrors != nil {
           
            var allValidationErrors = ValidatorDictionary<ValidationError>()
            if let formValidationErrors = formValidationErrors {
                allValidationErrors = formValidationErrors
            }
            if let externalValidationsErrors = externalValidationsErrors {
                allValidationErrors = allValidationErrors + externalValidationsErrors
            }

            for (_, error) in allValidationErrors {
                error.field.showValidationError()
            }
            
            delegate?.onValidationErrors(allValidationErrors)
            
        } else {
            if let lastErrors = validator?.errors {
                for (_, error) in lastErrors {
                    error.field.clearValidationError()
                }
            }
            
            let price: Float = priceInput.text?.floatValue ?? 0
            
            if let section = sectionInput.text?.trim(), let brand = brandInput.text?.trim(), let note = noteInput.text?.trim(), let sectionColor = sectionColorButton.textColor {
                
                // the price from scaleInputs is inserted in price field, so we have it already
                
                // Explanation category/section name: for list items, the section input refers to the list item's section. For the rest the product category. When we store the list items, if a category with the entered section name doesn't exist yet, one is created with the section's data.
                delegate?.onOkTap(price, quantity: currentQuantity, section: section, sectionColor: sectionColor, note: note, baseQuantity: currentBase, unit: currentUnit, brand: brand, edible: edibleSelected, editingItem: editingItem?.model)
                
            } else {
                logger.e("Validation was not implemented correctly, price: \(String(describing: priceInput.text)), quantity: \(String(describing: productQuantityController?.quantity)), brand: \(String(describing: brandInput.text)), sectionColor: \(String(describing: sectionColorButton.textColor))")
            }
        }
    }
    
    func textFieldShouldReturn(_ sender: UITextField) -> Bool {
        if sender == noteInput {
            submit()
            sender.resignFirstResponder()
        } else {
            let textFields = [brandInput, sectionInput, priceInput, noteInput] as [UITextField]
            if let index = textFields.index(of: sender) {
                if let next = textFields[safe: index + 1] {
                    next.becomeFirstResponder()
                }
            }
        }
        return false
    }
    
    func clearInputs() {
        for field in [sectionInput, priceInput] as [UITextField] {
            field.text = ""
        }
    }
    
    func dismissKeyboard(_ sender: AnyObject?) {
        for field in [sectionInput, priceInput] as [UITextField] {
            _ = field.resignFirstResponder()
        }
    }
    
    // MARK: - MLPAutoCompleteTextFieldDataSource

//    func autoCompleteTextField(_ textField: MLPAutoCompleteTextField!, possibleCompletionsFor string: String!, completionHandler handler: (([AnyObject]?) -> Void)!) {
//    func autoCompleteTextField(_ textField: MLPAutoCompleteTextField!, possibleCompletionsFor string: String!, completionHandler handler: @escaping (([Any]?) -> Void)!) {
    func autoCompleteTextField(_ textField: MLPAutoCompleteTextField!, possibleCompletionsFor string: String!, completionHandler handler: @escaping (([Any]?) -> Void)) {
        switch textField {
        case sectionInput:
            switch modus {
            case .listItem:
                Prov.sectionProvider.sectionSuggestionsContainingText(string, successHandler{suggestions in
                    handler(suggestions)
                })
            default:
                Prov.productCategoryProvider.categoriesContainingText(string, successHandler{categories in
                    let suggestions = categories.map{$0.name}.distinct()
                    handler(suggestions)
                })
            }
            
        case brandInput:
            Prov.brandProvider.brandsContainingText(string, successHandler{brands in
                handler(brands)
            })
        case _:
            print("Error: Not handled text field in autoCompleteTextField")
            break
        }
    }

    // MARK: - MLPAutoCompleteTextFieldDelegate

    func autoCompleteTextField(_ textField: MLPAutoCompleteTextField!, didSelectAutoComplete selectedString: String!, withAutoComplete selectedObject: MLPAutoCompletionObject!, forRowAt indexPath: IndexPath!) {

        if textField == sectionInput {
            delegate?.addEditSectionOrCategoryColor(selectedString) {[weak self] colorMaybe in
                self?.sectionColorButton.textColor = colorMaybe ?? {
                    logger.e("Invalid state: selected a section or category suggestion and there's no color.")
                    return UIColor.black
                }()
            }
        }
    }


    @IBAction func onSectionColorButtonTap(_ sender: UIButton) {
    
        let picker = UIStoryboard.listColorPicker()
        showPopup(sectionColorButton, controller: picker) {[weak self] in
            if let weakSelf = self {
                picker.delegate = weakSelf
                weakSelf.showingColorPicker = picker
                
                self?.view.endEditing(true)
                self?.delegate?.endEditing()
            }
        }
    }

    fileprivate func showPopup(_ button: UIView, controller: UIViewController, topOffset: CGFloat = 0, width: CGFloat? = nil, height: CGFloat? = nil, onWillShow: VoidFunction) {
        
        if let windowView = parent?.view.superview?.superview?.superview {
            
            // TODO dynamic
            let topBarHeight: CGFloat = Theme.navBarHeight
            let pricesViewHeight: CGFloat = DimensionsManager.listItemsPricesViewHeight
//            let tabBarHeight: CGFloat = 49
            
            let x: CGFloat = {
                if let width = width {
                    return (windowView.frame.width - width) / 2
                } else {
                    return 0
                }
            }()
            
            let w = width ?? windowView.frame.width
            let h = height ?? (windowView.frame.height - pricesViewHeight - topBarHeight)
            controller.view.frame = CGRect(x: x, y: topBarHeight + topOffset, width: w, height: h)
            
            windowView.addSubview(controller.view)
            
            let buttonPointInParent = windowView.convert(CGPoint(x: button.center.x, y: button.center.y - topBarHeight), from: view)
            let fractionX = (buttonPointInParent.x - ((windowView.frame.width - w) / 2)) / w
            let fractionY = buttonPointInParent.y / h
            
            controller.view.layer.anchorPoint = CGPoint(x: fractionX, y: fractionY)
            
            controller.view.frame = CGRect(x: x, y: topBarHeight + topOffset, width: w, height: h)
            
            controller.view.transform = CGAffineTransform(scaleX: 0, y: 0)
            
            onWillShow()
            
            UIView.animate(withDuration: 0.3, animations: {
                controller.view.transform = CGAffineTransform(scaleX: 1, y: 1)
            }) 
            
        } else {
            print("Warn: AddEditListItemViewController.onSectionColorButtonTap: unexpected: no window")
        }
    }


    // MARK: - FlatColorPickerControllerDelegate

    func onColorPicked(_ color: UIColor) {
        dismissColorPicker(color)
    }

    func onDismiss() {
        dismissColorPicker(nil) // not used see FIXME in FlatColorPickerController.viewDidLoad
    }

    fileprivate func dismissColorPicker(_ selectedColor: UIColor?) {
        if let showingColorPicker = showingColorPicker {
            
            dismissPopup(showingColorPicker) {[weak self] in
                self?.showingColorPicker = nil
                self?.showingColorPicker?.removeFromParentViewControllerWithView()
                
                UIView.animate(withDuration: 0.3, animations: {
                    if let selectedColor = selectedColor {
                        self?.sectionColorButton.textColor = selectedColor
                    }
                }) 
//                UIView.animateWithDuration(0.15) {
//                    self.sectionColorButton.transform = CGAffineTransformMakeScale(2, 2)
//                    UIView.animateWithDuration(0.15) {
//                        self.sectionColorButton.transform = CGAffineTransformMakeScale(1, 1)
//                    }
//                }
                
                self?.sectionInput.becomeFirstResponder() // for now restore always section field TODO restore last responde
            }
        }
    }

    fileprivate func dismissPopup(_ controller: UIViewController, onComplete: VoidFunction? = nil) {
        UIView.animate(withDuration: 0.3, animations: {
            controller.view.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
            }, completion: {finished in
                controller.view.removeFromSuperview()
                onComplete?()
            }
        )
    }

    // MARK: - MyAutoCompleteTextFieldDelegate

    func onDeleteSuggestion(_ string: String, sender: MyAutoCompleteTextField) {
        switch sender {
        case sectionInput:
            ConfirmationPopup.show(title: trans("popup_title_confirm"), message: trans("popup_remove_section_completion_confirm", string), okTitle: trans("popup_button_yes"), cancelTitle: trans("popup_button_no"), controller: self, onOk: {[weak self] in guard let weakSelf = self else {return}
                Prov.sectionProvider.removeAllWithName(string, remote: true, weakSelf.successHandler {
                    Prov.productCategoryProvider.removeAllCategoriesWithName(string, remote: true, weakSelf.successHandler {
                        self?.delegate?.onRemovedSectionCategoryName(string)
                        AlertPopup.show(message: trans("popup_was_removed", string), controller: weakSelf)
                    })
                })
            })
        case brandInput:
            ConfirmationPopup.show(title: trans("popup_title_confirm"), message: trans("popup_remove_brand_completion_confirm"), okTitle: trans("popup_button_yes"), cancelTitle: trans("popup_button_no"), controller: self, onOk: {[weak self] in guard let weakSelf = self else {return}
                Prov.brandProvider.removeProductsWithBrand(string, remote: true, weakSelf.successHandler {
                    self?.delegate?.onRemovedBrand(string)
                    AlertPopup.show(message: trans("popup_was_removed", string), controller: weakSelf)
                })
            })
        default: logger.e("Not handled input")
        }
    }
    
    deinit {
        // TODO!!! why is this deinit never called?
        logger.v("Deinit add edit listitem controller")
    }
    
    // MARK: -
    
    @IBAction func onTapEdible() {
        edibleSelected = !edibleSelected
    }

///////////////////////////////////////////////////////////////////////////
// note popup - for now disabled
//    @IBAction func onNoteButtonTap(sender: AnyObject) {
//        let controller = UIStoryboard.simpleInputStoryboard()
//        controller.onUIReady = {[weak self] in
//            if let weakSelf = self {
//                controller.textView.text = weakSelf.noteInput
//            }
//        }
//        showPopup(noteButton, controller: controller, topOffset: 10, width: 300, height: 300) {[weak self] in
//            if let weakSelf = self {
//                controller.delegate = weakSelf
//                weakSelf.showingNoteInputPopup = controller
//            }
//        }
//    }
//
//    // MARK: - SimpleInputPopupControllerDelegate
//
//    func onSubmitInput(text: String) {
//        noteInput = text
//        showingNoteInputPopup?.dismiss()
//    }
//
//    func onDismissSimpleInputPopupController(cancelled: Bool) {
//        if let showingNoteInputPopup = showingNoteInputPopup {
//            dismissPopup(showingNoteInputPopup) {[weak self] in
//                if !cancelled {
//                    UIView.animateWithDuration(0.15) {
//                        self?.noteButton.transform = CGAffineTransformMakeScale(2, 2)
//                        UIView.animateWithDuration(0.15) {
//                            self?.noteButton.transform = CGAffineTransformMakeScale(1, 1)
//                        }
//                    }
//                }
//            }
//        }
//    }
///////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////
// plan left label - for now disabled
//    private func updatePlanLeftQuantity(inputQuantity: Int) {
//        if let planItem = planItem {
//            let planItemLeftQuantity = planItem.quantity - planItem.usedQuantity
//            let updatedLeftQuantity = planItemLeftQuantity - inputQuantity
//
//            // default
//            planInfoButton.setTitleColor(UIColor.darkTextColor(), forState: .Normal)
//            planInfoButton.titleLabel?.font = Fonts.verySmallLight
//
//            if planItemLeftQuantity <= 0 {
//                if planItemLeftQuantity == 0 {
//                    planInfoButton.setTitle("\(updatedLeftQuantity) left", forState: .Normal)
//                } else {
//                    planInfoButton.setTitle("\(abs(updatedLeftQuantity)) overflow!", forState: .Normal)
//                    planInfoButton.titleLabel?.font = Fonts.verySmallBold
//                }
//                planInfoButton.setTitleColor(UIColor.redColor(), forState: .Normal)
//            } else {
//                planInfoButton.setTitle("\(updatedLeftQuantity) left", forState: .Normal)
//
//            }
//
//        } else { // item is not planned -  don't show anything (no limits)
//            planInfoButton.setTitle("", forState: .Normal)
//        }
//    }
//
//    func showPlanItem(planItem: PlanItem) {
//        planInfoButton.setTitle("\(planItem.quantity - planItem.usedQuantity) left", forState: .Normal)
//    }
//
//    func onQuantityChanged() {
//        if let text = quantityInput.text, quantity = Int(text) {
//            updatePlanLeftQuantity(quantity)
//        } else {
//            print("Error: Invalid quantity input")
//        }
//    }
//
///////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////
// increment quantity buttons - for now disabled
//    // MARK: -
//
//    @IBAction func onQuantityPlusTap(button: UIButton) {
//        if let quantityText = quantityInput.text, quantity = Int(quantityText) {
//            quantityInput.text = "\(quantity + 1)"
//        } else {
//            quantityInput.text = "1"
//        }
//    }
//
//    @IBAction func onQuantityMinusTap(button: UIButton) {
//        if let quantityText = quantityInput.text, quantity = Int(quantityText) {
//            quantityInput.text = "\(quantity - 1)"
//        }
//    }
//
//    @IBAction func quantityEditingDidChange(sender: AnyObject) {
//        onQuantityChanged()
//    }
///////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////
// custom scale - for now disabled
//    private var showingScaleController: ScaleViewController?
//    private var overlay: UIView?
//
//    @IBAction func onScaleTap(button: UIButton) {
//        let scaleController = UIStoryboard.scaleViewController()
//        showPopup(scaleButton, controller: scaleController, topOffset: 10, width: 300, height: 300) {[weak self] in
//            if let weakSelf = self {
//                scaleController.delegate = self
//                weakSelf.showingScaleController = scaleController
//
//                let prefillScaleInputs = ProductScaleData(
//                    price: weakSelf.priceInput.text?.floatValue ?? 0, // current price input
//                    baseQuantity: weakSelf.scaleInputs?.baseQuantity ?? 1, // if no scale input has been done yet - default quantity is 1
//                    unit: weakSelf.scaleInputs?.unit ?? .None // if no scale input has been done yet - default unit is 1
//                )
//                scaleController.prefill(prefillScaleInputs)
//            }
//        }
//    }
//
//    // MARK: - ScaleViewControllerDelegate
//
//    func onScaleViewControllerValidationErrors(errors: [UITextField : ValidationError]) {
//        presentViewController(ValidationAlertCreator.create(errors), animated: true, completion: nil)
//    }
//
//    func onScaleViewControllerSubmit(scaleInputs: ProductScaleData) {
//
//        showingScaleController?.dismiss()
//
//        self.scaleInputs = scaleInputs
//
//        let (price, baseQuantity, unit) = (scaleInputs.price, scaleInputs.baseQuantity, scaleInputs.unit)
//
//        let priceStaticText = "Price"
//        let quantityStaticText = "Quantity"
//
//        priceInput.text = price.toString(2)
//
//        // .None with quantity 1 is the default doesn't need special labels TODO! review quantity 0 - validators aren't hindering users to enter this. Ensure quantity is never be 0 at least in lists (in inventory it may be allowed)
//        if unit == .None && (baseQuantity == 0 || baseQuantity == 1) {
//            priceLabel.text = priceStaticText
//            quantityLabel.text = quantityStaticText
//
//        } else { // entered custom units (or .None with a base quantity > 1, which doesn't make sense but who knows) - display custom labels
//            priceInput.text = price.toString(2)
//
//            // highlight shortly the updated unit infos
//            let priceText = "\(priceStaticText) (\(baseQuantity)\(unit.shortText))"
//            let quantityUnitText = unit == .None ? "" : " (\(unit.shortText))"
//            let quantityText = "\(quantityStaticText)\(quantityUnitText)"
//
//            if let priceUnitRange = priceText.firstRangeOfRegex("\\(.*\\)") {
//                priceLabel.attributedText = priceText.makeAttributed(priceUnitRange, normalFont: Fonts.verySmallLight, font: Fonts.verySmallBold)
//            }
//            if let quantityUnitRange = quantityText.firstRangeOfRegex("\\(.*\\)") {
//                quantityLabel.attributedText = quantityText.makeAttributed(quantityUnitRange, normalFont: Fonts.verySmallLight, font: Fonts.verySmallBold)
//            }
//
//            delay(2) {[weak self] in
//                self?.priceLabel.text = priceText
//                self?.quantityLabel.text = quantityText
//            }
//        }
//    }
//
//    func onDismissScaleViewController(cancelled: Bool) {
//        if let showingScaleController = showingScaleController {
//            dismissPopup(showingScaleController) {[weak self] in
//                if !cancelled {
//                    UIView.animateWithDuration(0.15) {
//                        self?.scaleButton.transform = CGAffineTransformMakeScale(2, 2)
//                        UIView.animateWithDuration(0.15) {
//                            self?.scaleButton.transform = CGAffineTransformMakeScale(1, 1)
//                        }
//                    }
//                }
//            }
//        }
//    }
///////////////////////////////////////////////////////////////////////////
}



// MARK: - ProductQuantityControlleDelegate

extension AddEditListItemViewController: ProductQuantityControlleDelegate {
    
    func units(_ handler: @escaping (Results<Providers.Unit>?) -> Void) {
        Prov.unitProvider.units(buyable: true, successHandler {units in
            handler(units)
        })
    }
    
    func addUnit(name: String, _ handler: @escaping ((unit: Providers.Unit, isNew: Bool)) -> Void) {
        Prov.unitProvider.getOrCreate(name: name, successHandler {tuple in
            handler(tuple)
        })
    }
    
    func deleteUnit(name: String, _ handler: @escaping (Bool) -> Void) {
        Prov.unitProvider.delete(name: name, successHandler {
            handler(true)
        })
    }
    
    
    func baseQuantities(_ handler: @escaping (RealmSwift.List<BaseQuantity>?) -> Void) {
        Prov.unitProvider.baseQuantities(successHandler {bases in
            handler(bases)
        })
    }
    
    func addBaseQuantity(val: Float, _ handler: @escaping (Bool) -> Void) {
        Prov.unitProvider.getOrCreate(baseQuantity: val, successHandler {tuple in
            handler(tuple.isNew)
        })
    }
    
    func deleteBaseQuantity(val: Float, _ handler: @escaping (Bool) -> Void) {
        Prov.unitProvider.delete(baseQuantity: val, successHandler {
            handler(true)
        })
    }
    
    
    var quantity: Float {
        return currentQuantity
    }
    
    func onSelect(unit: Providers.Unit) {
        currentUnit = unit.name
        currentUnitId = unit.id // This is needed for the unit image in the unit/base selection view
    }
    
    func onSelect(base: Float) {
        currentBase = base
    }
    
    func onChangeQuantity(quantity: Float) {
        currentQuantity = quantity
    }
    
    
    var parentForPickers: UIView {
        return self.view
    }
    
    // Returns if any child controller was showing (was closed)
    func closeChildControllers() -> Bool {
        let showingColorPicker = self.showingColorPicker
        dismissColorPicker(nil)
        return showingColorPicker != nil
    }
}



// MARK: - Touch

extension AddEditListItemViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    /// Tap to dismiss shouldn't block the autocompletion cells to receive touch
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if (touch.view.map{$0.hasAncestor(type: MyAutocompleteCell.self)} ?? false) {
            return false
        }
        return true
    }
}
