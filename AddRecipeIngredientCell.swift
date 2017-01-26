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
    func onUpdate(baseQuantity: Float, indexPath: IndexPath)
    func onUpdate(unit: ProductUnit, indexPath: IndexPath)
}

typealias AddRecipeIngredientCellOptions = (brands: [String], units: [ProductUnit], baseQuantities: [Float])

class AddRecipeIngredientCell: UITableViewCell {

    @IBOutlet weak var ingredientNameLabel: UILabel!
    
    @IBOutlet weak var productNameTextField: UITextField!
    @IBOutlet weak var brandTextField: UITextField!
    
    @IBOutlet weak var unitTextField: UITextField!
    @IBOutlet weak var baseQuantityTextField: UITextField!
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
            baseQuantityTextField.text = model?.productPrototype.baseQuantity.toString(2)
            quantityTextField.text = model.map{"\($0.quantity)"} ?? "" // this doesn't make a lot of sense, but for now
            
            updateQuantitySummary()
            updateBaseQuantityVisibility()
            
            initAlreadyHaveText()
        }
    }
    
    var indexPath: IndexPath?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        initTextListeners()
        selectionStyle = .none
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
        
        let unitText = Ingredient.unitText(quantity: quantityInput, baseQuantity: baseQuantityInput, unit: unitInput, showNoneText: true)
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
        [productNameTextField, brandTextField, quantityTextField, baseQuantityTextField, unitTextField].forEach {
            $0?.addTarget(self, action: #selector(onQuantityTextChange(_:)), for: .editingChanged)
        }
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
    
    fileprivate var baseQuantityInput: Float {
        return baseQuantityTextField.text.flatMap({Float($0)}) ?? 1
    }
    
    
}
