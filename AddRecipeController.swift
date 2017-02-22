//
//  AddRecipeController.swift
//  shoppin
//
//  Created by Ivan Schuetz on 20/01/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import Providers
import RealmSwift
import QorumLogs


protocol AddRecipeControllerDelegate: class {
    func onAddRecipe(ingredientModels: [AddRecipeIngredientModel], addRecipeController: AddRecipeController) // Delegate can decide when/if to close the recipe controller
    func getAlreadyHaveText(ingredient: Ingredient, _ handler: @escaping (String) -> Void)
}

class AddRecipeController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var recipeNameLabel: UILabel!

    @IBOutlet weak var addToListView: UIView! // to get height / table view inset
    @IBOutlet weak var addToListViewBottomConstraint: NSLayoutConstraint!
    
    var list: Providers.List?
    var recipe: Recipe?
    
    // TODO!!!!!!!!!!!!!! tending to not implement real time updates for this but check if it's safe - if a user removes e.g. a product in another device, which is used by any of the current ingredients, and we submit the ingredients (i.e. save corresponding list items pointing to these products, which should be now invalid?) will it re-add the product? Or does it crash?
    fileprivate var itemsResult: Results<Ingredient>?

    fileprivate var models: [AddRecipeIngredientModel] = []
    
    // These variables aren't updated in real time - they are loaded only once when the view controller is loaded
    // If they were to change in the background it's not critical, as the user submitting the ingredients will re-create products with any brands/units/base quantities that could have been deleted/changed(which is equivalent to a delete, being the brand/unit/base its own "unique")
    fileprivate var ingredientsToBrands = Dictionary<String, [String]>()
    fileprivate var units: Results<Providers.Unit>?
    fileprivate var baseQuantities: [String] = []
    
    weak var delegate: AddRecipeControllerDelegate?
    
    // MARK: - Controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UINib(nibName: "AddRecipeIngredientCell", bundle: nil), forCellReuseIdentifier: "cell")

        recipeNameLabel.text = recipe.map{$0.name} ?? ""
        
        loadIngredients()
        
        let tap = UITapGestureRecognizer()
        tap.cancelsTouchesInView = false
        tap.delegate = self
        tap.addTarget(self, action: #selector(onTapView(_:)))
        view.addGestureRecognizer(tap)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setupTableView()
        addKeyboardObserver()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeObserver()
    }
    

    // MARK: - Actions
    
    @IBAction func onAddToListTap(sender: UIButton) {
        
        // Remembering the last inputs is not a critical operation nor depends / is it a requisite to submit the items, so we just execute it in parallel
        // We only care eabout the intention of the user here ("want to submit this")
        Prov.ingredientProvider.updateLastProductInputs(ingredientModels: models, successHandler {
        })
        
        delegate?.onAddRecipe(ingredientModels: models, addRecipeController: self)
    }
    
    func onTapView(_ tap: UITapGestureRecognizer) {
        UIApplication.shared.delegate!.window??.endEditing(true)
        
        for cell in tableView.visibleCells {
            (cell as? AddRecipeIngredientCell)?.handleGlobalTap()
        }
    }
    
    // MARK: - Private
    
    fileprivate func setupTableView() {
        tableView.bottomInset = addToListView.height
    }
    
    fileprivate func loadIngredients() {
        guard let recipe = recipe else {QL4("No recipe"); return}
        
        Prov.addableIngredientProvider.addableIngredients(recipe: recipe, handler: successHandler {addableIngredients in
            self.onLoadedIngredients(ingredients: addableIngredients)
        })
    }
    
    fileprivate func onLoadedIngredients(ingredients: AddableIngredients) {
        itemsResult = ingredients.results
        
        ingredientsToBrands = ingredients.brands
        units = ingredients.units
        baseQuantities = ingredients.baseQuantities
        
        models = ingredients.results.map({
            let prototype = ProductPrototype(
                name: $0.pName.isEmpty ? $0.item.name : $0.pName,
                category: $0.item.category.name,
                categoryColor: $0.item.category.color,
                brand: $0.pBrand,
                baseQuantity: $0.pBase,
                unit: $0.pUnit
            )
            return AddRecipeIngredientModel(productPrototype: prototype, quantity: $0.pQuantity == 0 ? $0.quantity : $0.pQuantity, ingredient: $0)
        })
        
        tableView.reloadData()
        
        delay(0.5) {
            if self.tableView.numberOfRows(inSection: 0) > 0 {
                (self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as! AddRecipeIngredientCell).focus()
            }
        }
    }
    
    // MARK: - Keyboard
    
    fileprivate func addKeyboardObserver() {
        NotificationCenter.default.addObserver(self, selector:#selector(keyboardWillChangeFrame(_:)), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
        NotificationCenter.default.addObserver(self, selector:#selector(keyboardWillDisappear(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    fileprivate func removeObserver() {
        NotificationCenter.default.removeObserver(self)
    }
    
    func keyboardWillChangeFrame(_ notification: Foundation.Notification) {
        if let userInfo = (notification as NSNotification).userInfo {
            if let frame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
                QL1("keyboardWillChangeFrame, frame: \(frame)")
                let keyboardHeightWithoutTabbar = frame.height - (tabBarController?.tabBar.height ?? 0)
                addToListViewBottomConstraint.constant = keyboardHeightWithoutTabbar
                tableView.bottomInset = keyboardHeightWithoutTabbar + addToListView.height
            } else {
                QL3("Couldn't retrieve keyboard size from user info")
            }
        } else {
            QL3("Notification has no user info")
        }
        // TODO!!!!!!!!!!!!!!!!!!!!!!!! animate
//        animateVisible(true)
    }
    
    func keyboardWillDisappear(_ notification: Foundation.Notification) {
        // when showing validation popup the keyboard disappears so we have to remove the button - otherwise it looks weird
        QL1("add button - Keyboard will disappear - hiding")
//        animateVisible(false) // TODO!!!!!!!!!!!!!!!!!!!!!!!! animate
//        let tabBarHeight = (tabBarController?.tabBar.height ?? 0)
        
        addToListViewBottomConstraint.constant = 0
        
        tableView.bottomInset = addToListView.height
    }
}

// MARK: - Table view

extension AddRecipeController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return itemsResult?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! AddRecipeIngredientCell
        
        if let itemsResult = itemsResult {
            let ingredient = itemsResult[indexPath.row]
            let brands = ingredientsToBrands[ingredient.uuid] ?? []

            cell.delegate = self
            cell.indexPath = indexPath
            cell.model = models[indexPath.row]
            
            cell.initUnitPicker()
            
            if let units = units {
                cell.options = (brands: brands, baseQuantities: baseQuantities, units: units)
            } else {
                QL4("No units, can't set cell options")
            }
            
        } else {
            QL4("Invalid state: no itemsResult")
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 280
    }
}

// MARK: - Cell delegate

extension AddRecipeController: AddRecipeIngredientCellDelegate {
    
    func getAlreadyHaveText(ingredient: Ingredient, _ handler: @escaping (String) -> Void) {
        delegate?.getAlreadyHaveText(ingredient: ingredient, handler)
    }
    
    func addUnit(name: String, _ handler: @escaping (Bool) -> Void) {
        Prov.unitProvider.getOrCreate(name: name, successHandler{[weak self] (unit, isNew) in
            handler(isNew)
        })
    }
    
    func deleteUnit(name: String, _ handler: @escaping (Bool) -> Void) {
        Prov.unitProvider.delete(name: name, successHandler {
            handler(true)
        })
    }
    
    // MARK: - Model update
    
    func onUpdate(productName: String, indexPath: IndexPath) {
        models[indexPath.row].productPrototype.name = productName
    }

    func onUpdate(brand: String, indexPath: IndexPath) {
        models[indexPath.row].productPrototype.brand = brand
    }

    func onUpdate(quantity: Float, indexPath: IndexPath) {
        models[indexPath.row].quantity = quantity
    }
    
    func onUpdate(baseQuantity: String, indexPath: IndexPath) {
        models[indexPath.row].productPrototype.baseQuantity = baseQuantity
    }
    
    func onUpdate(unit: String, indexPath: IndexPath) {
        models[indexPath.row].productPrototype.unit = unit
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
    
    func baseQuantitiesContaining(text: String, handler: @escaping ([String]) -> Void) {
        Prov.productProvider.baseQuantitiesContainingText(text, successHandler{baseQuantities in
            handler(baseQuantities)
        })
    }
    
    func unitsContaining(text: String, handler: @escaping ([String]) -> Void) {
        Prov.productProvider.unitsContainingText(text, successHandler{units in
            handler(units)
        })
    }
    
    func delete(productName: String, handler: @escaping () -> Void) {
        Prov.productProvider.delete(productName: productName, successHandler{
            handler()
        })
    }
    
    func delete(brand: String, handler: @escaping () -> Void) {
        ConfirmationPopup.show(title: trans("popup_title_confirm"), message: trans("popup_remove_brand_completion_confirm"), okTitle: trans("popup_button_yes"), cancelTitle: trans("popup_button_no"), controller: self, onOk: {[weak self] in guard let weakSelf = self else {return}
            Prov.brandProvider.removeProductsWithBrand(brand, remote: true, weakSelf.successHandler {
                AlertPopup.show(message: trans("popup_was_removed", brand), controller: weakSelf)
                handler()
            })
        })
    }
    
    func delete(unit: String, handler: @escaping () -> Void) {
        ConfirmationPopup.show(title: trans("popup_title_confirm"), message: trans("popup_remove_unit_completion_confirm"), okTitle: trans("popup_button_yes"), cancelTitle: trans("popup_button_no"), controller: self, onOk: {[weak self] in guard let weakSelf = self else {return}
            Prov.unitProvider.delete(name: unit, weakSelf.successHandler {
                AlertPopup.show(message: trans("popup_was_removed", unit), controller: weakSelf)
                handler()
            })
        })
    }
    
    func delete(baseQuantity: String, handler: @escaping () -> Void) {
        ConfirmationPopup.show(title: trans("popup_title_confirm"), message: trans("popup_remove_base_completion_confirm"), okTitle: trans("popup_button_yes"), cancelTitle: trans("popup_button_no"), controller: self, onOk: {[weak self] in guard let weakSelf = self else {return}
            Prov.productProvider.deleteProductsWith(base: baseQuantity, weakSelf.successHandler {
                AlertPopup.show(message: trans("popup_was_removed", baseQuantity), controller: weakSelf)
                handler()
            })
        })
    }
    
    func units(_ handler: @escaping (Results<Providers.Unit>?) -> Void) {
        return handler(units)
    }
    
}

// MARK: - Touch

extension AddRecipeController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    /// Tap to dismiss shouldn't block the autocompletion cells to receive touch
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if (touch.view.map{$0.hasAncestor(type: MyAutocompleteCell.self)} ?? false) {
            return false
        }
        return true
    }
}
