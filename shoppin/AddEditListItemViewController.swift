//
//  AddEditListItemViewController.swift
//  shoppin
//
//  Created by ischuetz on 20/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import SwiftValidator
import QorumLogs

protocol AddEditListItemViewControllerDelegate {
    
    func onValidationErrors(errors: [UITextField: ValidationError])
    
    func onOkTap(price: Float, quantity: Int, section: String, sectionColor: UIColor, note: String?, baseQuantity: Float, unit: StoreProductUnit, brand: String, editingItem: Any?)
    
    func parentViewForAddButton() -> UIView?
    
    func addEditSectionOrCategoryColor(name: String, handler: UIColor? -> Void)
    
    func onRemovedSectionCategoryName(name: String)
    func onRemovedBrand(name: String)
    
//    func productNameAutocompletions(text: String, handler: [String] -> Void)
//    func sectionNameAutocompletions(text: String, handler: [String] -> Void)
//    func storeNameAutocompletions(text: String, handler: [String] -> Void)
    
    
//    func planItem(productName: String, handler: PlanItem? -> ())
}

// FIXME use instead a "fragment" (custom view) with the common inputs and use this in 2 separate view controllers
// then we can also use different delegates, now the delegate is passed "note" parameter for group item as well where it doesn't exist, not nice
enum AddEditListItemControllerModus {
    case ListItem, GroupItem, PlanItem, Product
}

typealias AddEditItemInput2 = (name: String, price: Float, quantity: String, category: String, categoryColor: UIColor, sectionName: String, note: String?, baseQuantity: Float, unit: ProductUnit)

struct AddEditItem {
    let product: Product
    let storeProduct: StoreProduct? // TODO? no redundancy with product
    let quantity: Int
    let sectionName: String
    let sectionColor: UIColor
    let note: String?
    let model: Any
    
    init(product: Product, storeProduct: StoreProduct? = nil, quantity: Int, sectionName: String, sectionColor: UIColor, note: String?, model: Any) {
        self.product = product
        self.storeProduct = storeProduct
        self.quantity = quantity
        self.sectionName = sectionName
        self.sectionColor = sectionColor
        self.note = note
        self.model = model
    }
    
    init(item: ListItem) {
        self.product = item.product.product
        self.storeProduct = item.product
        self.quantity = item.todoQuantity // only in todo screen we can update items. Note that we will update only the todo quantity, if the item is also in cart or stash this quantities are not updated
        self.sectionName = item.section.name
        self.sectionColor = item.section.color
        self.note = item.note
        self.model = item
    }
    
    init(item: GroupItem) {
        self.product = item.product
        self.storeProduct = nil
        self.quantity = item.quantity
        self.sectionName = item.product.category.name
        self.sectionColor = item.product.category.color
        self.note = nil
        self.model = item
    }
    
    init(item: InventoryItem) {
        self.product = item.product
        self.storeProduct = nil
        self.quantity = item.quantity
        self.sectionName = item.product.category.name
        self.sectionColor = item.product.category.color
        self.note = nil
        self.model = item
    }
    
    init(item: AddEditProductControllerEditingData) {
        self.product = item.product
        self.storeProduct = nil
        self.quantity = 0
        self.sectionName = item.product.category.name
        self.sectionColor = item.product.category.color
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

    @IBOutlet weak var quantityInput: LineTextField!

    @IBOutlet weak var titleLabel: UILabel!

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

    
    var delegate: AddEditListItemViewControllerDelegate?
    
    private var showingColorPicker: FlatColorPickerController?
    private var showingNoteInputPopup: SimpleInputPopupController?
    
    var editingItem: AddEditItem? {
        didSet {
            if let editingItem = editingItem {
                prefill(editingItem)
            } else {
                QL3("Setting updatingListItem before outlets are set")
            }
        }
    }

    // when the view controller is used in .PlanItem modus... // FIXME besser structure
    var editingPlanItem: PlanItem? {
        didSet {
            if let editingPlanItem = editingPlanItem {
                prefill(editingPlanItem)
                titleLabel.text = "Edit item"
            } else {
                QL3("Setting updatingListItem before outlets are set")
            }
        }
    }
    
    var modus: AddEditListItemControllerModus = .ListItem {
        didSet {
            if let noteInput = noteInput {
                
                let isListItem = modus == .ListItem
                noteInput.hidden = !isListItem
                priceInput.hidden = !isListItem
                
//                let sectionText = "Section"
//                let categoryText = "Category"
                let sectionPlaceHolderText = "List section"
                let categoryPlaceHolderText = "Category"
                
                switch modus {
                case .ListItem:
                    fallthrough
                case .GroupItem:
//                    sectionLabel.text = sectionText
                    sectionInput.placeholder = sectionPlaceHolderText
                case .PlanItem:
//                    sectionLabel.text = categoryText // plan items don't have section, but we need a category for the new product (note for list and group items we save the section as category - user can change the category later using the product manager. This is for simple usability, mostly section == category otherwise interface may be a bit confusing)
                    sectionInput.placeholder = categoryPlaceHolderText
                case .Product:
//                    sectionLabel.text = categoryText
                    sectionInput.placeholder = categoryPlaceHolderText
//                    quantityLabel.hidden = true
                    quantityInput.hidden = true
//                    quantityPlusButton.hidden = true
//                    quantityMinusButton.hidden = true
                }
            } else {
                print("Error: Trying to set modus before outlet is initialised")
            }
        }
    }
    
    var open: Bool = false
    
    private var validator: Validator?
    
    // TODO improve this, it's finicky.
    var onViewDidLoad: VoidFunction? // Called on view did load before custom logic, use e.g. to set mode from which other methods called in viewDidLoad may depend.
    var onDidLoad: VoidFunction? // Called on view did load at the end
    
    private var addButtonHelper: AddButtonHelper?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // order is important in these methods, first the "static" ones (don't depend on anything), then onViewDidLoad, which may be used to set the mode, then the rest...
        
        setInputsDefaultValues()
        initTextFieldPlaceholders()
        initAutocompletionTextFields()
        
        onViewDidLoad?()
        
        initValidator()
        
        view.clipsToBounds = true
        
        initStaticLabels()

        addButtonHelper = initAddButtonHelper()
        
        onDidLoad?()
//        updatePlanLeftQuantity(0) // no quantity yet -> 0
    }
    
    private func initAddButtonHelper() -> AddButtonHelper? {
        guard let parentViewForAddButton = delegate?.parentViewForAddButton() else {QL4("No delegate: \(delegate)"); return nil}
        let addButtonHelper = AddButtonHelper(parentView: parentViewForAddButton) {[weak self] in guard let weakSelf = self else {return}
            weakSelf.submit()
        }
        return addButtonHelper
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        addButtonHelper?.addObserver()
        addButtonHelper?.animateVisible(true)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        addButtonHelper?.removeObserver()
    }
    
    private func initStaticLabels() {
        addNewItemLabel.font = DimensionsManager.font(.Regular, fontType: .Regular)
        addNewItemLabel.text = "Add new item"
    }
    
    private func prefill(item: AddEditItem) {
        brandInput.text = item.product.brand
        sectionInput.text = item.sectionName ?? item.product.category.name
        sectionColorButton.textColor = item.sectionColor ?? item.product.category.color
        quantityInput.text = String(item.quantity)
        priceInput.text = item.storeProduct?.price.toString(2)
        noteInput.text = item.note
    }
    
    private func initTextFieldPlaceholders() {
        for (textField, placeholder) in [
            (brandInput, "Brand"),
            (sectionInput, "Section"),
            (quantityInput, "Quantity"),
            (priceInput, "Price"),
            (noteInput, "Note")
            ] {
            textField.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: [NSForegroundColorAttributeName: UIColor.grayColor()])
        }
    }
    
    private func initAutocompletionTextFields() {
        for textField in [brandInput, sectionInput] {
            textField.defaultAutocompleteStyle()
            textField.myDelegate = self
        }
    }

    private func prefill(planItem: PlanItem) {
        brandInput.text = planItem.product.brand
        sectionInput.text = planItem.product.category.name
        sectionColorButton.textColor = planItem.product.category.color
        quantityInput.text = String(planItem.quantity)
    }
    
    private func setInputsDefaultValues() {
        quantityInput.text = "1"
    }
    
    private func initValidator() {
        let validator = Validator()
        validator.registerField(sectionInput, rules: [MinLengthRule(length: 1, message: "validation_section_name_not_empty")])
        validator.registerField(quantityInput, rules: [MinLengthRule(length: 1, message: "validation_quantity_not_empty"), FloatRule(message: "validation_quantity_number")])

        if modus == .ListItem {
            validator.registerField(priceInput, rules: [MinLengthRule(length: 1, message: "validation_price_not_empty"), FloatRule(message: "validation_price_number")])
        }
        self.validator = validator
    }
    
    // Parameter action is only relevant for add case - in edit it's expected to be always "Ok" (since edit has only ok button) and ignored.
//    func submit(action: AddEditListItemViewControllerAction) {
    func submit() {
        guard validator != nil else {return}
        
        if let errors = validator?.validate() {
            for (field, _) in errors {
                field.showValidationError()
                delegate?.onValidationErrors(errors)
            }
            
        } else {
            if let lastErrors = validator?.lastErrors {
                for (field, _) in lastErrors {
                    field.clearValidationError()
                }
            }
            
            // For some items (e.g. group items) we don't have a price but our current implementation expects one so we just pass 0 in these case (it will not be used). // TODO improve
            let priceMaybe: Float? = {
                if modus == .ListItem {
                    return priceInput.text?.floatValue
                } else {
                    return 0
                }
            }()
            
            if let price = priceMaybe, quantityText = quantityInput.text, quantity = Int(quantityText), section = sectionInput.text, brand = brandInput.text, note = noteInput.text, sectionColor = sectionColorButton.textColor {
                
                // for now disabled due to new designs
//                let baseQuantity = scaleInputs?.baseQuantity ?? 1
//                let unit = scaleInputs?.unit ?? .None
                let baseQuantity: Float = 1
                let unit = StoreProductUnit.None
                
                // the price from scaleInputs is inserted in price field, so we have it already
                
                // Explanation category/section name: for list items, the section input refers to the list item's section. For the rest the product category. When we store the list items, if a category with the entered section name doesn't exist yet, one is created with the section's data.
                delegate?.onOkTap(price, quantity: quantity, section: section, sectionColor: sectionColor, note: note, baseQuantity: baseQuantity, unit: unit, brand: brand, editingItem: editingItem?.model)
                
            } else {
                QL4("Validation was not implemented correctly, price: \(priceInput.text), quantity: \(quantityInput.text), section: \(sectionInput.text), brand: \(brandInput.text), sectionColor: \(sectionColorButton.textColor)")
            }
        }
    }
    
    // Focus next input field when user presses "Next" on keypad
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        view.endEditing(true)
        switch textField {
        case sectionInput:
            priceInput.becomeFirstResponder()
        case priceInput:
            quantityInput.becomeFirstResponder()
        case _: break
        }
        
        return true
    }
    
    func clearInputs() {
        for field in [sectionInput, quantityInput, priceInput] {
            field.text = ""
        }
    }
    
    func dismissKeyboard(sender: AnyObject?) {
        for field in [sectionInput, quantityInput, priceInput] {
            field.resignFirstResponder()
        }
    }
    
    // MARK: - MLPAutoCompleteTextFieldDataSource
    
    func autoCompleteTextField(textField: MLPAutoCompleteTextField!, possibleCompletionsForString string: String!, completionHandler handler: (([AnyObject]!) -> Void)!) {
        switch textField {
        case sectionInput:
            switch modus {
            case .ListItem:
                Providers.sectionProvider.sectionSuggestionsContainingText(string, successHandler{suggestions in
                    handler(suggestions)
                })
            default:
                Providers.productCategoryProvider.categoriesContainingText(string, successHandler{categories in
                    let suggestions = categories.map{$0.name}.distinct()
                    handler(suggestions)
                })
            }

        case brandInput:
            Providers.brandProvider.brandsContainingText(string, successHandler{brands in
                handler(brands)
            })
        case _:
            print("Error: Not handled text field in autoCompleteTextField")
            break
        }
    }
    
    // MARK: - MLPAutoCompleteTextFieldDelegate
    
    // TODO remove this?
    func autoCompleteTextField(textField: MLPAutoCompleteTextField!, didSelectAutoCompleteString selectedString: String!, withAutoCompleteObject selectedObject: MLPAutoCompletionObject!, forRowAtIndexPath indexPath: NSIndexPath!) {

        if textField == sectionInput {
            delegate?.addEditSectionOrCategoryColor(selectedString) {[weak self] colorMaybe in
                self?.sectionColorButton.textColor = colorMaybe ?? {
                    QL4("Invalid state: selected a section or category suggestion and there's no color.")
                    return UIColor.blackColor()
                }()
            }
        }
    }

    
    @IBAction func onSectionColorButtonTap(sender: UIButton) {
    
        let picker = UIStoryboard.listColorPicker()
        showPopup(sectionColorButton, controller: picker) {[weak self] in
            if let weakSelf = self {
                picker.delegate = weakSelf
                weakSelf.showingColorPicker = picker
            }
        }
    }
    
    private func showPopup(button: UIView, controller: UIViewController, topOffset: CGFloat = 0, width: CGFloat? = nil, height: CGFloat? = nil, onWillShow: VoidFunction) {
        
        if let windowView = UIApplication.sharedApplication().keyWindow { // add popup and overlay on top of everything
            
            // TODO dynamic
            let topBarHeight: CGFloat = 64
            let tabBarHeight: CGFloat = 49
            
            let x: CGFloat = {
                if let width = width {
                    return (windowView.frame.width - width) / 2
                } else {
                    return 0
                }
            }()
            
            let w = width ?? windowView.frame.width
            let h = height ?? (windowView.frame.height - topBarHeight - tabBarHeight)
            controller.view.frame = CGRectMake(x, topBarHeight + topOffset, w, h)
            
            windowView.addSubview(controller.view)
            
            let buttonPointInParent = windowView.convertPoint(CGPointMake(button.center.x, button.center.y - topBarHeight), fromView: view)
            let fractionX = (buttonPointInParent.x - ((windowView.frame.width - w) / 2)) / w
            let fractionY = buttonPointInParent.y / h
            
            controller.view.layer.anchorPoint = CGPointMake(fractionX, fractionY)
            
            controller.view.frame = CGRectMake(x, topBarHeight + topOffset, w, h)
            
            controller.view.transform = CGAffineTransformMakeScale(0, 0)
            
            onWillShow()
            
            UIView.animateWithDuration(0.3) {
                controller.view.transform = CGAffineTransformMakeScale(1, 1)
            }
            
        } else {
            print("Warn: AddEditListItemViewController.onSectionColorButtonTap: unexpected: no window")
        }
    }
    
    
    // MARK: - FlatColorPickerControllerDelegate
    
    func onColorPicked(color: UIColor) {
        dismissColorPicker(color)
    }
    
    func onDismiss() {
        dismissColorPicker(nil) // not used see FIXME in FlatColorPickerController.viewDidLoad
    }
    
    private func dismissColorPicker(selectedColor: UIColor?) {
        if let showingColorPicker = showingColorPicker {
            
            dismissPopup(showingColorPicker) {
                self.showingColorPicker = nil
                self.showingColorPicker?.removeFromParentViewControllerWithView()
                
                UIView.animateWithDuration(0.3) {
                    if let selectedColor = selectedColor {
                        self.sectionColorButton.textColor = selectedColor
                    }
                }
//                UIView.animateWithDuration(0.15) {
//                    self.sectionColorButton.transform = CGAffineTransformMakeScale(2, 2)
//                    UIView.animateWithDuration(0.15) {
//                        self.sectionColorButton.transform = CGAffineTransformMakeScale(1, 1)
//                    }
//                }
            }
        }
    }
    
    private func dismissPopup(controller: UIViewController, onComplete: VoidFunction? = nil) {
        UIView.animateWithDuration(0.3, animations: {
            controller.view.transform = CGAffineTransformMakeScale(0.001, 0.001)
            }, completion: {finished in
                controller.view.removeFromSuperview()
                onComplete?()
            }
        )
    }
    
    // MARK: - MyAutoCompleteTextFieldDelegate
    
    func onDeleteSuggestion(string: String, sender: MyAutoCompleteTextField) {
        switch sender {
        case sectionInput:
            ConfirmationPopup.show(title: "Confirmation", message: "Do you want to remove '\(string)'?\nThis will remove all sections and categories with this name and associated list, group, inventory and history items everywhere in the app.", okTitle: "Yes", cancelTitle: "No", controller: self, onOk: {[weak self] in guard let weakSelf = self else {return}
                Providers.sectionProvider.removeAllWithName(string, remote: true, weakSelf.successHandler {
                    Providers.productCategoryProvider.removeAllCategoriesWithName(string, remote: true, weakSelf.successHandler {
                        self?.delegate?.onRemovedSectionCategoryName(string)
                        AlertPopup.show(message: "'\(string)' was removed.", controller: weakSelf)
                    })
                })
            })
        case brandInput:
            ConfirmationPopup.show(title: "Confirmation", message: "Do you want to remove '\(string)'?\nThis will remove all products with this brand and associated list, group, inventory and history items everywhere in the app.", okTitle: "Yes", cancelTitle: "No", controller: self, onOk: {[weak self] in guard let weakSelf = self else {return}
                Providers.brandProvider.removeProductsWithBrand(string, remote: true, weakSelf.successHandler {
                    self?.delegate?.onRemovedBrand(string)
                    AlertPopup.show(message: "'\(string)' was removed.", controller: weakSelf)
                })
            })
        default: QL4("Not handled input")
        }
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