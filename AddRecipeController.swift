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
    func onAddRecipe(ingredientModels: [AddRecipeIngredientModel], recipeData: RecipeData, addRecipeController: AddRecipeController) // Delegate can decide when/if to close the recipe controller
    func getAlreadyHaveText(ingredient: Ingredient, _ handler: @escaping (String) -> Void)
}

struct RecipeData {
    let name: String
    let color: UIColor
}

class AddRecipeController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    // Initial state
    fileprivate var modelData: AddableIngredients?

    fileprivate var recipeData = RecipeData(name: "", color: Theme.lightGreyBackground)

    // Of cells presented so far
    fileprivate var cellStates: Dictionary<Int, AddRecipeIngredientCell.CellState> = [:]

    fileprivate weak var delegate: AddRecipeControllerDelegate?

    fileprivate var unitBasePopup: MyPopup?
    fileprivate var unitBaseViewController: SelectUnitAndBaseController?

    // Quick access, to get the unit images (derived from id) in the cells
    fileprivate var unitNameToIdDictionary: Dictionary<String, UnitId> = [:]

    fileprivate var units: Results<Providers.Unit>?
    fileprivate var baseQuantities: RealmSwift.List<BaseQuantity>?
    fileprivate var unitsNotificationToken: NotificationToken?
    fileprivate var baseQuantitiesNotificationToken: NotificationToken?
    fileprivate var secondBaseQuantitiesNotificationToken: NotificationToken?

    func config(recipe: Recipe, delegate: AddRecipeControllerDelegate) {
        self.delegate = delegate

        recipeData = RecipeData(name: recipe.name, color: recipe.color)

        retrieveData(recipe: recipe)
    }

    // Close any added views to superviews of this controller (e.g. popups)
    // Returns if any was showing
    func closeAddedNonChildren() -> Bool {
        let anyWasShowing = unitBasePopup != nil
        unitBasePopup?.hide(onFinish: { [weak self] in
            self?.unitBasePopup = nil
        })
        return anyWasShowing
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        loadUnits()
        loadFirstBaseQuantities()
        loadSecondBaseQuantities()

        initTableView()
        initSubmitView()
        registerKeyboardNotifications()
    }

    fileprivate func registerKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(AddRecipeController.keyboardWillShow(notification:)), name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(AddRecipeController.keyboardWillHide(notification:)), name: UIResponder.keyboardDidHideNotification, object: nil)
    }

    fileprivate func retrieveData(recipe: Recipe) {
        Prov.addableIngredientProvider.addableIngredients(recipe: recipe, handler: successHandler { [weak self] addableIngredients in
            guard let weakSelf = self else { return }
            weakSelf.modelData = addableIngredients
            weakSelf.unitNameToIdDictionary = weakSelf.createUnitNameToIdDictionary(units: addableIngredients.units)

            weakSelf.tableView.reloadData()
        })
    }

    fileprivate func createUnitNameToIdDictionary(units: Results<Providers.Unit>) -> Dictionary<String, UnitId> {
        var dictionary = [String: UnitId]()
        for unit in units {
            dictionary[unit.name] = unit.id
        }
        return dictionary
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
                        secondBaseQuantity: cellState?.secondBaseQuantity ?? 1,
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

        delegate?.onAddRecipe(ingredientModels: ingredientModels, recipeData: recipeData, addRecipeController: self)
    }

    fileprivate func initTableView() {
        tableView.register(UINib(nibName: "AddRecipeIngredientCell", bundle: nil), forCellReuseIdentifier: "cell")
        tableView.bottomInset = Theme.submitViewHeight
        tableView.keyboardDismissMode = .onDrag
        tableView.backgroundColor = Theme.lightGreyBackground
    }

    fileprivate func initSubmitView() {
        let submitView = SubmitView()
        submitView.setButtonTitle(title: trans("add_recipe_to_list_submit_button_title"))
        submitView.delegate = self
        view.addSubview(submitView)

        submitView.translatesAutoresizingMaskIntoConstraints = false
        _ = submitView.alignLeft(self.view)
        _ = submitView.alignRight(self.view)
        _ = submitView.alignBottom(self.view, constant: 0)
        _ = submitView.heightConstraint(Theme.submitViewHeight)
    }

    // MARK: Keyboard Notifications

    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardHeight = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height {
            self.tableView.bottomInset = keyboardHeight
        }
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        UIView.animate(withDuration: 0.2, animations: {
            // For some reason adding inset in keyboardWillShow is animated by itself but removing is not, that's why we have to use animateWithDuration here
            self.tableView.bottomInset = Theme.submitViewHeight
        })
    }

    // MARK: Data

    fileprivate func loadUnits() {
        Prov.unitProvider.units(buyable: true, successHandler{ [weak self] units in
            self?.units = units
            self?.unitBaseViewController?.loadItems()
            delay(0.3) { // FIXME - temporary hack - sometimes (very rarely) units/bases don't appear - debug message "No items (yet?), returning 0 contents height"
                self?.unitBaseViewController?.loadItems()
            }

            let notificationToken = units.observe({ changes in

                switch changes {
                case .initial: break
                case .update(_, let deletions, let insertions, let modifications):
                    logger.d("Units notification, deletions: \(deletions), let insertions: \(insertions), let modifications: \(modifications)")

                    self?.unitBaseViewController?.updateUnits(insertions: insertions, deletions: deletions, modifications: modifications)

                case .error(let error):
                    // An error occurred while opening the Realm file on the background worker thread
                    fatalError(String(describing: error))
                }
            })

            self?.unitsNotificationToken = notificationToken
        })
    }

    fileprivate func loadBaseQuantities(onHasNotificationToken: @escaping (NotificationToken) -> Void, onChanges: @escaping ([Int], [Int], [Int]) -> Void) {
        Prov.unitProvider.baseQuantities(successHandler{ [weak self] baseQuantities in
            self?.baseQuantities = baseQuantities
            self?.unitBaseViewController?.loadItems()
            delay(0.3) { // FIXME - temporary hack - sometimes (very rarely) units/bases don't appear - debug message "No items (yet?), returning 0 contents height"
                self?.unitBaseViewController?.loadItems()
            }

            let notificationToken = baseQuantities.observe({ changes in

                switch changes {
                case .initial: break
                case .update(_, let deletions, let insertions, let modifications):
                    onChanges(deletions, insertions, modifications)

                case .error(let error):
                    // An error occurred while opening the Realm file on the background worker thread
                    fatalError(String(describing: error))
                }
            })

            onHasNotificationToken(notificationToken)
        })
    }

    fileprivate func loadFirstBaseQuantities() {
        loadBaseQuantities (onHasNotificationToken: { [weak self] notificationToken in
            self?.baseQuantitiesNotificationToken = notificationToken
        }, onChanges: { [weak self] deletions, insertions, modifications in
            logger.d("First base quantities notification, deletions: \(deletions), let insertions: \(insertions), let modifications: \(modifications)")
            self?.unitBaseViewController?.updateBaseQuantities(insertions: insertions, deletions: deletions, modifications: modifications)
        })
    }

    fileprivate func loadSecondBaseQuantities() {
        loadBaseQuantities (onHasNotificationToken: { [weak self] notificationToken in
            self?.secondBaseQuantitiesNotificationToken = notificationToken
        }, onChanges: { [weak self] deletions, insertions, modifications in
            logger.d("Second base quantities notification, deletions: \(deletions), let insertions: \(insertions), let modifications: \(modifications)")
            self?.unitBaseViewController?.updateSecondBaseQuantities(insertions: insertions, deletions: deletions, modifications: modifications)
        })
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

        let cellState = cellStates[indexPath.row] ?? toCellState(ingredient: ingredient, unitNameToIdDictionary: unitNameToIdDictionary)
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
        header.config(title: recipeData.name, recipeColor: recipeData.color)
        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }

    // MARK: - Helpers

    fileprivate func determineUnit(ingredient: Ingredient, unitNameToIdDictionary: Dictionary<String, UnitId>) -> (UnitId, String) {

        if !ingredient.pUnit.isEmpty {
            if let unitId = unitNameToIdDictionary[ingredient.pUnit] {
                return (unitId, ingredient.pUnit)
            } else {
                // pUnit but no unit id found - invalid state!
                // This shouldn't happen also if user deletes the unit, since this deletes the ingredient
                logger.e("Couldn't get unit id for name: \(ingredient.pUnit). Defaulting to none.", .ui)
                return (.none, trans("unit_unit"))
            }
        } else { // pUnit is empty! User has never entered store data for this ingredient
            if ingredient.unit.buyable { // Try to use the same unit of ingredient - if it's buyable
                return (ingredient.unit.id, ingredient.unit.name)
            } else { // Default otherwise to none unit
                return (.none, trans("unit_unit"))
            }
        }
    }

    // Unit id: since this can be derived from name it's not stored in the ingredient. We get this from a separate fetch.
    // Unit name optional: Normally unit name is in ingredient - but for error handling consistency we can override it
    // with a default value.
    fileprivate func toCellState(ingredient: Ingredient, unitNameToIdDictionary: Dictionary<String, UnitId>) -> AddRecipeIngredientCell.CellState {

        let (unitId, unitName) = determineUnit(ingredient: ingredient, unitNameToIdDictionary: unitNameToIdDictionary)

        return AddRecipeIngredientCell.CellState(
            ingredientId: ingredient.uuid,
            ingredientName: ingredient.item.name,
            productName: ingredient.pName.isEmpty ? ingredient.item.name : ingredient.pName,
            brandName: ingredient.pBrand,
            unitData: AddRecipeIngredientCell.CellUnitState(
                unitId: unitId,
                unitName: unitName
            ),
            baseQuantity: ingredient.pBase,
            secondBaseQuantity: ingredient.pSecondBase,
            quantity: ingredient.pQuantity == 0 ? 1 : ingredient.pQuantity, // Default is 1
            isHighlighted: false,
            alreadyHaveText: nil
        )
    }

    fileprivate func highlightCell(indexPath: IndexPath) {
        // Update models
        for var cellState in cellStates {
            cellState.value.isHighlighted = false
        }
        cellStates[indexPath.row]?.isHighlighted = true

        // Update views
        let highlightedCell = tableView.cellForRow(at: indexPath)
        for visibleCell in (tableView.visibleCells as! [AddRecipeIngredientCell]) {
            visibleCell.showSelected(visibleCell == highlightedCell)
        }
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
        Prov.unitProvider.delete(name: name, notificationToken: nil, successHandler {
            handler(true)
        })
    }

    func deleteBaseQuantity(val: Float, _ handler: @escaping (Bool) -> Void) {
        let message = trans("popup_remove_base_completion_confirm", val.quantityString)
        let ranges = message.range(val.quantityString).map { [$0] } ?? {
            logger.e("Invalid state product name not contained in: \(message)", .ui)
            return []
        } ()

        MyPopupHelper.showPopup(
            parent: self,
            type: .warning,
            title: trans("popup_title_confirm"),
            message: message,
            highlightRanges: ranges,
            okText: trans("popup_button_yes"),
            centerYOffset: 80, onOk: { [weak self] in guard let weakSelf = self else {return}
                Prov.productProvider.deleteProductsWith(base: val, weakSelf.successHandler {
                    MyPopupHelper.showPopup(parent: weakSelf, type: .info, message: trans("popup_was_removed"), centerYOffset: -80)
                    handler(true)
                })
            }, onCancel: nil)
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

    func onSelect(secondBase: Float, cell: AddRecipeIngredientCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { logger.e("Couldn't find cell!", .ui); return }
        cellStates[indexPath.row]?.secondBaseQuantity = secondBase
    }

    func onChange(quantity: Float, cell: AddRecipeIngredientCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { logger.e("Couldn't find cell!", .ui); return}
        cellStates[indexPath.row]?.quantity = quantity
        if let cellState = cellStates[indexPath.row] {
            cell.showSummary(
                unitId: cellState.unitData.unitId,
                unitName: cellState.unitData.unitName,
                base: cellState.baseQuantity,
                secondBase: cellState.secondBaseQuantity,
                quantity: cellState.quantity
            )
        } else {
            logger.e("Invalid state", .ui)
        }

        highlightCell(indexPath: indexPath)
    }

    func onChange(brandName: String, cell: AddRecipeIngredientCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { logger.e("Couldn't find cell!", .ui); return}
        cellStates[indexPath.row]?.brandName = brandName
    }

    func onChange(productName: String, cell: AddRecipeIngredientCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { logger.e("Couldn't find cell!", .ui); return}
        cellStates[indexPath.row]?.productName = productName
    }

    // Generic cell touch handler - used to highlight the cell when interacted with it
    func onTouchCell(cell: AddRecipeIngredientCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { logger.e("Couldn't find cell!", .ui); return}
        highlightCell(indexPath: indexPath)
    }

    func onTapUnitBaseView(cell: AddRecipeIngredientCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { logger.e("Couldn't find cell!", .ui); return }
        guard let cellState = cellStates[indexPath.row] else { logger.e("Couldn't find cell state!", .ui); return }
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
            weakSelf.cellStates[indexPath.row]?.secondBaseQuantity = result.secondBaseQuantity

            self?.unitBasePopup?.hide(onFinish: { [weak self] in
                self?.unitBasePopup = nil
                self?.unitBaseViewController?.removeFromParent()
                self?.unitBaseViewController = nil
                UIView.performWithoutAnimation { [weak self] in
                    self?.tableView.reloadRows(at: [indexPath], with: .none)
                }
            })
        }

        controller.fetchUnitsFunc = { [weak self] in
            return self?.units.map { AnyRealmCollection($0) }
        }

        controller.fetchBaseQuantitiesFunc = { [weak self] in
            return self?.baseQuantities.map { AnyRealmCollection($0) }
        }

        parent.addChild(controller)

        controller.view.frame = CGRect(x: 0, y: 0, width: parent.view.width, height: parent.view.height)
        popup.contentView = controller.view
        self.unitBasePopup = popup
        self.unitBaseViewController = controller

        controller.config(selectedUnitId: cellState.unitData.unitId,
                          selectedUnitName: cellState.unitData.unitName,
                          selectedBaseQuantity: cellState.baseQuantity,
                          secondSelectedBaseQuantity: cellState.secondBaseQuantity)

        if let unitsNotificationToken = self.unitsNotificationToken {
            controller.setUnitsNotificationToken(token: unitsNotificationToken)
        } else {
            logger.w("No unit notification token", .ui)
        }
        if let firstBaseQuantitiesNotificationToken = self.baseQuantitiesNotificationToken {
            controller.setFirstBaseQuantitiesNotificationToken(token: firstBaseQuantitiesNotificationToken)
        } else {
            logger.w("No first base quantities notification token", .ui)
        }
        if let secondBaseQuantitiesNotificationToken = self.secondBaseQuantitiesNotificationToken {
            controller.setSecondBaseQuantitiesNotificationToken(token: secondBaseQuantitiesNotificationToken)
        } else {
            logger.w("No second base quantities notification token", .ui)
        }

        controller.loadItems()

        view.endEditing(true)

        popup.show(from: baseUnitView, onFinish: {
        })
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

        guard let parent = self.parent?.parent?.parent?.parent else {
            logger.e("No parent!", .ui)
            return
        }

        view.endEditing(true)

        let message = trans("popup_remove_product_completion_confirm", productNameSuggestion)
        let ranges = message.range(productNameSuggestion).map { [$0] } ?? {
            logger.e("Invalid state product name not contained in: \(message)", .ui)
            return []
        } ()

        MyPopupHelper.showPopup(
            parent: parent,
            type: .warning,
            title: trans("popup_title_confirm"),
            message: message,
            highlightRanges: ranges,
            okText: trans("popup_button_yes"),
            centerYOffset: 0,  onOk: { [weak self] in guard let weakSelf = self else {return}
                Prov.productProvider.delete(productName: productNameSuggestion, weakSelf.successHandler{
                    handler()
                })
        }, onCancel: nil)
    }

    func delete(brandNameSuggestion: String, handler: @escaping () -> Void) {

        guard let parent = self.parent?.parent?.parent?.parent else {
            logger.e("No parent!", .ui)
            return
        }

        view.endEditing(true)

        let message = trans("popup_remove_brand_completion_confirm", brandNameSuggestion)
        let ranges = message.range(brandNameSuggestion).map { [$0] } ?? {
            logger.e("Invalid state brand name not contained in: \(message)", .ui)
            return []
        } ()

        MyPopupHelper.showPopup(
            parent: parent,
            type: .warning,
            title: trans("popup_title_confirm"),
            message: trans("popup_remove_brand_completion_confirm", brandNameSuggestion),
            highlightRanges: ranges,
            okText: trans("popup_button_yes"),
            centerYOffset: 0, onOk: { [weak self] in guard let weakSelf = self else {return}
                Prov.brandProvider.removeProductsWithBrand(brandNameSuggestion, remote: true, weakSelf.successHandler {
                    MyPopupHelper.showPopup(parent: weakSelf, type: .info, message: trans("popup_was_removed"), centerYOffset: -80)
                    handler()
                })
            }, onCancel: nil)
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

