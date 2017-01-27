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

protocol AddRecipeIngredientCellDelegate {
    func getAlreadyHaveText(ingredient: Ingredient, _ handler: @escaping (String) -> Void)
    
    func onUpdate(productName: String, indexPath: IndexPath)
    func onUpdate(brand: String, indexPath: IndexPath)
    func onUpdate(quantity: Int, indexPath: IndexPath)
    func onUpdate(baseQuantity: String, indexPath: IndexPath)
    func onUpdate(unit: ProductUnit, indexPath: IndexPath)
    
    func productNamesContaining(text: String, handler: @escaping ([String]) -> Void)
    func brandsContaining(text: String, handler: @escaping ([String]) -> Void)
    func baseQuantitiesContaining(text: String, handler: @escaping ([String]) -> Void)
    func unitsContaining(text: String, handler: @escaping ([String]) -> Void)
    
    func delete(productName: String, handler: @escaping () -> Void)
    func delete(brand: String, handler: @escaping () -> Void)
    func delete(unit: String, handler: @escaping () -> Void)
    func delete(baseQuantity: String, handler: @escaping () -> Void)
}

typealias AddRecipeIngredientCellOptions = (brands: [String], units: [ProductUnit], baseQuantities: [String]) // TODO!!!!!!!!!!!!!!!!!! remove this

class AddRecipeIngredientCell: UITableViewCell {

    @IBOutlet weak var ingredientNameLabel: UILabel!
    
    @IBOutlet weak var productNameTextField: LineAutocompleteTextField!
    @IBOutlet weak var brandTextField: LineAutocompleteTextField!
    
    @IBOutlet weak var unitTextField: LineAutocompleteTextField!
    @IBOutlet weak var baseQuantityTextField: LineAutocompleteTextField!
    @IBOutlet weak var quantityTextField: UITextField!
    
    @IBOutlet weak var quantitySummaryLabel: UILabel!
    @IBOutlet weak var alreadyHaveLabel: UILabel!
    
    var delegate: AddRecipeIngredientCellDelegate?
    var didMoveToSuperviewCalledOnce = false
    
    
    var model: AddRecipeIngredientModel? {
        didSet {
            ingredientNameLabel.text = model.map{"\($0.ingredient.quantity) x \($0.productPrototype.name)"}
            productNameTextField.text = model?.productPrototype.name
            brandTextField.text = model?.productPrototype.brand
            unitTextField.text = model?.productPrototype.unit.shortText
            baseQuantityTextField.text = model?.productPrototype.baseQuantity.floatValue?.toString(2)
            quantityTextField.text = model.map{"\($0.quantity)"} ?? "" // this doesn't make a lot of sense, but for now
            
            updateQuantitySummary()
            updateBaseQuantityVisibility()
            
            initAlreadyHaveText()
        }
    }
    
    var indexPath: IndexPath?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    
        selectionStyle = .none
        
        initTextFieldPlaceholders()
        initAutocompletionTextFields()
        initTextListeners()
    }
    
    
    var options: AddRecipeIngredientCellOptions? {
        didSet {
            // TODO update autosuggestion/popover etc
        }
    }

    
    func focus() {
        productNameTextField.becomeFirstResponder()
    }
    
    // MARK: - Private
    
    fileprivate func updateQuantitySummary() {

        // TODO!!!!!!!!!!!!!!!!! user can enters any unit - don't use enum anymore
        
        let unitText = Ingredient.unitText(quantity: quantityInput, baseQuantity: baseQuantityInput.floatValue ?? 1, unit: unitInput, showNoneText: true)
        let allUnitText = trans("recipe_you_will_add", unitText)
        quantitySummaryLabel.text = allUnitText
    }
    
    /// Showing base quantity with .none unit may be confusing to the user (doesn't make sense) so we hide it in this case
    fileprivate func updateBaseQuantityVisibility() {
        baseQuantityTextField.isHidden = unitInput == .none
    }
    
    fileprivate func initAlreadyHaveText() {
        guard let model = model else {QL4("No model"); return}
        
        delegate?.getAlreadyHaveText(ingredient: model.ingredient) {text in
            self.alreadyHaveLabel.text = text
        }
    }
    
    fileprivate func initTextListeners() {
        for textField in [productNameTextField, brandTextField, quantityTextField, baseQuantityTextField, unitTextField] {
            textField?.addTarget(self, action: #selector(onQuantityTextChange(_:)), for: .editingChanged)
        }
    }
    
    fileprivate func initAutocompletionTextFields() {
        for textField in [productNameTextField, brandTextField, baseQuantityTextField, unitTextField] {
            textField?.defaultAutocompleteStyle()
            textField?.myDelegate = self
        }
    }
    
    fileprivate func initTextFieldPlaceholders() {
        productNameTextField.attributedPlaceholder = NSAttributedString(string: productNameTextField.placeholder!, attributes: [NSForegroundColorAttributeName: UIColor.gray])
        brandTextField.attributedPlaceholder = NSAttributedString(string: brandTextField.placeholder!, attributes: [NSForegroundColorAttributeName: UIColor.gray])
        baseQuantityTextField.attributedPlaceholder = NSAttributedString(string: baseQuantityTextField.placeholder!, attributes: [NSForegroundColorAttributeName: UIColor.gray])
        unitTextField.attributedPlaceholder = NSAttributedString(string: unitTextField.placeholder!, attributes: [NSForegroundColorAttributeName: UIColor.gray])
    }
    
    func onQuantityTextChange(_ sender: UITextField) {
        updateQuantitySummary()
        updateBaseQuantityVisibility()
        
        guard let indexPath = indexPath else {QL4("Illegal state: no index path"); return}
        
        delegate?.onUpdate(productName: nameInput, indexPath: indexPath)
        delegate?.onUpdate(brand: brandInput, indexPath: indexPath)
        delegate?.onUpdate(quantity: quantityInput, indexPath: indexPath)
        delegate?.onUpdate(unit: unitInput, indexPath: indexPath)
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
    
    fileprivate var quantityInput: Int {
        return quantityTextField.text.flatMap({Int($0)}) ?? 0
    }
    
    fileprivate var unitInput: ProductUnit {
        return (unitTextField.text.flatMap{unitText in ProductUnit.fromString(unitText)}) ?? .none
    }
    
    fileprivate var baseQuantityInput: String {
        return baseQuantityTextField.text ?? ""
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
            
        case unitTextField:
            delegate?.unitsContaining(text: string) {units in
                handler(units)
            }
            
        case baseQuantityTextField:
            delegate?.baseQuantitiesContaining(text: string) {baseQuantities in
                handler(baseQuantities)
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

        case baseQuantityTextField:
            delegate?.delete(baseQuantity: string) {
                self.baseQuantityTextField.closeAutoCompleteTableView()
            }
            
        case unitTextField:
            delegate?.delete(unit: string) {
                self.unitTextField.closeAutoCompleteTableView()
            }

        default: QL4("Not handled input")
        }
    }
}
