//
//  AddRecipeController.swift
//  groma
//
//  Created by Ivan Schuetz on 22.12.17.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import Providers
import RealmSwift

protocol AddRecipeControllerDelegate: class {
    func onAddRecipe(ingredientModels: [AddRecipeIngredientModel], addRecipeController: AddRecipeController) // Delegate can decide when/if to close the recipe controller
    func getAlreadyHaveText(ingredient: Ingredient, _ handler: @escaping (String) -> Void)
}

class AddRecipeController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    // Initial state
    fileprivate var modelData: AddableIngredients?

    fileprivate var recipeName: String = ""

    // Of cells presented so far
    fileprivate var cellStates: Dictionary<Int, AddRecipeIngredientCell.CellState> = [:]

    fileprivate weak var delegate: AddRecipeControllerDelegate?

    fileprivate var unitBasePopup: MyPopup?

    func config(recipe: Recipe, delegate: AddRecipeControllerDelegate) {
        self.delegate = delegate

        recipeName = recipe.name
        retrieveData(recipe: recipe)
    }

    // Close any added views to superviews of this controller (e.g. popups)
    func closeAddedNonChildren() {
        unitBasePopup?.hide(onFinish: { [weak self] in
            self?.unitBasePopup = nil
        })
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        initTableView()
    }

    fileprivate func retrieveData(recipe: Recipe) {
        Prov.addableIngredientProvider.addableIngredients(recipe: recipe, handler: successHandler { [weak self] addableIngredients in
            self?.modelData = addableIngredients
            self?.tableView.reloadData()
        })
    }

    fileprivate func submit() {

        guard let ingredients = modelData?.results else { logger.e("Invalid state - no model data", .ui); return }

        // Translate to objects for delegate
        func toIngredientModels(ingredients: Results<Ingredient>, cellStates: Dictionary<Int, AddRecipeIngredientCell.CellState>) -> [AddRecipeIngredientModel] {

            var cellStatesById = [String: AddRecipeIngredientCell.CellState]()
            for cellState in Array(cellStates.values) {
                cellStatesById[cellState.ingredientId] = cellState
            }

            return ingredients.collect { ingredient in
                let cellState = cellStatesById[ingredient.uuid]

                // Don't add ingredients which were set to 0 quantity (default is 1)
                if let cellState = cellState {
                    if cellState.quantity == 0 { return nil }
                }

                return AddRecipeIngredientModel(
                    productPrototype: ProductPrototype(
                        name: cellState?.productName ?? ingredient.item.name,
                        category: ingredient.item.category.name,
                        categoryColor: ingredient.item.category.color,
                        brand: cellState?.brandName ?? "",
                        baseQuantity: cellState?.baseQuantity ?? 1,
                        unit: cellState?.unitData.unitName ?? ingredient.unit.name,
                        edible: true),
                    quantity: cellState?.quantity ?? ingredient.quantity,
                    ingredient: ingredient
                )
            }
        }

        let ingredientModels = toIngredientModels(ingredients: ingredients, cellStates: cellStates)

        // We update last inputs and submit paralelly - last inputs isn't critical.
        Prov.ingredientProvider.updateLastProductInputs(ingredientModels: ingredientModels, successHandler {})

        delegate?.onAddRecipe(ingredientModels: ingredientModels, addRecipeController: self)
    }

    fileprivate func initTableView() {
        tableView.register(UINib(nibName: "AddRecipeIngredientCell", bundle: nil), forCellReuseIdentifier: "cell")
    }
}

// MARK: - Table view

extension AddRecipeController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return modelData?.results.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! AddRecipeIngredientCell

        guard let modelData = modelData else {
            logger.e("Invalid state: Should have model data", .ui)
            return cell
        }

        let ingredient = modelData.results[indexPath.row]

        let cellState = cellStates[indexPath.row] ?? toCellState(ingredient: ingredient)
        cellStates[indexPath.row] = cellState

        cell.config(state: cellState, delegate: self)

        if let alreadyHaveText = cellState.alreadyHaveText {
            cell.showAlreadyHaveText(alreadyHaveText)
        } else {
            delegate?.getAlreadyHaveText(ingredient: ingredient, { [weak self] text in
                cell.showAlreadyHaveText(text)
                self?.cellStates[indexPath.row]?.alreadyHaveText = text
            })
        }

        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 280
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = AddRecipeTableViewHeader.createView()
        header.config(title: recipeName)
        header.backgroundColor = Theme.lightGreyBackground
        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let submitView = SubmitView()
        submitView.setButtonTitle(title: trans("add_recipe_to_list_submit_button_title"))
        submitView.delegate = self
        return submitView
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return Theme.submitViewHeight
    }

    // MARK: - Helpers

    fileprivate func toCellState(ingredient: Ingredient) -> AddRecipeIngredientCell.CellState {
        return AddRecipeIngredientCell.CellState(
            ingredientId: ingredient.uuid,
            ingredientName: ingredient.item.name,
            productName: ingredient.pName.isEmpty ? ingredient.item.name : ingredient.pName,
            brandName: ingredient.pBrand,
            unitData: AddRecipeIngredientCell.CellUnitState(
                unitId: ingredient.pUnitId,
                unitName: ingredient.pUnit
            ),
            baseQuantity: ingredient.pBase,
            quantity: ingredient.pQuantity == 0 ? 1 : ingredient.pQuantity, // Default is 1
            alreadyHaveText: nil
        )
    }
}

// MARK: - AddRecipeIngredientCellDelegate

extension AddRecipeController: AddRecipeIngredientCellDelegate {

    func units(_ handler: @escaping (Results<Providers.Unit>?) -> Void) {
        handler(modelData?.units)
    }

    func baseQuantities(_ handler: @escaping (RealmSwift.List<BaseQuantity>?) -> Void) {
        handler(modelData?.baseQuantities)
    }

    func deleteUnit(name: String, _ handler: @escaping (Bool) -> Void) {
        Prov.unitProvider.delete(name: name, successHandler {
            handler(true)
        })
    }

    func deleteBaseQuantity(val: Float, _ handler: @escaping (Bool) -> Void) {
        ConfirmationPopup.show(title: trans("popup_title_confirm"), message: trans("popup_remove_base_completion_confirm"), okTitle: trans("popup_button_yes"), cancelTitle: trans("popup_button_no"), controller: self, onOk: {[weak self] in guard let weakSelf = self else {return}
            Prov.productProvider.deleteProductsWith(base: val, weakSelf.successHandler {
                AlertPopup.show(message: trans("popup_was_removed", val), controller: weakSelf)
                handler(true)
            })
        })
    }

    func addUnit(name: String, _ handler: @escaping ((unit: Providers.Unit, isNew: Bool)) -> Void) {
        Prov.unitProvider.getOrCreate(name: name, successHandler{tuple in
            handler(tuple)
        })
    }

    func addBaseQuantity(val: Float, _ handler: @escaping (Bool) -> Void) {
        Prov.unitProvider.getOrCreate(baseQuantity: val, successHandler{(unit, isNew) in
            handler(isNew)
        })
    }

    func onSelect(unit: Providers.Unit, cell: AddRecipeIngredientCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { logger.e("Couldn't find cell!", .ui); return }
        cellStates[indexPath.row]?.unitData = AddRecipeIngredientCell.CellUnitState(unitId: unit.id, unitName: unit.name)
    }

    func onSelect(base: Float, cell: AddRecipeIngredientCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { logger.e("Couldn't find cell!", .ui); return }
        cellStates[indexPath.row]?.baseQuantity = base
    }

    func onChange(quantity: Float, cell: AddRecipeIngredientCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { logger.e("Couldn't find cell!", .ui); return}
        cellStates[indexPath.row]?.quantity = quantity
        if let cellState = cellStates[indexPath.row] {
            cell.showSummary(
                unitId: cellState.unitData.unitId,
                unitName: cellState.unitData.unitName,
                base: cellState.baseQuantity,
                quantity: cellState.quantity
            )
        } else {
            logger.e("Invalid state", .ui)
        }
    }

    func onChange(brandName: String, cell: AddRecipeIngredientCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { logger.e("Couldn't find cell!", .ui); return}
        cellStates[indexPath.row]?.brandName = brandName
    }

    func onChange(productName: String, cell: AddRecipeIngredientCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { logger.e("Couldn't find cell!", .ui); return}
        cellStates[indexPath.row]?.productName = productName
    }

    func onTapUnitBaseView(cell: AddRecipeIngredientCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { logger.e("Couldn't find cell!", .ui); return }
        guard let baseUnitView = cell.productQuantityController?.unitWithBaseView else { logger.e("Couldn't find cell state!", .ui); return }

        let parent = self

        let popupFrame = CGRect(x: parent.view.x, y: 0, width: parent.view.width, height: parent.view.height)
        let popup = MyPopup(parent: parent.view, frame: popupFrame)
        let controller = SelectUnitAndBaseController(nibName: "SelectUnitAndBaseController", bundle: nil)

        controller.onSubmit = { [weak self] result in guard let weakSelf = self else { return }
            weakSelf.cellStates[indexPath.row]?.unitData = AddRecipeIngredientCell.CellUnitState(
                unitId: result.unitId,
                unitName: result.unitName
            )
            weakSelf.cellStates[indexPath.row]?.baseQuantity = result.baseQuantity

            self?.unitBasePopup?.hide(onFinish: { [weak self] in
                self?.unitBasePopup = nil
                self?.tableView.reloadRows(at: [indexPath], with: .none)
            })
        }

        parent.addChildViewController(controller)

        controller.view.frame = CGRect(x: 0, y: 0, width: parent.view.width, height: parent.view.height)
        popup.contentView = controller.view
        self.unitBasePopup = popup

        popup.show(from: baseUnitView)
    }

    func productNamesContaining(text: String, handler: @escaping ([String]) -> Void) {
        Prov.productProvider.products(text, range: NSRange(location: 0, length: 10000), sortBy: .alphabetic, successHandler {tuple in
            let names = tuple.products.map{$0.item.name}
            handler(names)
        })
    }

    func brandsContaining(text: String, handler: @escaping ([String]) -> Void) {
        Prov.brandProvider.brandsContainingText(text, successHandler{brands in
            handler(brands)
        })
    }

    func delete(productNameSuggestion: String, handler: @escaping () -> Void) {
        Prov.productProvider.delete(productName: productNameSuggestion, successHandler{
            handler()
        })
    }

    func delete(brandNameSuggestion: String, handler: @escaping () -> Void) {
        ConfirmationPopup.show(
            title: trans("popup_title_confirm"),
            message: trans("popup_remove_brand_completion_confirm", brandNameSuggestion),
            okTitle: trans("popup_button_yes"),
            cancelTitle: trans("popup_button_no"),
            controller: self,
            onOk: { [weak self] in guard let weakSelf = self else {return}
                Prov.brandProvider.removeProductsWithBrand(brandNameSuggestion, remote: true, weakSelf.successHandler {
                    AlertPopup.show(message: trans("popup_was_removed", brandNameSuggestion), controller: weakSelf)
                    handler()
                })
            }
        )
    }

    // TODO remove
    var parentForPickers: UIView {
        fatalError("remove")
    }
}

// MARK: - SubmitViewDelegate

extension AddRecipeController: SubmitViewDelegate {

    func onSubmitButton() {
        submit()
    }
}

