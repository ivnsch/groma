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
    func onUpdate(unit: String, indexPath: IndexPath)
    
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
}

typealias AddRecipeIngredientCellOptions = (brands: [String], units: Results<Providers.Unit>, baseQuantities: [String]) // TODO!!!!!!!!!!!!!!!!!! remove this

class AddRecipeIngredientCell: UITableViewCell {

    @IBOutlet weak var ingredientNameLabel: UILabel!
    
    @IBOutlet weak var productNameTextField: LineAutocompleteTextField!
    @IBOutlet weak var brandTextField: LineAutocompleteTextField!

    @IBOutlet weak var unitButton: UIButton!
    
    @IBOutlet weak var baseQuantityTextField: LineAutocompleteTextField!
    @IBOutlet weak var quantityTextField: UITextField!
    
    @IBOutlet weak var quantitySummaryLabel: UILabel!
    @IBOutlet weak var alreadyHaveLabel: UILabel!
    
    var delegate: AddRecipeIngredientCellDelegate?
    var didMoveToSuperviewCalledOnce = false
    
    fileprivate var currentUnitInput: String? {
        didSet {
            guard let unitButton = unitButton else {QL3("Outlets not set yet"); return}
            unitButton.setTitle(currentUnitInput ?? "", for: .normal)
            if currentUnitInput != nil {
                unitButton.backgroundColor = UIColor.white
            } else {
                unitButton.backgroundColor = UIColor.clear
            }
        }
    }
    
    
    var indexPath: IndexPath?
    
    
    // MARK: - Units variables
    
    fileprivate var unitsCollectionView: UICollectionView?
    fileprivate var unitsDataSource: UnitsDataSource?
    fileprivate var unitsDelegate: UnitsDelegate? // arc
    fileprivate var unitPicker: PickerCollectionView?
    fileprivate var shapeLayer: CAShapeLayer?
    fileprivate var unitPickerWrapper: UIView?
    fileprivate var unitPickerMask: UIView?
    
    fileprivate var unitButtonMaskFrame: CGRect {
        let unitButtonOrigin = contentView.convert(unitButton.frame.origin, to: unitPicker)
        unitButton.bounds.origin = unitButtonOrigin
        return unitButton.bounds.insetBy(dx: -10, dy: -10)
    }
    
    // MARK: -

    var model: AddRecipeIngredientModel? {
        didSet {
            ingredientNameLabel.text = model.map{"\($0.ingredient.quantity) x \($0.productPrototype.name)"}
            productNameTextField.text = model?.productPrototype.name
            brandTextField.text = model?.productPrototype.brand
            
            if let unit = model?.productPrototype.unit {
                unitButton.setTitle(unit, for: .normal)
                currentUnitInput = unit
            }

            baseQuantityTextField.text = model?.productPrototype.baseQuantity.floatValue?.toString(2)
            quantityTextField.text = model.map{"\($0.quantity)"} ?? "" // this doesn't make a lot of sense, but for now
            
            updateQuantitySummary()
            updateBaseQuantityVisibility()
            
            initAlreadyHaveText()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    
        selectionStyle = .none
        
        initTextFieldPlaceholders()
        initAutocompletionTextFields()
        initTextListeners()
        
        unitButton.layer.cornerRadius = DimensionsManager.quickAddCollectionViewCellCornerRadius
        
        unitButton.isHidden = true
    }
    
    
    var options: AddRecipeIngredientCellOptions? {
        didSet {
            // TODO update autosuggestion/popover etc
        }
    }

    
    func focus() {
        productNameTextField.becomeFirstResponder()
    }
    
    func handleGlobalTap() {
        setUnitPickerOpen(false)
        
        func onUnitAdded(isNew: Bool) {
            guard let picker = unitPicker else {QL4("No units picker"); return}
            guard let unitsDataSource = unitsDataSource else {QL4("No data source"); return}
            
            if isNew {
                picker.collectionView.insertItems(at: [IndexPath(row: (unitsDataSource.units?.count ?? 0) - 1, section: 0)])
                if let editCell = picker.collectionView.cellForItem(at: IndexPath(row: (unitsDataSource.units?.count ?? 0), section: 0)) as? UnitEditableCell {
                    editCell.editableUnitView.clear()
                }
            }
            currentUnitInput = nil
        }
        
        if let currentUnitInput = currentUnitInput {
            delegate?.addUnit(name: currentUnitInput) {isNew in
                onUnitAdded(isNew: isNew)
            }
        }
    }

    
    // TODO cell recycling?
    func initUnitPicker() {
        
        func onHasUnits(units: Results<Providers.Unit>) {
        
            let view = contentView
            
            let dataSource = UnitsDataSource(units: units)
            dataSource.delegate = self
            unitsDataSource = dataSource
            
            let flowLayout = UICollectionViewFlowLayout()
            flowLayout.scrollDirection = .vertical
            
            // We need an additional scaling mask for open/close so to now overwrite the gradient mask of PickerCollectionView we need an additional view
            let unitPickerWrapper = UIView(size: CGSize(width: 100, height: 250), center: unitButton.center)
            self.unitPickerWrapper = unitPickerWrapper
            let unitPicker = PickerCollectionView(size: unitPickerWrapper.bounds.size, center: unitPickerWrapper.bounds.center, layout: flowLayout, boxY: unitButton.y, boxCenterY: unitButton.center.y, cellHeight: cellSize.height, cellSpacing: cellSpacing, delegate: self)
            
            view.addSubview(unitPickerWrapper)
            unitPickerWrapper.addSubview(unitPicker)

            self.unitPicker = unitPicker
            
            unitPicker.collectionView.register(UINib(nibName: "UnitCell", bundle: nil), forCellWithReuseIdentifier: "unitCell")
            unitPicker.collectionView.register(UINib(nibName: "UnitEditableCell", bundle: nil), forCellWithReuseIdentifier: "unitEditableCell")
            unitPicker.collectionView.register(UINib(nibName: "UnitSubmitCell", bundle: nil), forCellWithReuseIdentifier: "submitCell")
            
            unitPicker.collectionView.showsVerticalScrollIndicator = false
            
            unitPicker.collectionView.dataSource = dataSource
            unitPicker.collectionView.reloadData()
            
            unitPicker.collectionView.backgroundColor = UIColor.clear
            unitPickerWrapper.backgroundColor = UIColor.clear
            
            let unitPickerMask = UIView(frame: unitButtonMaskFrame)
            unitPickerMask.backgroundColor = UIColor.white
            unitPickerWrapper.mask = unitPickerMask
            
            self.unitPickerMask = unitPickerMask
        }
        
        delegate?.units({unitsMaybe in
            if let units = unitsMaybe {
                onHasUnits(units: units)
            } else {
                QL4("No units")
            }
        })
    }

    
    // MARK: - Private
    
    fileprivate func updateQuantitySummary() {

        // TODO!!!!!!!!!!!!!!!!! user can enters any unit - don't use enum anymore
        
        let unitText = Ingredient.unitText(quantity: quantityInput, baseQuantity: baseQuantityInput.floatValue ?? 1, unitName: unitInput, showNoneText: true)
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
        for textField in [productNameTextField, brandTextField, quantityTextField, baseQuantityTextField] {
            textField?.addTarget(self, action: #selector(onQuantityTextChange(_:)), for: .editingChanged)
        }
    }
    
    fileprivate func initAutocompletionTextFields() {
        for textField in [productNameTextField, brandTextField, baseQuantityTextField] {
            textField?.defaultAutocompleteStyle()
            textField?.myDelegate = self
        }
    }
    
    fileprivate func initTextFieldPlaceholders() {
        productNameTextField.attributedPlaceholder = NSAttributedString(string: productNameTextField.placeholder!, attributes: [NSForegroundColorAttributeName: UIColor.gray])
        brandTextField.attributedPlaceholder = NSAttributedString(string: brandTextField.placeholder!, attributes: [NSForegroundColorAttributeName: UIColor.gray])
        baseQuantityTextField.attributedPlaceholder = NSAttributedString(string: baseQuantityTextField.placeholder!, attributes: [NSForegroundColorAttributeName: UIColor.gray])
    }
    
    func onQuantityTextChange(_ sender: UITextField) {
        updateQuantitySummary()
        updateBaseQuantityVisibility()
        
        guard let indexPath = indexPath else {QL4("Illegal state: no index path"); return}
        
        delegate?.onUpdate(productName: nameInput, indexPath: indexPath)
        delegate?.onUpdate(brand: brandInput, indexPath: indexPath)
        delegate?.onUpdate(quantity: quantityInput, indexPath: indexPath)
        delegate?.onUpdate(baseQuantity: baseQuantityInput, indexPath: indexPath)
    }
}

// MARK: - UnitsCollectionViewDataSourceDelegate

extension AddRecipeIngredientCell: UnitsCollectionViewDataSourceDelegate {
    
    var currentUnitName: String {
        return currentUnitInput ?? ""
    }
    
    func onUpdateUnitNameInput(nameInput: String) {
        currentUnitInput = nameInput
    }
    
    var minUnitTextFieldWidth: CGFloat {
        return 40
    }
    
    var highlightSelected: Bool {
        return false
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
        return quantityTextField.text.flatMap({Float($0)}) ?? 0
    }
    
    fileprivate var unitInput: String {
        return currentUnitInput ?? ""
    }
    
    fileprivate var baseQuantityInput: String {
        // NOTE: We convert to float and back to get correct format for realm (e.g. "1.0" instead of "1"). Since we store base quantity as strings, this is important. The reason of storing it as strings is that it's more efficient to search for autosuggestions, since we can let Realm search. On the other side the way we are handling it now is bad practice. TODO We should use floats until the object is stored to the Realm, where the float is converted to a string (in Provider) in a single place using a single formatter. This way we ensure consistency and also don't expose implementation details to the UI project.   
        return baseQuantityTextField.text?.floatValue.map{String($0)} ?? ""
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

        default: QL4("Not handled input")
        }
    }
}


extension AddRecipeIngredientCell: PickerCollectionViewDelegate {
    
    var cellSize: CGSize {
        return CGSize(width: 70, height: DimensionsManager.quickAddCollectionViewItemsFixedHeight)
    }
    
    var cellSpacing: CGFloat {
        return 10
    }
    
    func onStartScrolling() {
        
        anim {
            self.unitPickerMask?.frame = self.unitPicker!.bounds
            self.contentView.setNeedsLayout()
            self.contentView.layoutIfNeeded()
        }
    }
    

    ///////////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////
    // (Almost) same code from SelectIngredientDataController - refactor?
    
    func onSelectItem(index: Int) {
        
        guard let unitsDataSource = unitsDataSource else {
            setUnitPickerOpen(false)
            QL4("No data source")
            return
        }
        
        guard let units = unitsDataSource.units else {QL4("No units"); return}
        guard let unitsCollectionView = unitPicker?.collectionView else {QL4("No collection"); return}
        
        
        let indexPath = IndexPath(row: index, section: 0)
        
        let cellMaybe = unitsCollectionView.cellForItem(at: indexPath) as? UnitCell
        
        if cellMaybe?.unitView.markedToDelete ?? false {
            
            let unit = units[indexPath.row]
            
            delegate?.deleteUnit(name: unit.name) {success in
                unitsCollectionView.deleteItems(at: [indexPath])
                unitsCollectionView.collectionViewLayout.invalidateLayout() // seems to fix weird space appearing before last cell (input cell) sometimes
            }
            
            
        } else {
            clearToDeleteUnits()
            clearSelectedUnits()
            
            if let cell = cellMaybe {
                if isSelected(cell: cell) {
                    onSelect(unitName: "")
                    
                } else {
                    let unitName: String = {
                        if indexPath.row < units.count {
                            return units[indexPath.row].name
                        } else if indexPath.row == units.count {
                            return currentUnitInput ?? ""
                        } else {
                            fatalError("Invalid index: \(indexPath.row), unit count: \(units.count)")
                        }
                    }()
                    onSelect(unitName: unitName)
                }
            }
        }
    }
    
    fileprivate func isSelected(cell: UnitCell) -> Bool {
        guard let unitViewUnit = cell.unitView.unit else {return false}
        
        return unitViewUnit.name == currentUnitInput
    }
    
    fileprivate func clearToDeleteUnits() {
        guard let unitsCollectionView = unitPicker?.collectionView else {QL4("No collection"); return}
        
        for cell in unitsCollectionView.visibleCells {
            if let fractionCell = cell as? UnitCell { // Note that we cast individual cells, because the collection view is mixed
                fractionCell.unitView.mark(toDelete: false, animated: true)
            }
        }
    }
    
    fileprivate func clearSelectedUnits() {
        guard let unitsCollectionView = unitPicker?.collectionView else {QL4("No collection"); return}
        
        for cell in unitsCollectionView.visibleCells {
            if let fractionCell = cell as? UnitCell { // Note that we cast individual cells, because the collection view is mixed
                fractionCell.unitView.showSelected(selected: false, animated: true)
            }
        }
    }
    
    
    fileprivate func onSelect(unitName: String) {
        guard let indexPath = indexPath else {QL4("Illegal state: no index path"); return}
        
        currentUnitInput = unitName
        delegate?.onUpdate(unit: unitName, indexPath: indexPath)
    }
    
    
    ///////////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////
    
    
    fileprivate func setUnitPickerOpen(_ open: Bool) {
        
        guard let picker = unitPicker else {QL4("No units picker"); return}
        
        func animNewFrame(frame: CGRect) {
            anim {
                self.unitPickerMask?.frame = frame
                self.contentView.setNeedsLayout()
                self.contentView.layoutIfNeeded()
            }
        }
        
        if open {
            animNewFrame(frame: picker.bounds)
        } else {
            animNewFrame(frame: unitButtonMaskFrame)
            
        }
    }

    func onSnap(cellIndex: Int) { // select model
        guard let unitsDataSource = unitsDataSource else {QL4("No data source"); return}
        guard let units = unitsDataSource.units else {QL4("No units"); return}
        
        let unitName: String = {
            if cellIndex < units.count {
                return units[cellIndex].name
            } else if cellIndex == units.count {
                return currentUnitInput ?? ""
            } else {
                fatalError("Invalid index: \(cellIndex), unit count: \(units.count)")
            }
        }()
        
        onSelect(unitName: unitName)
    }
}
