//
//  AddEditListItemViewController.swift
//  shoppin
//
//  Created by ischuetz on 20/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import SwiftValidator


protocol AddEditListItemViewControllerDelegate {
    
    func onValidationErrors(errors: [UITextField: ValidationError])
    
    func onOkTap(name: String, price: String, quantity: String, category: String, categoryColor: UIColor, sectionName: String, note: String?, baseQuantity: Float, unit: ProductUnit)
    func onOkAndAddAnotherTap(name: String, price: String, quantity: String, category: String, categoryColor: UIColor, sectionName: String, note: String?, baseQuantity: Float, unit: ProductUnit)
    func onUpdateTap(name: String, price: String, quantity: String, category: String, categoryColor: UIColor, sectionName: String, note: String?, baseQuantity: Float, unit: ProductUnit)
    func onCancelTap()
    
    func productNameAutocompletions(text: String, handler: [String] -> ())
    func sectionNameAutocompletions(text: String, handler: [String] -> ())
    
    func planItem(productName: String, handler: PlanItem? -> ())
}

enum AddEditListItemViewControllerAction {
    case AddAndAddAnother, Add, Update
}

class AddEditListItemViewController: UIViewController, UITextFieldDelegate, MLPAutoCompleteTextFieldDataSource, MLPAutoCompleteTextFieldDelegate, ScaleViewControllerDelegate, FlatColorPickerControllerDelegate {

    @IBOutlet weak var nameInput: UITextField!
    @IBOutlet weak var sectionLabel: UILabel!
    @IBOutlet weak var sectionInput: MLPAutoCompleteTextField!
    @IBOutlet weak var sectionColorButton: UIButton!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var priceInput: UITextField!
    @IBOutlet weak var quantityLabel: UILabel!
    @IBOutlet weak var quantityInput: UITextField!
    
    @IBOutlet weak var noteLabel: UILabel!
    @IBOutlet weak var noteInput: UITextField!
    
    @IBOutlet weak var planInfoButton: UIButton!
    
    @IBOutlet weak var scaleButton: UIButton!
    
    private var scaleInputs: ProductScaleData?
    
    var delegate: AddEditListItemViewControllerDelegate?
    
    private var showingColorPicker: FlatColorPickerController?

    var planItem: PlanItem? {
        didSet {
            onQuantityChanged()
        }
    }
    
    var updatingListItem: ListItem? {    
        didSet {
            if let updatingListItem = updatingListItem {
                prefill(updatingListItem)
            } else {
                print("Warn: AddEditListItemViewController.updatingListItem: Setting updatingListItem before outlets are set")
            }
        }
    }

    // when the view controller is used in .PlanItem modus... // FIXME besser structure
    var updatingPlanItem: PlanItem? {
        didSet {
            if let updatingPlanItem = updatingPlanItem {
                prefill(updatingPlanItem)
            } else {
                print("Warn: AddEditListItemViewController.updatingPlanItem: Setting updatingListItem before outlets are set")
            }
        }
    }
    
    var modus: AddEditListItemControllerModus = .ListItem {
        didSet {
            if let noteInput = noteInput {
                noteInput.hidden = modus == .GroupItem
                
                let showNote = modus == .ListItem
                noteInput.hidden = !showNote
                noteLabel.hidden = !showNote
                
                let sectionText = "Section"
                let categoryText = "Category"
                let sectionPlaceHolderText = "Section (e.g. vegetables)"
                let categoryPlaceHolderText = "Category (e.g. vegetables)"
                
                switch modus {
                case .ListItem:
                    fallthrough
                case .GroupItem:
                    sectionLabel.text = sectionText
                    sectionInput.placeholder = sectionPlaceHolderText
                case .PlanItem:
                    sectionLabel.text = categoryText // plan items don't have section, but we need a category for the new product (note for list and group items we save the section as category - user can change the category later using the product manager. This is for simple usability, mostly section == category otherwise interface may be a bit confusing)
                    sectionInput.placeholder = categoryPlaceHolderText
                }
            } else {
                print("Error: Trying to set modus before outlet is initialised")
            }
        }
    }
    
    var open: Bool = false
    
    private var validator: Validator?
    
    var onViewDidLoad: VoidFunction?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        onViewDidLoad?()
        
        initValidator()
        
        setInputsDefaultValues()
        
        updatePlanLeftQuantity(0) // no quantity yet -> 0
    }
    
    private func prefill(listItem: ListItem) {
        nameInput.text = listItem.product.name
        sectionInput.text = listItem.section.name
        sectionColorButton.tintColor = listItem.product.category.color
        sectionColorButton.imageView?.tintColor = listItem.product.category.color
        quantityInput.text = String(listItem.quantity)
        priceInput.text = listItem.product.price.toString(2)
        noteInput.text = listItem.note
    }

    private func prefill(planItem: PlanItem) {
        nameInput.text = planItem.product.name
        sectionInput.text = planItem.product.category.name
        sectionColorButton.tintColor = planItem.product.category.color
        sectionColorButton.imageView?.tintColor = planItem.product.category.color
        quantityInput.text = String(planItem.quantity)
        priceInput.text = planItem.product.price.toString(2)
    }
    
    private func setInputsDefaultValues() {
        quantityInput.text = "1"
    }
    
    private func initValidator() {
        let validator = Validator()
        validator.registerField(nameInput, rules: [MinLengthRule(length: 1, message: "validation_item_name_not_empty")])
        validator.registerField(sectionInput, rules: [MinLengthRule(length: 1, message: "validation_section_name_not_empty")])
        validator.registerField(priceInput, rules: [MinLengthRule(length: 1, message: "validation_price_not_empty"), FloatRule(message: "validation_price_number")])
        validator.registerField(quantityInput, rules: [MinLengthRule(length: 1, message: "validation_quantity_not_empty"), FloatRule(message: "validation_quantity_number")])
        self.validator = validator
    }
    
    // Parameter action is only relevant for add case - in edit it's expected to be always "Ok" (since edit has only ok button) and ignored.
    func submit(action: AddEditListItemViewControllerAction) {
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
            
            // TODO new input field for section,
            if let text = nameInput.text, priceText = priceInput.text, quantityText = quantityInput.text, category = sectionInput.text {
                
                let baseQuantity = scaleInputs?.baseQuantity ?? 1
                let unit = scaleInputs?.unit ?? .None
                // the price from scaleInputs is inserted in price field, so we have it already
                
                switch action {
                case .Add:
                    delegate?.onOkTap(text, price: priceText, quantity: quantityText, category: category, categoryColor: sectionColorButton.tintColor, sectionName: category, note: noteInput.text, baseQuantity: baseQuantity, unit: unit)
                case .AddAndAddAnother:
                    delegate?.onOkAndAddAnotherTap(text, price: priceText, quantity: quantityText, category: category, categoryColor: sectionColorButton.tintColor, sectionName: category, note: noteInput.text, baseQuantity: baseQuantity, unit: unit)
                case .Update:
                    delegate?.onUpdateTap(text, price: priceText, quantity: quantityText, category: category, categoryColor: sectionColorButton.tintColor, sectionName: category, note: noteInput.text, baseQuantity: baseQuantity, unit: unit)
                }
                
            } else {
                print("Error: validation was not implemented correctly")
            }
        }
    }
    
    // Focus next input field when user presses "Next" on keypad
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        view.endEditing(true)
        switch textField {
        case nameInput:
            sectionInput.becomeFirstResponder()
        case sectionInput:
            priceInput.becomeFirstResponder()
        case priceInput:
            quantityInput.becomeFirstResponder()
        case _: break
        }
        
        return true
    }
    
    func clearInputs() {
        for field in [nameInput, sectionInput, quantityInput, priceInput] {
            field.text = ""
        }
    }
    
    func dismissKeyboard(sender: AnyObject?) {
        for field in [nameInput, sectionInput, quantityInput, priceInput] {
            field.resignFirstResponder()
        }
    }
    
    @IBAction func productNameEditingDidEnd(sender: AnyObject) {
        if let text = nameInput.text {
            onNameInputChange(text)
        } else {
            print("Error: unexpected, text field with no text")
        }
    }
    
    private func onNameInputChange(text: String) {
        delegate?.planItem(text) {[weak self] planItemMaybe in
            self?.planItem = planItemMaybe
        }
    }
    
    @IBAction func productNameEditingDidChange(sender: AnyObject) {
        let text = nameInput.text ?? ""
        onNameInputChange(text)
    }
    
    @IBAction func quantityEditingDidChange(sender: AnyObject) {
        onQuantityChanged()
    }
    
    func onQuantityChanged() {
        if let text = quantityInput.text, quantity = Int(text) {
            updatePlanLeftQuantity(quantity)
        } else {
            print("Error: Invalid quantity input")
        }
    }
    
    private func updatePlanLeftQuantity(inputQuantity: Int) {
        if let planItem = planItem {
            let planItemLeftQuantity = planItem.quantity - planItem.usedQuantity
            let updatedLeftQuantity = planItemLeftQuantity - inputQuantity

            // default
            planInfoButton.setTitleColor(UIColor.darkTextColor(), forState: .Normal)
            planInfoButton.titleLabel?.font = Fonts.verySmallLight
            
            if planItemLeftQuantity <= 0 {
                if planItemLeftQuantity == 0 {
                    planInfoButton.setTitle("\(updatedLeftQuantity) left", forState: .Normal)
                } else {
                    planInfoButton.setTitle("\(abs(updatedLeftQuantity)) overflow!", forState: .Normal)
                    planInfoButton.titleLabel?.font = Fonts.verySmallBold
                }
                planInfoButton.setTitleColor(UIColor.redColor(), forState: .Normal)
            } else {
                planInfoButton.setTitle("\(updatedLeftQuantity) left", forState: .Normal)

            }
            
        } else { // item is not planned -  don't show anything (no limits)
            planInfoButton.setTitle("", forState: .Normal)
        }
    }
    
    func showPlanItem(planItem: PlanItem) {
        planInfoButton.setTitle("\(planItem.quantity - planItem.usedQuantity) left", forState: .Normal)
    }
    
    // MARK: - MLPAutoCompleteTextFieldDataSource
    
    func autoCompleteTextField(textField: MLPAutoCompleteTextField!, possibleCompletionsForString string: String!, completionHandler handler: (([AnyObject]!) -> Void)!) {
        switch textField {
        case nameInput:
            delegate?.productNameAutocompletions(string) {completions in
                // don't use autocompletions for product - now that there's quick add, the only reason the user is here is because we don't have the product, so autocompletion doesn't make sense
//                handler(completions)
            }
        case sectionInput:
            delegate?.sectionNameAutocompletions(string) {completions in
                handler(completions)
            }
        case _:
            print("Error: Not handled text field in autoCompleteTextField")
            break
        }
    }
    
    // MARK: - MLPAutoCompleteTextFieldDelegate
    
    func autoCompleteTextField(textField: MLPAutoCompleteTextField!, didSelectAutoCompleteString selectedString: String!, withAutoCompleteObject selectedObject: MLPAutoCompletionObject!, forRowAtIndexPath indexPath: NSIndexPath!) {
        onNameInputChange(selectedString)
    }
    
    // MARK: -
    
    @IBAction func onQuantityPlusTap(button: UIButton) {
        if let quantityText = quantityInput.text, quantity = Int(quantityText) {
            quantityInput.text = "\(quantity + 1)"
        } else {
            quantityInput.text = "1"
        }
    }
    
    @IBAction func onQuantityMinusTap(button: UIButton) {
        if let quantityText = quantityInput.text, quantity = Int(quantityText) {
            quantityInput.text = "\(quantity - 1)"
        }
    }
    
    
    private var showingScaleController: ScaleViewController?
    private var overlay: UIView?
    
    @IBAction func onScaleTap(button: UIButton) {

        if let windowView = UIApplication.sharedApplication().keyWindow { // add popup and overlay on top of everything
            
            let scaleController = UIStoryboard.scaleViewController()
            
            let overlay = UIButton(frame: CGRectMake(0, 0, 400, 700))
            overlay.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.3)
            self.overlay = overlay
            overlay.addTarget(self, action: "onOverlayTap:", forControlEvents: .TouchUpInside)
            
            let w: CGFloat = 280
            let h: CGFloat = 300
            let top: CGFloat = 200
            scaleController.view.frame = CGRectMake((view.frame.width - w) / 2, top, w, h)
            
            overlay.alpha = 0
            windowView.addSubview(overlay)
            windowView.addSubview(scaleController.view)
            
            scaleController.delegate = self
            showingScaleController = scaleController

            let prefillScaleInputs = ProductScaleData(
                price: priceInput.text?.floatValue ?? 0, // current price input
                baseQuantity: scaleInputs?.baseQuantity ?? 1, // if no scale input has been done yet - default quantity is 1
                unit: scaleInputs?.unit ?? .None // if no scale input has been done yet - default unit is 1
            )
            scaleController.prefill(prefillScaleInputs)
            
            // set anchor point such that popup start at button's center
            let buttonCenterInPopup = scaleController.view.convertPoint(CGPointMake(scaleButton.center.x, scaleButton.center.y), fromView: view)
            let fractionX = buttonCenterInPopup.x / w
            let fractionY = buttonCenterInPopup.y / h
            scaleController.view.layer.anchorPoint = CGPointMake(fractionX, fractionY)
            
            scaleController.view.frame = CGRectMake((view.frame.width - w) / 2, top, w, h)
            scaleController.view.transform = CGAffineTransformMakeScale(0, 0)
            
            UIView.animateWithDuration(0.3) {
                scaleController.view.transform = CGAffineTransformMakeScale(1, 1)
                overlay.alpha = 1
            }
            
        } else {
            print("Warn: AddEditListItemViewController.onScaleTap: unexpected: no window")
        }
    }
    
    func onOverlayTap(sender: UIButton) {
        dismissScaleControllerIfShowing()
    }
    
    private func dismissScaleControllerIfShowing() {
        if let showingScaleController = showingScaleController {
            UIView.animateWithDuration(0.3, animations: {[weak self] in
                showingScaleController.view.transform = CGAffineTransformMakeScale(0.001, 0.001)
                self?.overlay?.alpha = 0
                }, completion: {finished in
                    self.showingScaleController = nil
                    self.showingScaleController?.view.removeFromSuperview()
                    
                    self.overlay?.removeFromSuperview()
                    self.overlay = nil
                }
            )
        }
    }
    
    // MARK: - ScaleViewControllerDelegate
    
    func onScaleViewControllerValidationErrors(errors: [UITextField : ValidationError]) {
        presentViewController(ValidationAlertCreator.create(errors), animated: true, completion: nil)
    }
    
    func onScaleViewControllerSubmit(scaleInputs: ProductScaleData) {
        
        dismissScaleControllerIfShowing()

        self.scaleInputs = scaleInputs

        let (price, baseQuantity, unit) = (scaleInputs.price, scaleInputs.baseQuantity, scaleInputs.unit)
        
        let priceStaticText = "Price"
        let quantityStaticText = "Quantity"
        
        priceInput.text = price.toString(2)

        // .None with quantity 1 is the default doesn't need special labels TODO! review quantity 0 - validators aren't hindering users to enter this. Ensure quantity is never be 0 at least in lists (in inventory it may be allowed)
        if unit == .None && (baseQuantity == 0 || baseQuantity == 1) {
            priceLabel.text = priceStaticText
            quantityLabel.text = quantityStaticText
            
        } else { // entered custom units (or .None with a base quantity > 1, which doesn't make sense but who knows) - display custom labels
            priceInput.text = price.toString(2)
            
            // highlight shortly the updated unit infos
            let priceText = "\(priceStaticText) (\(baseQuantity)\(unit.shortText))"
            let quantityUnitText = unit == .None ? "" : " (\(unit.shortText))"
            let quantityText = "\(quantityStaticText)\(quantityUnitText)"
            
            if let priceUnitRange = priceText.firstRangeOfRegex("\\(.*\\)") {
                priceLabel.attributedText = priceText.makeAttributed(priceUnitRange, normalFont: Fonts.verySmallLight, font: Fonts.verySmallBold)
            }
            if let quantityUnitRange = quantityText.firstRangeOfRegex("\\(.*\\)") {
                quantityLabel.attributedText = quantityText.makeAttributed(quantityUnitRange, normalFont: Fonts.verySmallLight, font: Fonts.verySmallBold)
            }

            delay(2) {[weak self] in
                self?.priceLabel.text = priceText
                self?.quantityLabel.text = quantityText
            }
        }
    }
    
    @IBAction func onSectionColorButtonTap(sender: UIButton) {
    
        if let windowView = UIApplication.sharedApplication().keyWindow { // add popup and overlay on top of everything

            let picker = UIStoryboard.listColorPicker()

            // TODO dynamic
            let topBarHeight: CGFloat = 64
            let tabBarHeight: CGFloat = 49
            
            picker.view.frame = CGRectMake(0, topBarHeight, windowView.frame.width, windowView.frame.height - topBarHeight - tabBarHeight)
         
            windowView.addSubview(picker.view)
            picker.delegate = self
            showingColorPicker = picker
            
            let buttonPointInParent = windowView.convertPoint(CGPointMake(sectionColorButton.center.x, sectionColorButton.center.y - topBarHeight), fromView: view)
            let fractionX = buttonPointInParent.x / windowView.frame.width
            let fractionY = buttonPointInParent.y / (windowView.frame.height - topBarHeight - tabBarHeight)
            
            picker.view.layer.anchorPoint = CGPointMake(fractionX, fractionY)
            
            picker.view.frame = CGRectMake(0, topBarHeight, windowView.frame.width, windowView.frame.height - topBarHeight - tabBarHeight)

            picker.view.transform = CGAffineTransformMakeScale(0, 0)

            UIView.animateWithDuration(0.3) {
                picker.view.transform = CGAffineTransformMakeScale(1, 1)
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
            
            UIView.animateWithDuration(0.3, animations: {
                showingColorPicker.view.transform = CGAffineTransformMakeScale(0.001, 0.001)
                
                }, completion: {finished in
                    self.showingColorPicker = nil
                    self.showingColorPicker?.removeFromParentViewControllerWithView()
                    
                    UIView.animateWithDuration(0.3) {
                        if let selectedColor = selectedColor {
                            self.sectionColorButton.tintColor = selectedColor
                            self.sectionColorButton.imageView?.tintColor = selectedColor
                        }
                    }
                    UIView.animateWithDuration(0.15) {
                        self.sectionColorButton.transform = CGAffineTransformMakeScale(2, 2)
                        UIView.animateWithDuration(0.15) {
                            self.sectionColorButton.transform = CGAffineTransformMakeScale(1, 1)
                        }
                    }
                }
            )
        }
    }
}