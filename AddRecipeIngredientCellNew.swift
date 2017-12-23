//
//  AddRecipeIngredientCellNew.swift
//  groma
//
//  Created by Ivan Schuetz on 22.12.17.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import Providers
import RealmSwift

protocol AddRecipeIngredientCellNewDelegate: class {

    func units(_ handler: @escaping (Results<Providers.Unit>?) -> Void)
    func baseQuantities(_ handler: @escaping (RealmSwift.List<BaseQuantity>?) -> Void)

    func deleteUnit(name: String, _ handler: @escaping (Bool) -> Void)
    func deleteBaseQuantity(val: Float, _ handler: @escaping (Bool) -> Void)

    // TODO remove - saved now on submit
    func addUnit(name: String, _ handler: @escaping ((unit: Providers.Unit, isNew: Bool)) -> Void)
    func addBaseQuantity(val: Float, _ handler: @escaping (Bool) -> Void)

    // State updaters
    func onSelect(unit: Providers.Unit, cell: AddRecipeIngredientCellNew)
    func onSelect(base: Float, cell: AddRecipeIngredientCellNew)
    func onChange(quantity: Float, cell: AddRecipeIngredientCellNew)
    func onChange(productName: String, cell: AddRecipeIngredientCellNew)
    func onChange(brandName: String, cell: AddRecipeIngredientCellNew)

    func onTapUnitBaseView(cell: AddRecipeIngredientCellNew)

    // TODO remove - no pickers anymore
    var parentForPickers: UIView { get }
}

class AddRecipeIngredientCellNew: UITableViewCell {

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

    @IBOutlet weak var ingredientNameLabel: UILabel!

    @IBOutlet weak var productNameTextField: LineAutocompleteTextField!
    @IBOutlet weak var brandTextField: LineAutocompleteTextField!

    @IBOutlet weak var quantitySummaryLabel: UILabel!
    @IBOutlet weak var alreadyHaveLabel: UILabel!

    @IBOutlet weak var quantitiesContainer: UIView!

    fileprivate(set) var productQuantityController: ProductQuantityController?

    fileprivate weak var delegate: AddRecipeIngredientCellNewDelegate?

    func config(state: CellState, delegate: AddRecipeIngredientCellNewDelegate) {

        self.delegate = delegate

        ingredientNameLabel.text = state.ingredientName
        productNameTextField.text = state.productName
        brandTextField.text = state.brandName

        quantitySummaryLabel.text = generateSummary(
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

    func setAlreadyHaveText(_ text: String) {
        alreadyHaveLabel.text = text
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        initProductQuantityController()
    }

    fileprivate func initProductQuantityController() {
        let productQuantityController = ProductQuantityController()

        // TODO!!!!!!!!!!!!!!!!!!! is it correct to do this here (awake from nib) - does this work with recycled cells?
        productQuantityController.delegate = self

        productQuantityController.view.translatesAutoresizingMaskIntoConstraints = false
        productQuantityController.view.backgroundColor = UIColor.clear
        quantitiesContainer.addSubview(productQuantityController.view)
        productQuantityController.view.fillSuperview()

        self.productQuantityController = productQuantityController
    }

    fileprivate func generateSummary(unitId: UnitId, unitName: String, base: Float, quantity: Float) -> String {
        let unitText = Ingredient.quantityFullText(quantity: quantity, baseQuantity: base, unitId: unitId, unitName: unitName)
        return trans("recipe_you_will_add", unitText)
    }

    @IBAction func onBrandChanged(_ sender: LineAutocompleteTextField) {
        delegate?.onChange(brandName: sender.text ?? "", cell: self)
    }

    @IBAction func onBrandNameChanged(_ sender: LineAutocompleteTextField) {
        delegate?.onChange(productName: sender.text ?? "", cell: self)
    }
}

// MARK: - MLPAutoCompleteTextFieldDataSource

extension AddRecipeIngredientCellNew: MLPAutoCompleteTextFieldDataSource {

    func autoCompleteTextField(_ textField: MLPAutoCompleteTextField!, possibleCompletionsFor string: String!, completionHandler handler: @escaping (([Any]?) -> Void)) {
//        switch textField {
//
//        case productNameTextField:
//            delegate?.productNamesContaining(text: string) {productNames in
//                handler(productNames)
//            }
//
//        case brandTextField:
//            delegate?.brandsContaining(text: string) {brands in
//                handler(brands)
//            }
//
//        case _:
//            print("Error: Not handled text field in autoCompleteTextField")
//            break
//        }
    }
}

// MARK: - MyAutoCompleteTextFieldDelegate

extension AddRecipeIngredientCellNew: MyAutoCompleteTextFieldDelegate {

    func onDeleteSuggestion(_ string: String, sender: MyAutoCompleteTextField) {
        //        switch sender {
        //        case productNameTextField:
        //            delegate?.delete(productName: string) {
        //                self.productNameTextField.closeAutoCompleteTableView()
        //            }
        //
        //        case brandTextField:
        //            delegate?.delete(brand: string) {
        //                self.brandTextField.closeAutoCompleteTableView()
        //            }
        //
        //        default: logger.e("Not handled input")
        //        }
    }
}

extension AddRecipeIngredientCellNew: ProductQuantityControlleDelegate {

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
