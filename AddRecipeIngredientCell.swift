//
//  AddRecipeIngredientCell.swift
//  shoppin
//
//  Created by Ivan Schuetz on 21/01/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import Providers
import QorumLogs
import RealmSwift

protocol AddRecipeIngredientCellDelegate {
    func getAlreadyHaveText(ingredient: Ingredient, _ handler: @escaping (String) -> Void)
    
    func onUpdate(productName: String, indexPath: IndexPath)
    func onUpdate(brand: String, indexPath: IndexPath)
    func onUpdate(quantity: Float, indexPath: IndexPath)
    func onUpdate(baseQuantity: String, indexPath: IndexPath)
    func onUpdate(unit: Providers.Unit, indexPath: IndexPath)
    
    func productNamesContaining(text: String, handler: @escaping ([String]) -> Void)
    func brandsContaining(text: String, handler: @escaping ([String]) -> Void)
    func baseQuantitiesContaining(text: String, handler: @escaping ([String]) -> Void)
    func unitsContaining(text: String, handler: @escaping ([String]) -> Void)
    
    func delete(productName: String, handler: @escaping () -> Void)
    func delete(brand: String, handler: @escaping () -> Void)
    func delete(unit: String, handler: @escaping () -> Void)
    func delete(baseQuantity: String, handler: @escaping () -> Void)
    
    
    func units(_ handler: @escaping (Results<Providers.Unit>?) -> Void)
    func addUnit(name: String, _ handler: @escaping (Bool) -> Void)
    func deleteUnit(name: String, _ handler: @escaping (Bool) -> Void)
    
    func baseQuantities(_ handler: @escaping (RealmSwift.List<BaseQuantity>?) -> Void)
    func addBaseQuantity(stringVal: String, _ handler: @escaping (Bool) -> Void)
    func deleteBaseQuantity(stringVal: String, _ handler: @escaping (Bool) -> Void)
}

typealias AddRecipeIngredientCellOptions = (brands: [String], units: Results<Providers.Unit>, baseQuantities: RealmSwift.List<BaseQuantity>) // TODO!!!!!!!!!!!!!!!!!! remove this

class AddRecipeIngredientCell: UITableViewCell {

    @IBOutlet weak var ingredientNameLabel: UILabel!
    
    @IBOutlet weak var productNameTextField: LineAutocompleteTextField!
    @IBOutlet weak var brandTextField: LineAutocompleteTextField!
    
    @IBOutlet weak var quantitySummaryLabel: UILabel!
    @IBOutlet weak var alreadyHaveLabel: UILabel!
    
    @IBOutlet weak var quantitiesContainer: UIView!
    
    fileprivate var productQuantityController: ProductQuantityController?
    
    var delegate: AddRecipeIngredientCellDelegate?
    var didMoveToSuperviewCalledOnce = false

    
    var indexPath: IndexPath?
    
    
    // MARK: -

    var model: AddRecipeIngredientModel? {
        didSet {
            ingredientNameLabel.text = model.map{"\($0.ingredient.quantity) x \($0.productPrototype.name)"}
            productNameTextField.text = model?.productPrototype.name
            brandTextField.text = model?.productPrototype.brand
            
            productQuantityController?.onPickersInitialized = {[weak self, weak productQuantityController] in
                if let prefillUnitName = self?.model?.productPrototype.unit {
                    productQuantityController?.selectUnitWithName(prefillUnitName)
                }
                if let prefillBase = self?.model?.productPrototype.baseQuantity {
                    productQuantityController?.selectBaseWithName(prefillBase)
                }
            }
            
            if let base = model?.productPrototype.baseQuantity {
                productQuantityController?.currentBaseInput = base
            }
            
            productQuantityController?.quantity = model?.quantity ?? 0
            
            updateQuantitySummary()
            
            initAlreadyHaveText()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    
        selectionStyle = .none
        
        initTextFieldPlaceholders()
        initAutocompletionTextFields()
        initTextListeners()
        
        configQuantifiablesView()
    }
    
    
    var options: AddRecipeIngredientCellOptions? {
        didSet {
            // TODO update autosuggestion/popover etc
        }
    }

    
    func focus() {
        productNameTextField.becomeFirstResponder()
    }
    
    
    func configQuantifiablesView() {
        let productQuantityController = ProductQuantityController()
        
        // TODO!!!!!!!!!!!!!!!!!!! is it correct to do this here (awake from nib) - does this work with recycled cells?
        productQuantityController.delegate = self
        
        productQuantityController.view.translatesAutoresizingMaskIntoConstraints = false
        productQuantityController.view.backgroundColor = UIColor.clear
        quantitiesContainer.addSubview(productQuantityController.view)
        productQuantityController.view.fillSuperview()
        
        self.productQuantityController = productQuantityController
    }
    
    func handleGlobalTap() {
        submitUnitOrBasePickers()
    }

    fileprivate func submitUnitOrBasePickers() {
        
        guard let productQuantityController = productQuantityController else {QL4("No product quantity controller"); return}
        
        productQuantityController.setUnitPickerOpen(false)
        productQuantityController.setBasesPickerOpen(false)
        
        if let currentUnitInput = productQuantityController.currentUnitInput, !currentUnitInput.isEmpty {
            delegate?.addUnit(name: currentUnitInput) {isNew in
                if isNew {
                    productQuantityController.appendNewUnitCell()
                }
                productQuantityController.currentUnitInput = nil
            }
        }
        
        if let currentBaseInput = productQuantityController.currentBaseInput, !currentBaseInput.isEmpty {
            delegate?.addBaseQuantity(stringVal: currentBaseInput) {isNew in
                if isNew {
                    productQuantityController.appendNewBaseCell()
                }
                productQuantityController.currentBaseInput = nil
            }
        }
    }
    
    // MARK: - Private
    
    fileprivate func updateQuantitySummary() {

        // TODO!!!!!!!!!!!!!!!!! user can enters any unit - don't use enum anymore
        
        let unitText = Ingredient.unitText(quantity: quantityInput, baseQuantity: baseQuantityInput.floatValue ?? 1, unitName: unitInput, showNoneText: true)
        let allUnitText = trans("recipe_you_will_add", unitText)
        quantitySummaryLabel.text = allUnitText
    }
    
    fileprivate func initAlreadyHaveText() {
        guard let model = model else {QL4("No model"); return}
        
        delegate?.getAlreadyHaveText(ingredient: model.ingredient) {text in
            self.alreadyHaveLabel.text = text
        }
    }
    
    fileprivate func initTextListeners() {
        for textField in [productNameTextField, brandTextField] {
            textField?.addTarget(self, action: #selector(onQuantityTextChange(_:)), for: .editingChanged)
        }
    }
    
    fileprivate func initAutocompletionTextFields() {
        for textField in [productNameTextField, brandTextField] {
            textField?.defaultAutocompleteStyle()
            textField?.myDelegate = self
        }
    }
    
    fileprivate func initTextFieldPlaceholders() {
        productNameTextField.attributedPlaceholder = NSAttributedString(string: productNameTextField.placeholder!, attributes: [NSForegroundColorAttributeName: UIColor.gray])
        brandTextField.attributedPlaceholder = NSAttributedString(string: brandTextField.placeholder!, attributes: [NSForegroundColorAttributeName: UIColor.gray])
    }
    
    func onQuantityTextChange(_ sender: UITextField) {
        updateQuantitySummary()
        
        guard let indexPath = indexPath else {QL4("Illegal state: no index path"); return}
        
        delegate?.onUpdate(productName: nameInput, indexPath: indexPath)
        delegate?.onUpdate(brand: brandInput, indexPath: indexPath)
        delegate?.onUpdate(quantity: quantityInput, indexPath: indexPath)
        delegate?.onUpdate(baseQuantity: baseQuantityInput, indexPath: indexPath)
    }
}

// MARK: - Inputs

extension AddRecipeIngredientCell {

    fileprivate var nameInput: String {
        return productNameTextField.text ?? ""
    }
    
    fileprivate var brandInput: String {
        return brandTextField.text ?? ""
    }
    
    fileprivate var quantityInput: Float {
        return productQuantityController?.quantity ?? 0
    }
    
    fileprivate var unitInput: String {
        return productQuantityController?.currentUnitInput ?? ""
    }
    
    fileprivate var baseQuantityInput: String {
        // NOTE: We convert to float and back to get correct format for realm (e.g. "1.0" instead of "1"). Since we store base quantity as strings, this is important. The reason of storing it as strings is that it's more efficient to search for autosuggestions, since we can let Realm search. On the other side the way we are handling it now is bad practice. TODO We should use floats until the object is stored to the Realm, where the float is converted to a string (in Provider) in a single place using a single formatter. This way we ensure consistency and also don't expose implementation details to the UI project. TODO is this note still valid after adding the base quantity picker?
        return productQuantityController?.currentBaseInput ?? ""
    }
}

extension AddRecipeIngredientCell: MLPAutoCompleteTextFieldDataSource, MLPAutoCompleteTextFieldDelegate, MyAutoCompleteTextFieldDelegate {
    
    // MARK: - MLPAutoCompleteTextFieldDataSource
    
    func autoCompleteTextField(_ textField: MLPAutoCompleteTextField!, possibleCompletionsFor string: String!, completionHandler handler: @escaping (([Any]?) -> Void)) {
        switch textField {
            
        case productNameTextField:
            delegate?.productNamesContaining(text: string) {productNames in
                handler(productNames)
            }
            
        case brandTextField:
            delegate?.brandsContaining(text: string) {brands in
                handler(brands)
            }

        case _:
            print("Error: Not handled text field in autoCompleteTextField")
            break
        }
    }

    
    // MARK: - MyAutoCompleteTextFieldDelegate
    
    func onDeleteSuggestion(_ string: String, sender: MyAutoCompleteTextField) {
        switch sender {
        case productNameTextField:
            delegate?.delete(productName: string) {
                self.productNameTextField.closeAutoCompleteTableView()
            }
            
        case brandTextField:
            delegate?.delete(brand: string) {
                self.brandTextField.closeAutoCompleteTableView()
            }

        default: QL4("Not handled input")
        }
    }
}

// MARK: - ProductQuantityControlleDelegate

extension AddRecipeIngredientCell: ProductQuantityControlleDelegate {
    
    func units(_ handler: @escaping (Results<Providers.Unit>?) -> Void) {
        delegate?.units(handler)
    }
    
    func addUnit(name: String, _ handler: @escaping (Bool) -> Void) {
        delegate?.addUnit(name: name, handler)
    }
    
    func deleteUnit(name: String, _ handler: @escaping (Bool) -> Void) {
        delegate?.deleteUnit(name: name, handler)
    }
    
    
    func baseQuantities(_ handler: @escaping (RealmSwift.List<BaseQuantity>?) -> Void) {
        delegate?.baseQuantities(handler)
    }
    
    func addBaseQuantity(stringVal: String, _ handler: @escaping (Bool) -> Void) {
        delegate?.addBaseQuantity(stringVal: stringVal, handler)
    }
    
    func deleteBaseQuantity(stringVal: String, _ handler: @escaping (Bool) -> Void) {
        delegate?.deleteBaseQuantity(stringVal: stringVal, handler)
    }
    
    
    var quantity: Float {
        return quantityInput
    }
    
    
    func onSelect(unit: Providers.Unit) {
        guard let indexPath = indexPath else {QL4("Illegal state: no index path"); return}
        
        delegate?.onUpdate(unit: unit, indexPath: indexPath)
        updateQuantitySummary()
    }
    
    func onSelect(base: String) {
        guard let indexPath = indexPath else {QL4("Illegal state: no index path"); return}
        
        delegate?.onUpdate(baseQuantity: base, indexPath: indexPath)
        updateQuantitySummary()
    }

    func onChangeQuantity(quantity: Float) {
        guard let indexPath = indexPath else {QL4("Illegal state: no index path"); return}

        delegate?.onUpdate(quantity: quantity, indexPath: indexPath)
        updateQuantitySummary()
    }
    
    
    var parentForPickers: UIView {
        return contentView
    }
}
