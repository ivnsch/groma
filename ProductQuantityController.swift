//
//  ProductQuantityController.swift
//  shoppin
//
//  Created by Ivan Schuetz on 23/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import Providers

import RealmSwift


protocol ProductQuantityControlleDelegate {

    func units(_ handler: @escaping (Results<Providers.Unit>?) -> Void)
    func baseQuantities(_ handler: @escaping (RealmSwift.List<BaseQuantity>?) -> Void)

    func deleteUnit(name: String, _ handler: @escaping (Bool) -> Void)
    func deleteBaseQuantity(val: Float, _ handler: @escaping (Bool) -> Void)

    // TODO remove - saved now on submit
    func addUnit(name: String, _ handler: @escaping ((unit: Providers.Unit, isNew: Bool)) -> Void)
    func addBaseQuantity(val: Float, _ handler: @escaping (Bool) -> Void)

    func onSelect(unit: Providers.Unit)
    func onSelect(base: Float)
    func onChangeQuantity(quantity: Float)

    // TODO remove - no pickers anymore
    var parentForPickers: UIView { get }
}


class ProductQuantityController: UIViewController {

    @IBOutlet weak var unitWithBaseView: UnitWithBaseView!
    @IBOutlet weak var quantityView: QuantityView!

    @IBOutlet weak var unitBaseViewHeightConstraint: NSLayoutConstraint!

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
//        updateBasesVisibility(unit: unit)
    }
    
    // MARK: - Base quantities variables
    
    fileprivate var basesDataSource: BasesDataSource?
    fileprivate var basesDelegate: UnitsDelegate? // arc

    var onPickersInitialized: (() -> Void)?
    
    func config(onTapUnitBase: @escaping () -> Void) {
        unitWithBaseView.configure(onTap: {
            onTapUnitBase()
        })
        quantityView.delegate = self
    }

    func show(base: Float, secondBase: Float?, unitId: UnitId, unitName: String, quantity: Float) {
        quantityView.quantity = quantity
        unitWithBaseView.show(base: base, secondBase: secondBase, unitId: unitId, unitName: unitName)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        unitBaseViewHeightConstraint.constant = DimensionsManager.unitBaseViewHeightConstraint

        // TODO remove?
//        setBasesVisible(visible: false, animated: false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
//        config()

        onPickersInitialized?()
    }


    func showBaseUnit(base: Float, secondBase: Float?, unitId: UnitId, unitName: String) {
        unitWithBaseView.show(base: base, secondBase: secondBase, unitId: unitId, unitName: unitName)
    }
//    func selectBaseWithValue(_ val: Float) {
//        if let bases = basesDataSource?.bases {
//            if let (index, base) = (bases.enumerated().filter {$0.element.val == val}.first) {
//                basesPicker?.scrollToItem(index: index, animated: false)
//                selectedBase = base.val
//                updateBasesVisibility(unit: selectedUnit, animated: false)
//            } else {
//                logger.v("Base with val: \(val) not found in data source bases")
//            }
//        } else {
//            logger.v("Data source not set")
//        }
//    }
//
//
//    // TODO cell recycling?
//    func initBasePicker() {
//
//        guard let delegate = delegate else {logger.e("No delegate, can't add picker"); return}
//
//        func onHasBases(bases: RealmSwift.List<BaseQuantity>) {
//
//            let dataSource = BasesDataSource(bases: bases)
//            dataSource.delegate = self
//            basesDataSource = dataSource
//
//            let flowLayout = UICollectionViewFlowLayout()
//            flowLayout.scrollDirection = .vertical
//
//            let pickerParent = delegate.parentForPickers
//
//            // We need an additional scaling mask for open/close so to now overwrite the gradient mask of PickerCollectionView we need an additional view
//            let basesPickerWrapper = UIViewHitTest(size: CGSize(width: 100, height: 250), center: view.convert(baseButton.center, to: pickerParent))
//
//            let basesAddRecipeDelegate = BasesAddRecipeDelegate(productQuantityController: self)
//            let basePicker = PickerCollectionView(size: basesPickerWrapper.bounds.size, center: basesPickerWrapper.bounds.center, layout: flowLayout, boxY: baseButton.y, boxCenterY: baseButton.center.y, cellHeight: cellSize.height, cellSpacing: cellSpacing, delegate: basesAddRecipeDelegate)
//
//            basesPickerWrapper.isInArea = {[weak basesPickerWrapper, weak basePicker, weak baseButton] point in
//                guard let basesPickerWrapper = basesPickerWrapper, let basePicker = basePicker, let baseButton = baseButton else {return false}
//                return basePicker.open ? true : point.y > basesPickerWrapper.bounds.center.y - baseButton.height / 2 && point.y < basesPickerWrapper.bounds.center.y + baseButton.height / 2
//            }
//
//            self.basesPickerWrapper = basesPickerWrapper
//
//            self.basesAddRecipeDelegate = basesAddRecipeDelegate
//
//            pickerParent.addSubview(basesPickerWrapper)
//            basesPickerWrapper.addSubview(basePicker)
//
//            self.basesPicker = basePicker
//
//            basePicker.collectionView.register(UINib(nibName: "BaseQuantityCell", bundle: nil), forCellWithReuseIdentifier: "baseCell")
//            basePicker.collectionView.register(UINib(nibName: "UnitEditableCell", bundle: nil), forCellWithReuseIdentifier: "unitEditableCell")
//            //            basePicker.collectionView.register(UINib(nibName: "BaseQuantityEditableCell", bundle: nil), forCellWithReuseIdentifier: "baseEditableCell")
//
//            basePicker.collectionView.showsVerticalScrollIndicator = false
//
//            basePicker.collectionView.dataSource = dataSource
//            basePicker.collectionView.reloadData()
//
//            basePicker.collectionView.backgroundColor = UIColor.clear
//            basesPickerWrapper.backgroundColor = UIColor.clear
//
//            let basePickerMask = UIView(frame: baseButtonMaskFrame)
//            basePickerMask.backgroundColor = UIColor.white
//            basesPickerWrapper.mask = basePickerMask
//
//            self.basesPickerMask = basePickerMask
//
//            setBasesVisible(visible: false, animated: false) // start hidden
//        }
//
//        delegate.baseQuantities({baseQuantitiesMaybe in
//            if let bases = baseQuantitiesMaybe {
//                onHasBases(bases: bases)
//            } else {
//                logger.e("No bases")
//            }
//        })
//    }

    
    func initQuantitiesView() {
        guard let delegate = delegate else {logger.e("No delegate, can't add picker"); return}

        //TODO# unidirectional - init/update method - no fetching from delegate
//        quantityView.quantity = delegate.quantity
    }
    
    /// Some of the views added by this controller, are not added as subviews of this controller's view but above in the hierarchy so we have to hide them explicitly.
    func setManagedViewsHidden(hidden: Bool) {
        //TODO do we still need this
//        view.isHidden = hidden
//        unitPicker?.isHidden = hidden
//        basesPicker?.isHidden = hidden
    }
}


// MARK: - UnitsCollectionViewDataSourceDelegate

extension ProductQuantityController: UnitsCollectionViewDataSourceDelegate {
    
    var currentUnitName: String {
        return currentUnitInput ?? ""
    }

    var unitToDeleteName: String {
        return "" // TODO
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

    func onMarkUnitToDelete(unit: Providers.Unit) {
        fatalError("TODO?")
    }

    var collectionView: UICollectionView {
        fatalError("TODO?")
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

//
//extension ProductQuantityController: PickerCollectionViewDelegate {
//
//    var cellSize: CGSize {
//        return CGSize(width: 70, height: DimensionsManager.quickAddCollectionViewItemsFixedHeight)
//    }
//
//    var cellSpacing: CGFloat {
//        return 10
//    }
//
//    func onStartScrolling() {
//        setBasesPickerOpen(false)
//        setUnitPickerOpen(true)
//    }
//
//    ///////////////////////////////////////////////////////////////////////////////////////
//    ///////////////////////////////////////////////////////////////////////////////////////
//    // (Almost) same code from SelectIngredientDataController - refactor?
//
//    func appendNewBaseCell() {
//        guard let picker = basesPicker else {logger.e("No base picker"); return}
//        guard let basesDataSource = basesDataSource else {logger.e("No bases data source"); return}
//
//        picker.collectionView.insertItems(at: [IndexPath(row: (basesDataSource.bases?.count ?? 0) - 1, section: 0)])
//        if let editCell = picker.collectionView.cellForItem(at: IndexPath(row: (basesDataSource.bases?.count ?? 0), section: 0)) as? UnitEditableCell {
//            editCell.editableUnitView.clear()
//        }
//    }
//
//    fileprivate func updateBasesVisibility(unit: Providers.Unit?, animated: Bool = true) {
//        if let unit = unit {
//            if Providers.Unit.unitsWithBase.contains(unit.id) {
//                setBasesVisible(visible: true, animated: animated)
//            } else {
//                setBasesVisible(visible: false, animated: animated)
//            }
//        } else {
//            setBasesVisible(visible: false, animated: animated)
//        }
//    }
//
//    fileprivate func setBasesVisible(visible: Bool, animated: Bool) {
//        animIf(animated) {[weak self] in
//            self?.basesPickerWrapper?.alpha = visible ? 1 : 0
//        }
//    }
//
//    ///////////////////////////////////////////////////////////////////////////////////////
//    ///////////////////////////////////////////////////////////////////////////////////////
//
//}

//// just a new namespace for the base quantities delegate
//fileprivate class BasesAddRecipeDelegate: PickerCollectionViewDelegate {
//
//    let productQuantityController: ProductQuantityController
//
//    var view: UIView {
//        return productQuantityController.view
//    }
//
//    init(productQuantityController: ProductQuantityController) {
//        self.productQuantityController = productQuantityController
//    }
//
//
//    var cellSize: CGSize {
//        return CGSize(width: 70, height: DimensionsManager.quickAddCollectionViewItemsFixedHeight)
//    }
//
//    var cellSpacing: CGFloat {
//        return 10
//    }
//
//    func onStartScrolling() {
//        productQuantityController.setUnitPickerOpen(false)
//        productQuantityController.setBasesPickerOpen(true)
//    }
//
//
//    ///////////////////////////////////////////////////////////////////////////////////////
//    ///////////////////////////////////////////////////////////////////////////////////////
//    // (Almost) same code from SelectIngredientDataController - refactor?
//
//    func onSelectItem(index: Int) {
//
//        guard let basesDataSource = productQuantityController.basesDataSource else {
//            setBasesPickerOpen(false)
//            logger.e("No data source")
//            return
//        }
//
//        guard let bases = basesDataSource.bases else {logger.e("No bases"); return}
//        guard let basesCollectionView = productQuantityController.basesPicker?.collectionView else {logger.e("No collection"); return}
//
//
//        let indexPath = IndexPath(row: index, section: 0)
//
//        let cellMaybe = basesCollectionView.cellForItem(at: indexPath) as? BaseQuantityCell
//
//        if cellMaybe?.baseQuantityView.markedToDelete ?? false {
//
//            let base = bases[indexPath.row]
//
//            productQuantityController.delegate?.deleteBaseQuantity(val: base.val) {success in
//                basesCollectionView.deleteItems(at: [indexPath])
//                basesCollectionView.collectionViewLayout.invalidateLayout() // seems to fix weird space appearing before last cell (input cell) sometimes
//            }
//
//
//        } else {
//            clearToDeleteBases()
//            clearSelectedBases()
//
//            if let cell = cellMaybe {
//                if isSelected(cell: cell) {
//                    onSelect(base: nil)
//
//                } else {
//                    let base: Float = {
//                        if indexPath.row < bases.count {
//                            return bases[indexPath.row].val
//                        } else if indexPath.row == bases.count {
//                            return self.productQuantityController.currentBaseInput ?? 1
//                        } else {
//                            fatalError("Invalid index: \(indexPath.row), bases count: \(bases.count)")
//                        }
//                    }()
//                    onSelect(base: base)
//                }
//            }
//        }
//    }
//
//    fileprivate func isSelected(cell: BaseQuantityCell) -> Bool {
//        guard let base = cell.baseQuantityView.base else {return false}
//
//        return base.val == self.productQuantityController.currentBaseInput
//    }
//
//    fileprivate func clearToDeleteBases() {
//        //TODO?
////        guard let basesCollectionView = productQuantityController.basesPicker?.collectionView else {logger.e("No collection"); return}
////
////        for cell in basesCollectionView.visibleCells {
////            if let baseCell = cell as? BaseQuantityCell { // Note that we cast individual cells, because the collection view is mixed
////                baseCell.baseQuantityView.mark(toDelete: false, animated: true)
////            }
////        }
//    }
//
//    fileprivate func clearSelectedBases() {
//        //TODO?
////        guard let basesCollectionView = productQuantityController.basesPicker?.collectionView else {logger.e("No collection"); return}
////
////        for cell in basesCollectionView.visibleCells {
////            if let baseCell = cell as? BaseQuantityCell { // Note that we cast individual cells, because the collection view is mixed
////                baseCell.baseQuantityView.showSelected(selected: false, animated: true)
////            }
////        }
//    }
//
//
//    fileprivate func onSelect(base: Float?) {
//        productQuantityController.selectedBase = base
//
//        if let base = base {
//            productQuantityController.delegate?.onSelect(base: base)
//        }
//    }
//
//
//    ///////////////////////////////////////////////////////////////////////////////////////
//    ///////////////////////////////////////////////////////////////////////////////////////
//
//}

