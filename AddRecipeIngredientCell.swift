//
//  AddRecipeIngredientCell.swift
//  groma
//
//  Created by Ivan Schuetz on 22.12.17.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import Providers
import RealmSwift

protocol AddRecipeIngredientCellDelegate: class {

    func units(_ handler: @escaping (Results<Providers.Unit>?) -> Void)
    func baseQuantities(_ handler: @escaping (RealmSwift.List<BaseQuantity>?) -> Void)

    func deleteUnit(name: String, _ handler: @escaping (Bool) -> Void)
    func deleteBaseQuantity(val: Float, _ handler: @escaping (Bool) -> Void)

    // TODO remove - saved now on submit
    func addUnit(name: String, _ handler: @escaping ((unit: Providers.Unit, isNew: Bool)) -> Void)
    func addBaseQuantity(val: Float, _ handler: @escaping (Bool) -> Void)

    // State updaters
    func onSelect(unit: Providers.Unit, cell: AddRecipeIngredientCell)
    func onSelect(base: Float, cell: AddRecipeIngredientCell)
    func onChange(quantity: Float, cell: AddRecipeIngredientCell)
    func onChange(productName: String, cell: AddRecipeIngredientCell)
    func onChange(brandName: String, cell: AddRecipeIngredientCell)

    func onTapUnitBaseView(cell: AddRecipeIngredientCell)

    // Autocomplete
    func productNamesContaining(text: String, handler: @escaping ([String]) -> Void)
    func brandsContaining(text: String, handler: @escaping ([String]) -> Void)
    func delete(productNameSuggestion: String, handler: @escaping () -> Void)
    func delete(brandNameSuggestion: String, handler: @escaping () -> Void)

    // TODO remove - no pickers anymore
    var parentForPickers: UIView { get }
}

class AddRecipeIngredientCell: UITableViewCell {

    struct CellUnitState {
        let unitId: UnitId
        let unitName: String
    }

    struct CellState {
        let ingredientId: String
        let ingredientName: String
        var productName: String
        var brandName: String
        var unitData: CellUnitState
        var baseQuantity: Float
        var quantity: Float

        // Cache - to fetch it only once
        var alreadyHaveText: String?
    }

    @IBOutlet weak var ingredientNameLabel: LabelMore!

    @IBOutlet weak var productNameTextField: LineAutocompleteTextField!
    @IBOutlet weak var brandTextField: LineAutocompleteTextField!

    @IBOutlet weak var quantitySummaryLabel: UILabel!
    @IBOutlet weak var quantitySummaryValueLabel: UILabel!
    @IBOutlet weak var alreadyHaveLabel: UILabel!

    @IBOutlet weak var quantitiesContainer: UIView!

    fileprivate(set) var productQuantityController: ProductQuantityController?

    fileprivate weak var delegate: AddRecipeIngredientCellDelegate?

    func config(state: CellState, delegate: AddRecipeIngredientCellDelegate) {

        self.delegate = delegate

        ingredientNameLabel.text = state.ingredientName
        productNameTextField.text = state.productName
        brandTextField.text = state.brandName

        showSummary(
            unitId: state.unitData.unitId,
            unitName: state.unitData.unitName,
            base: state.baseQuantity,
            quantity: state.quantity
        )

        productQuantityController?.config(
            quantity: state.quantity,
            unitId: state.unitData.unitId,
            unitName: state.unitData.unitName,
            base: state.baseQuantity,
            onTapUnitBase: { [weak self, weak delegate] in guard let weakSelf = self else { return }
                delegate?.onTapUnitBaseView(cell: weakSelf)
            }
        )
    }

    func showAlreadyHaveText(_ text: String) {
        alreadyHaveLabel.text = text
    }

    func showSummary(unitId: UnitId, unitName: String, base: Float, quantity: Float) {
        let summary = Ingredient.quantityFullText(quantity: quantity, baseQuantity: base, unitId: unitId, unitName: unitName, showNoneUnitName: true)
        quantitySummaryValueLabel.text = summary
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        initStaticText()
        initProductQuantityController()
    }

    fileprivate func initProductQuantityController() {
        // TODO shouldn't we add the controller as a child of the parent controller? but how/when to remove it?
        let productQuantityController = ProductQuantityController()

        productQuantityController.delegate = self

        productQuantityController.view.translatesAutoresizingMaskIntoConstraints = false
        productQuantityController.view.backgroundColor = UIColor.clear
        quantitiesContainer.addSubview(productQuantityController.view)
        productQuantityController.view.fillSuperview()

        self.productQuantityController = productQuantityController
    }

    fileprivate func initStaticText() {
        quantitySummaryLabel.text = trans("add_recipe_to_list_placeholder_to_add")
        productNameTextField.setPlaceholderWithColor(trans("add_recipe_to_list_placeholder_name"), color: Theme.midGrey2)
        productNameTextField.setPlaceholderWithColor(trans("add_recipe_to_list_placeholder_brand"), color: Theme.midGrey2)
    }

    @IBAction func onBrandChanged(_ sender: LineAutocompleteTextField) {
        delegate?.onChange(brandName: sender.text ?? "", cell: self)
    }

    @IBAction func onBrandNameChanged(_ sender: LineAutocompleteTextField) {
        delegate?.onChange(productName: sender.text ?? "", cell: self)
    }
}

// MARK: - MLPAutoCompleteTextFieldDataSource

extension AddRecipeIngredientCell: MLPAutoCompleteTextFieldDataSource {

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
}

// MARK: - MyAutoCompleteTextFieldDelegate

extension AddRecipeIngredientCell: MyAutoCompleteTextFieldDelegate {

    func onDeleteSuggestion(_ string: String, sender: MyAutoCompleteTextField) {
        switch sender {
        case productNameTextField:
            delegate?.delete(productNameSuggestion: string) {
                self.productNameTextField.closeAutoCompleteTableView()
            }

        case brandTextField:
            delegate?.delete(brandNameSuggestion: string) {
                self.brandTextField.closeAutoCompleteTableView()
            }

        default: logger.e("Not handled input")
        }
    }
}

extension AddRecipeIngredientCell: ProductQuantityControlleDelegate {

    func units(_ handler: @escaping (Results<Providers.Unit>?) -> Void) {
        delegate?.units(handler)
    }

    func baseQuantities(_ handler: @escaping (RealmSwift.List<BaseQuantity>?) -> Void) {
        delegate?.baseQuantities(handler)
    }

    func deleteUnit(name: String, _ handler: @escaping (Bool) -> Void) {
        delegate?.deleteUnit(name: name, handler)
    }

    func deleteBaseQuantity(val: Float, _ handler: @escaping (Bool) -> Void) {
        delegate?.deleteBaseQuantity(val: val, handler)
    }

    // TODO remove
    func addUnit(name: String, _ handler: @escaping ((unit: Providers.Unit, isNew: Bool)) -> Void) {
    }
    func addBaseQuantity(val: Float, _ handler: @escaping (Bool) -> Void) {
    }


    func onSelect(unit: Providers.Unit) {
        delegate?.onSelect(unit: unit, cell: self)
    }

    func onSelect(base: Float) {
        delegate?.onSelect(base: base, cell: self)
    }

    func onChangeQuantity(quantity: Float) {
        delegate?.onChange(quantity: quantity, cell: self)
    }

    // TODO remove
    var parentForPickers: UIView {
        fatalError("remove")
    }
}
