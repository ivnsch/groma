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


struct AddRecipeIngredientModel {
    var productPrototype: ProductPrototype
    var quantity: Int
    let ingredient: Ingredient // The unmodified ingredient (to pass around)
}

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
    fileprivate var units: [ProductUnit] = []
    fileprivate var baseQuantities: [Float] = []
    
    weak var delegate: AddRecipeControllerDelegate?
    
    // MARK: - Controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UINib(nibName: "AddRecipeIngredientCell", bundle: nil), forCellReuseIdentifier: "cell")

        recipeNameLabel.text = recipe.map{$0.name} ?? ""
        
        loadIngredients()
        
        let tap = UITapGestureRecognizer()
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
        delegate?.onAddRecipe(ingredientModels: models, addRecipeController: self)
    }
    
    func onTapView(_ tap: UITapGestureRecognizer) {
        UIApplication.shared.delegate!.window??.endEditing(true)
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
                name: $0.product.product.name,
                category: $0.product.product.category.name,
                categoryColor: $0.product.product.category.color,
                brand: $0.product.product.brand,
                baseQuantity: $0.product.baseQuantity,
                unit: $0.product.unit
            )
            return AddRecipeIngredientModel(productPrototype: prototype, quantity: $0.quantity, ingredient: $0)
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
            cell.options = (brands: brands, baseQuantities: baseQuantities, units: units)
            
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
    
    // MARK: - Model update
    
    func onUpdate(productName: String, indexPath: IndexPath) {
        models[indexPath.row].productPrototype.name = productName
    }

    func onUpdate(brand: String, indexPath: IndexPath) {
        models[indexPath.row].productPrototype.brand = brand
    }

    func onUpdate(quantity: Int, indexPath: IndexPath) {
        models[indexPath.row].quantity = quantity
    }
    
    func onUpdate(baseQuantity: Float, indexPath: IndexPath) {
        models[indexPath.row].productPrototype.baseQuantity = baseQuantity
    }
    
    func onUpdate(unit: ProductUnit, indexPath: IndexPath) {
        models[indexPath.row].productPrototype.unit = unit
    }
}
