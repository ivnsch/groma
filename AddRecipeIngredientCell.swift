//
//  AddRecipeIngredientCell.swift
//  shoppin
//
//  Created by Ivan Schuetz on 21/01/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import Providers

import RealmSwift

protocol AddRecipeIngredientCellDelegate {
    func getAlreadyHaveText(ingredient: Ingredient, _ handler: @escaping (String) -> Void)
    
    func onUpdate(productName: String, indexPath: IndexPath)
    func onUpdate(brand: String, indexPath: IndexPath)
    func onUpdate(quantity: Float, indexPath: IndexPath)
    func onUpdate(baseQuantity: Float, indexPath: IndexPath)
    func onUpdate(unit: Providers.Unit, indexPath: IndexPath)
    
    func productNamesContaining(text: String, handler: @escaping ([String]) -> Void)
    func brandsContaining(text: String, handler: @escaping ([String]) -> Void)
    func baseQuantitiesContaining(text: String, handler: @escaping ([Float]) -> Void)
    func unitsContaining(text: String, handler: @escaping ([String]) -> Void)
    
    func delete(productName: String, handler: @escaping () -> Void)
    func delete(brand: String, handler: @escaping () -> Void)
    func delete(unit: String, handler: @escaping () -> Void)
    func delete(baseQuantity: Float, handler: @escaping () -> Void)
    
    
    func units(_ handler: @escaping (Results<Providers.Unit>?) -> Void)
    func addUnit(name: String, _ handler: @escaping ((unit: Providers.Unit, isNew: Bool)) -> Void)
    func deleteUnit(name: String, _ handler: @escaping (Bool) -> Void)
    
    func baseQuantities(_ handler: @escaping (RealmSwift.List<BaseQuantity>?) -> Void)
    func addBaseQuantity(val: Float, _ handler: @escaping (Bool) -> Void)
    func deleteBaseQuantity(val: Float, _ handler: @escaping (Bool) -> Void)
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
            
            guard let model = model else {logger.w("No model"); return}
            
            let quantityPart = model.ingredient.quantity < 2 ? "" : "\(model.ingredient.quantity.quantityString) x "
            
            ingredientNameLabel.text = "\(quantityPart)\(model.productPrototype.name)"
            productNameTextField.text = model.productPrototype.name
            brandTextField.text = model.productPrototype.brand
            
            productQuantityController?.onPickersInitialized = {[weak productQuantityController] in
                productQuantityController?.selectUnitWithName(model.productPrototype.unit)
                productQuantityController?.selectBaseWithValue(model.productPrototype.baseQuantity)
            }
            
            productQuantityController?.currentBaseInput = model.productPrototype.baseQuantity
            
            productQuantityController?.quantity = model.quantity
            
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
        
        guard let productQuantityController = productQuantityController else {logger.e("No product quantity controller"); return}
        
        productQuantityController.setUnitPickerOpen(false)
        productQuantityController.setBasesPickerOpen(false)
        
        if let currentUnitInput = productQuantityController.currentUnitInput, !currentUnitInput.isEmpty {
            delegate?.addUnit(name: currentUnitInput) {(unit, isNew) in
                if isNew {
                    productQuantityController.appendNewUnitCell(unit: unit)
                }
                productQuantityController.currentUnitInput = nil
            }
        }
        
        if let currentBaseInput = productQuantityController.currentBaseInput {
            delegate?.addBaseQuantity(val: currentBaseInput) {isNew in
                if isNew {
                    productQuantityController.appendNewBaseCell()
                }
                productQuantityController.currentBaseInput = nil
            }
        }
    }
    
    // MARK: - Private
    
    fileprivate func updateQuantitySummary() {
        let unitText = Ingredient.quantityFullText(quantity: quantityInput, baseQuantity: productQuantityController?.selectedBase ?? 1, unit: productQuantityController?.selectedUnit)
        let allUnitText = trans("recipe_you_will_add", unitText)
        quantitySummaryLabel.text = allUnitText
    }
    
    fileprivate func initAlreadyHaveText() {
        guard let model = model else {logger.e("No model"); return}
        
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
        productNameTextField.attributedPlaceholder = NSAttributedString(string: productNameTextField.placeholder!, attributes: [NSAttributedStringKey.foregroundColor: UIColor.gray])
        brandTextField.attributedPlaceholder = NSAttributedString(string: brandTextField.placeholder!, attributes: [NSAttributedStringKey.foregroundColor: UIColor.gray])
    }
    
    @objc func onQuantityTextChange(_ sender: UITextField) {
        updateQuantitySummary()
        
        guard let indexPath = indexPath else {logger.e("Illegal state: no index path"); return}
        
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
    
    fileprivate var baseQuantityInput: Float {
        return productQuantityController?.currentBaseInput ?? 1
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

        default: logger.e("Not handled input")
        }
    }
}

// MARK: - ProductQuantityControlleDelegate

extension AddRecipeIngredientCell: ProductQuantityControlleDelegate {
    
    func units(_ handler: @escaping (Results<Providers.Unit>?) -> Void) {
        delegate?.units(handler)
    }
    
    func addUnit(name: String, _ handler: @escaping ((unit: Providers.Unit, isNew: Bool)) -> Void) {
        delegate?.addUnit(name: name, handler)
    }
    
    func deleteUnit(name: String, _ handler: @escaping (Bool) -> Void) {
        delegate?.deleteUnit(name: name, handler)
    }
    
    
    func baseQuantities(_ handler: @escaping (RealmSwift.List<BaseQuantity>?) -> Void) {
        delegate?.baseQuantities(handler)
    }
    
    func addBaseQuantity(val: Float, _ handler: @escaping (Bool) -> Void) {
        delegate?.addBaseQuantity(val: val, handler)
    }
    
    func deleteBaseQuantity(val: Float, _ handler: @escaping (Bool) -> Void) {
        delegate?.deleteBaseQuantity(val: val, handler)
    }
    
    
    var quantity: Float {
        return quantityInput
    }
    
    
    func onSelect(unit: Providers.Unit) {
        guard let indexPath = indexPath else {logger.e("Illegal state: no index path"); return}
        
        delegate?.onUpdate(unit: unit, indexPath: indexPath)
        updateQuantitySummary()
    }
    
    func onSelect(base: Float) {
        guard let indexPath = indexPath else {logger.e("Illegal state: no index path"); return}
        
        delegate?.onUpdate(baseQuantity: base, indexPath: indexPath)
        updateQuantitySummary()
    }

    func onChangeQuantity(quantity: Float) {
        guard let indexPath = indexPath else {logger.e("Illegal state: no index path"); return}

        delegate?.onUpdate(quantity: quantity, indexPath: indexPath)
        updateQuantitySummary()
    }
    
    
    var parentForPickers: UIView {
        return contentView
    }
}
