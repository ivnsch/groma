//
//  ProductQuantityController.swift
//  shoppin
//
//  Created by Ivan Schuetz on 23/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import Providers
import QorumLogs
import RealmSwift


protocol ProductQuantityControlleDelegate {

    func units(_ handler: @escaping (Results<Providers.Unit>?) -> Void)
    func addUnit(name: String, _ handler: @escaping (Bool) -> Void)
    func deleteUnit(name: String, _ handler: @escaping (Bool) -> Void)
    
    func baseQuantities(_ handler: @escaping (RealmSwift.List<BaseQuantity>?) -> Void)
    func addBaseQuantity(val: Float, _ handler: @escaping (Bool) -> Void)
    func deleteBaseQuantity(val: Float, _ handler: @escaping (Bool) -> Void)
    
    var quantity: Float {get}
    
    func onSelect(unit: Providers.Unit)
    func onSelect(base: Float)
    func onChangeQuantity(quantity: Float)
    
    var parentForPickers: UIView {get}
}


class ProductQuantityController: UIViewController {
    
    @IBOutlet weak var unitButton: UIButton!
    @IBOutlet weak var baseButton: UIButton!
    
    @IBOutlet weak var quantityView: QuantityView!
    
    var delegate: ProductQuantityControlleDelegate?
    
    // MARK: - Inputs

    var quantity: Float {
        get {
            return quantityView.quantity
            
        } set {
            quantityView.quantity = newValue
        }
    }
    
    var currentUnitInput: String?
    var selectedUnit: Providers.Unit?
    
    var currentBaseInput: Float?
    var selectedBase: Float?
    
    fileprivate func onSelect(unit: Providers.Unit) {
        selectedUnit = unit // this is redundant but in AddRecipeController (where the models are) we currently store only the unit name and in some cases we have to get the unit object from cell, not only the name so for now we will store it here
        
        delegate?.onSelect(unit: unit)
        updateBasesVisibility(unit: unit)
    }
    
    // MARK: - Units variables
    
    fileprivate var unitsDataSource: UnitsDataSource?
    fileprivate var unitsDelegate: UnitsDelegate? // arc
    fileprivate var unitPicker: PickerCollectionView?
    fileprivate var shapeLayer: CAShapeLayer?
    fileprivate var unitPickerWrapper: UIView?
    fileprivate var unitPickerMask: UIView?
    
    fileprivate var unitButtonMaskFrame: CGRect {
        let unitButtonOrigin = view.convert(unitButton.frame.origin, to: unitPicker)
        unitButton.bounds.origin = unitButtonOrigin
        return unitButton.bounds.insetBy(dx: -10, dy: -10)
    }
    
    // MARK: - Base quantities variables
    
    fileprivate var basesDataSource: BasesDataSource?
    fileprivate var basesDelegate: UnitsDelegate? // arc
    fileprivate var basesPicker: PickerCollectionView?
    fileprivate var basesShapeLayer: CAShapeLayer?
    fileprivate var basesPickerWrapper: UIView?
    var basesPickerMask: UIView?
    fileprivate var basesAddRecipeDelegate: BasesAddRecipeDelegate? // arc
    
    fileprivate var baseButtonMaskFrame: CGRect {
        let baseButtonOrigin = view.convert(baseButton.frame.origin, to: basesPicker)
        baseButton.bounds.origin = baseButtonOrigin
        return baseButton.bounds.insetBy(dx: -10, dy: -10)
    }

    var onPickersInitialized: (() -> Void)?
    
    func config() {
        
        unitButton.isHidden = true
        baseButton.isHidden = true
        
        initUnitPicker()
        initBasePicker()
        initQuantitiesView()
        
        quantityView.delegate = self
    }
 
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setBasesVisible(visible: false, animated: false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        config()
        
        onPickersInitialized?()
    }
    
    // TODO cell recycling?
    func initUnitPicker() {
        
        guard let delegate = delegate else {QL4("No delegate, can't add picker"); return}
        
        func onHasUnits(units: Results<Providers.Unit>) {
            
            let dataSource = UnitsDataSource(units: units)
            dataSource.delegate = self
            unitsDataSource = dataSource
            
            let flowLayout = UICollectionViewFlowLayout()
            flowLayout.scrollDirection = .vertical
            
            let pickerParent = delegate.parentForPickers
            
            // We need an additional scaling mask for open/close so to now overwrite the gradient mask of PickerCollectionView we need an additional view
            let unitPickerWrapper = UIViewHitTest(size: CGSize(width: 100, height: 250), center: view.convert(unitButton.center, to: pickerParent))

            let unitPicker = PickerCollectionView(size: unitPickerWrapper.bounds.size, center: unitPickerWrapper.bounds.center, layout: flowLayout, boxY: unitButton.y, boxCenterY: unitButton.center.y, cellHeight: cellSize.height, cellSpacing: cellSpacing, delegate: self)
            
            unitPickerWrapper.isInArea = {[weak unitPickerWrapper, weak unitPicker, weak baseButton] point in
                guard let unitPickerWrapper = unitPickerWrapper, let unitPicker = unitPicker, let baseButton = baseButton else {return false}
                return unitPicker.open ? true : point.y > unitPickerWrapper.bounds.center.y - baseButton.height / 2 && point.y < unitPickerWrapper.bounds.center.y + baseButton.height / 2
            }
            
            self.unitPickerWrapper = unitPickerWrapper

            pickerParent.addSubview(unitPickerWrapper)
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
        
        delegate.units({unitsMaybe in
            if let units = unitsMaybe {
                onHasUnits(units: units)
            } else {
                QL4("No units")
            }
        })
    }

    func selectUnitWithName(_ name: String) {
        if let units = unitsDataSource?.units {
            if let (index, unit) = (units.enumerated().filter {$0.element.name == name}.first) {
                unitPicker?.scrollToItem(index: index, animated: false)
                selectedUnit = unit
            } else {
                QL1("Unit with name: \(name) not found in data source units")
            }
        } else {
            QL1("Data source not set")
        }
    }
    
    func selectBaseWithValue(_ val: Float) {
        if let bases = basesDataSource?.bases {
            if let (index, base) = (bases.enumerated().filter {$0.element.val == val}.first) {
                basesPicker?.scrollToItem(index: index, animated: false)
                selectedBase = base.val
                setBasesVisible(visible: true, animated: false) // ensure it's visible
            } else {
                QL1("Base with val: \(val) not found in data source bases")
            }
        } else {
            QL1("Data source not set")
        }
    }
    
    
    // TODO cell recycling?
    func initBasePicker() {
        
        guard let delegate = delegate else {QL4("No delegate, can't add picker"); return}

        func onHasBases(bases: RealmSwift.List<BaseQuantity>) {
            
            let dataSource = BasesDataSource(bases: bases)
            dataSource.delegate = self
            basesDataSource = dataSource
            
            let flowLayout = UICollectionViewFlowLayout()
            flowLayout.scrollDirection = .vertical
            
            let pickerParent = delegate.parentForPickers
            
            // We need an additional scaling mask for open/close so to now overwrite the gradient mask of PickerCollectionView we need an additional view
            let basesPickerWrapper = UIViewHitTest(size: CGSize(width: 100, height: 250), center: view.convert(baseButton.center, to: pickerParent))
            
            let basesAddRecipeDelegate = BasesAddRecipeDelegate(productQuantityController: self)
            let basePicker = PickerCollectionView(size: basesPickerWrapper.bounds.size, center: basesPickerWrapper.bounds.center, layout: flowLayout, boxY: baseButton.y, boxCenterY: baseButton.center.y, cellHeight: cellSize.height, cellSpacing: cellSpacing, delegate: basesAddRecipeDelegate)
            
            basesPickerWrapper.isInArea = {[weak basesPickerWrapper, weak basePicker, weak baseButton] point in
                guard let basesPickerWrapper = basesPickerWrapper, let basePicker = basePicker, let baseButton = baseButton else {return false}
                return basePicker.open ? true : point.y > basesPickerWrapper.bounds.center.y - baseButton.height / 2 && point.y < basesPickerWrapper.bounds.center.y + baseButton.height / 2
            }
            
            self.basesPickerWrapper = basesPickerWrapper
            
            self.basesAddRecipeDelegate = basesAddRecipeDelegate
            
            pickerParent.addSubview(basesPickerWrapper)
            basesPickerWrapper.addSubview(basePicker)
            
            self.basesPicker = basePicker
            
            basePicker.collectionView.register(UINib(nibName: "BaseQuantityCell", bundle: nil), forCellWithReuseIdentifier: "baseCell")
            basePicker.collectionView.register(UINib(nibName: "UnitEditableCell", bundle: nil), forCellWithReuseIdentifier: "unitEditableCell")
            //            basePicker.collectionView.register(UINib(nibName: "BaseQuantityEditableCell", bundle: nil), forCellWithReuseIdentifier: "baseEditableCell")
            
            basePicker.collectionView.showsVerticalScrollIndicator = false
            
            basePicker.collectionView.dataSource = dataSource
            basePicker.collectionView.reloadData()
            
            basePicker.collectionView.backgroundColor = UIColor.clear
            basesPickerWrapper.backgroundColor = UIColor.clear
            
            let basePickerMask = UIView(frame: baseButtonMaskFrame)
            basePickerMask.backgroundColor = UIColor.white
            basesPickerWrapper.mask = basePickerMask
            
            self.basesPickerMask = basePickerMask
            
            setBasesVisible(visible: false, animated: false) // start hidden
        }
        
        delegate.baseQuantities({baseQuantitiesMaybe in
            if let bases = baseQuantitiesMaybe {
                onHasBases(bases: bases)
            } else {
                QL4("No bases")
            }
        })
    }

    
    func initQuantitiesView() {
        guard let delegate = delegate else {QL4("No delegate, can't add picker"); return}

        quantityView.quantity = delegate.quantity
    }
}


// MARK: - UnitsCollectionViewDataSourceDelegate

extension ProductQuantityController: UnitsCollectionViewDataSourceDelegate {
    
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


// MARK: - UnitsCollectionViewDataSourceDelegate

extension ProductQuantityController: BaseQuantitiesDataSourceSourceDelegate {
    
    var currentBaseQuantity: Float {
        return currentBaseInput ?? 1
    }
    
    func onUpdateBaseQuantityInput(valueInput: Float) {
        currentBaseInput = valueInput
    }
    
    var minBaseQuantityTextFieldWidth: CGFloat {
        return 40
    }
    
    var highlightSelectedBaseQuantity: Bool {
        return false
    }
}

extension ProductQuantityController: QuantityViewDelegate {
    
    func onRequestUpdateQuantity(_ delta: Float) {
        let newQuantity = quantity + delta
        quantityView.quantity = newQuantity
        delegate?.onChangeQuantity(quantity: newQuantity)
    }
    
    func onQuantityInput(_ quantity: Float) {
        delegate?.onChangeQuantity(quantity: quantity)
    }
}


extension ProductQuantityController: PickerCollectionViewDelegate {
    
    var cellSize: CGSize {
        return CGSize(width: 70, height: DimensionsManager.quickAddCollectionViewItemsFixedHeight)
    }
    
    var cellSpacing: CGFloat {
        return 10
    }
    
    func onStartScrolling() {
        setBasesPickerOpen(false)
        setUnitPickerOpen(true)
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

                if indexPath.row < units.count {
                    onSelect(unit: units[indexPath.row])
                }
                // for input cell there's no action on select
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
    
    
    
    func appendNewUnitCell() {
        guard let picker = unitPicker else {QL4("No units picker"); return}
        guard let unitsDataSource = unitsDataSource else {QL4("No units data source"); return}
        
        picker.collectionView.insertItems(at: [IndexPath(row: (unitsDataSource.units?.count ?? 0) - 1, section: 0)])
        
        if let editCell = picker.collectionView.cellForItem(at: IndexPath(row: (unitsDataSource.units?.count ?? 0), section: 0)) as? UnitEditableCell {
            editCell.editableUnitView.clear()
        }
    }
    
    func appendNewBaseCell() {
        guard let picker = basesPicker else {QL4("No base picker"); return}
        guard let basesDataSource = basesDataSource else {QL4("No bases data source"); return}
        
        picker.collectionView.insertItems(at: [IndexPath(row: (basesDataSource.bases?.count ?? 0) - 1, section: 0)])
        if let editCell = picker.collectionView.cellForItem(at: IndexPath(row: (basesDataSource.bases?.count ?? 0), section: 0)) as? UnitEditableCell {
            editCell.editableUnitView.clear()
        }
    }
    
    fileprivate func updateBasesVisibility(unit: Providers.Unit?) {
        if let unit = unit {
            let unitsWithBase: [UnitId] = [.g, .kg, .liter, .milliliter]
            if unitsWithBase.contains(unit.id) {
                setBasesVisible(visible: true, animated: true)
            } else {
                setBasesVisible(visible: false, animated: true)
            }
        } else {
            setBasesVisible(visible: false, animated: true)
        }
    }
    
    fileprivate func setBasesVisible(visible: Bool, animated: Bool) {
        animIf(animated) {[weak self] in
            self?.basesPickerWrapper?.alpha = visible ? 1 : 0
        }
    }
    
    ///////////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////
    
    
    func setUnitPickerOpen(_ open: Bool) {
        
        guard let picker = unitPicker else {QL4("No units picker"); return}
        
        setPickerOpen(open, picker: picker, mask: unitPickerMask, maskFrame: unitButtonMaskFrame)
        
    }
    
    func setBasesPickerOpen(_ open: Bool) {
        
        guard let picker = basesPicker else {QL4("No bases picker"); return}
        
        setPickerOpen(open, picker: picker, mask: basesPickerMask, maskFrame: baseButtonMaskFrame)
    }
    
    fileprivate func setPickerOpen(_ open: Bool, picker: PickerCollectionView, mask: UIView?, maskFrame: CGRect) {
        
        picker.open = open
        
        func animNewFrame(frame: CGRect) {
            anim {
                mask?.frame = frame
                self.view.setNeedsLayout()
                self.view.layoutIfNeeded()
            }
        }
        
        if open {
            animNewFrame(frame: picker.bounds)
        } else {
            animNewFrame(frame: maskFrame)
            
        }
    }
    
    func onSnap(cellIndex: Int) { // select model
        guard let unitsDataSource = unitsDataSource else {QL4("No data source"); return}
        guard let units = unitsDataSource.units else {QL4("No units"); return}
        
        if cellIndex < units.count {
            onSelect(unit: units[cellIndex])
        }
        // for input cell there's no action on snap
    }
}

// just a new namespace for the base quantities delegate
fileprivate class BasesAddRecipeDelegate: PickerCollectionViewDelegate {
    
    let productQuantityController: ProductQuantityController
    
    var view: UIView {
        return productQuantityController.view
    }
    
    init(productQuantityController: ProductQuantityController) {
        self.productQuantityController = productQuantityController
    }
    
    
    var cellSize: CGSize {
        return CGSize(width: 70, height: DimensionsManager.quickAddCollectionViewItemsFixedHeight)
    }
    
    var cellSpacing: CGFloat {
        return 10
    }
    
    func onStartScrolling() {
        productQuantityController.setUnitPickerOpen(false)
        productQuantityController.setBasesPickerOpen(true)
    }
    
    
    ///////////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////
    // (Almost) same code from SelectIngredientDataController - refactor?
    
    func onSelectItem(index: Int) {
        
        guard let basesDataSource = productQuantityController.basesDataSource else {
            setBasesPickerOpen(false)
            QL4("No data source")
            return
        }
        
        guard let bases = basesDataSource.bases else {QL4("No bases"); return}
        guard let basesCollectionView = productQuantityController.basesPicker?.collectionView else {QL4("No collection"); return}
        
        
        let indexPath = IndexPath(row: index, section: 0)
        
        let cellMaybe = basesCollectionView.cellForItem(at: indexPath) as? BaseQuantityCell
        
        if cellMaybe?.baseQuantityView.markedToDelete ?? false {
            
            let base = bases[indexPath.row]
            
            productQuantityController.delegate?.deleteBaseQuantity(val: base.val) {success in
                basesCollectionView.deleteItems(at: [indexPath])
                basesCollectionView.collectionViewLayout.invalidateLayout() // seems to fix weird space appearing before last cell (input cell) sometimes
            }
            
            
        } else {
            clearToDeleteBases()
            clearSelectedBases()
            
            if let cell = cellMaybe {
                if isSelected(cell: cell) {
                    onSelect(base: nil)
                    
                } else {
                    let base: Float = {
                        if indexPath.row < bases.count {
                            return bases[indexPath.row].val
                        } else if indexPath.row == bases.count {
                            return self.productQuantityController.currentBaseInput ?? 1
                        } else {
                            fatalError("Invalid index: \(indexPath.row), bases count: \(bases.count)")
                        }
                    }()
                    onSelect(base: base)
                }
            }
        }
    }
    
    fileprivate func isSelected(cell: BaseQuantityCell) -> Bool {
        guard let base = cell.baseQuantityView.base else {return false}
        
        return base.val == self.productQuantityController.currentBaseInput
    }
    
    fileprivate func clearToDeleteBases() {
        guard let basesCollectionView = productQuantityController.basesPicker?.collectionView else {QL4("No collection"); return}
        
        for cell in basesCollectionView.visibleCells {
            if let baseCell = cell as? BaseQuantityCell { // Note that we cast individual cells, because the collection view is mixed
                baseCell.baseQuantityView.mark(toDelete: false, animated: true)
            }
        }
    }
    
    fileprivate func clearSelectedBases() {
        guard let basesCollectionView = productQuantityController.basesPicker?.collectionView else {QL4("No collection"); return}
        
        for cell in basesCollectionView.visibleCells {
            if let baseCell = cell as? BaseQuantityCell { // Note that we cast individual cells, because the collection view is mixed
                baseCell.baseQuantityView.showSelected(selected: false, animated: true)
            }
        }
    }
    
    
    fileprivate func onSelect(base: Float?) {
        productQuantityController.selectedBase = base

        if let base = base {
            productQuantityController.delegate?.onSelect(base: base)
        }
    }
    
    
    ///////////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////
    
    
    fileprivate func setBasesPickerOpen(_ open: Bool) {
        productQuantityController.setBasesPickerOpen(open)
    }
    
    
    func onSnap(cellIndex: Int) { // select model
        guard let basesDataSource = productQuantityController.basesDataSource else {QL4("No data source"); return}
        guard let bases = basesDataSource.bases else {QL4("No bases"); return}
        
        let base: Float = {
            if cellIndex < bases.count {
                return bases[cellIndex].val
            } else if cellIndex == bases.count {
                return productQuantityController.currentBaseInput ?? 1
            } else {
                fatalError("Invalid index: \(cellIndex), unit count: \(bases.count)")
            }
        }()
        
        onSelect(base: base)
    }
}
