//
//  SelectIngredientDataController.swift
//  shoppin
//
//  Created by Ivan Schuetz on 09/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import Providers
import QorumLogs
import RealmSwift

struct SelectIngredientDataControllerInputs {
    var unitName: String = ""
    var quantity: Float = 1
    var fraction: Fraction = Fraction(wholeNumber: 0, numerator: 1, denominator: 1)
}

protocol SelectIngredientDataControllerDelegate: class {

    func parentViewForAddButton() -> UIView?
    func onSubmitIngredientInputs(item: Item, inputs: SelectIngredientDataControllerInputs)
}

class SelectIngredientDataController: UIViewController, QuantityViewDelegate, SwipeToIncrementHelperDelegate, UIGestureRecognizerDelegate, SubmitViewDelegate {

    @IBOutlet weak var wholeNumberLabel: UILabel!
    @IBOutlet weak var fractionLabel: UILabel!
    @IBOutlet weak var unitLabel: UILabel!
    @IBOutlet weak var itemNameLabel: UILabel!
    @IBOutlet weak var wholeNumberTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var fractionTrailingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var quantityView: QuantityView!
    @IBOutlet weak var quantityBackgroundView: UIView!
    
    @IBOutlet weak var fractionsCollectionView: UICollectionView!
    
    @IBOutlet weak var unitsCollectionView: UICollectionView!
    
    var inputs: SelectIngredientDataControllerInputs = SelectIngredientDataControllerInputs()
    
    fileprivate var titleLabelsFont: UIFont?

    weak var delegate: SelectIngredientDataControllerDelegate?

    fileprivate var currentNewFractionInput: Fraction?
    fileprivate var currentNewUnitInput: String?

    fileprivate var submitView: SubmitView?
    
    var item: Item? {
        didSet {
            if let item = item {
                itemNameLabel.text = item.name // TODO string should be "2/1/2 units Onions" etc
            }
        }
    }
    
//    fileprivate var units: Results<Providers.Unit>?
    fileprivate var unitNames: [String] = [] // we need this because we can't touch the Realm Units in the autocompletions thread (get diff. thread exception). So we have to map to Strings in advance.
    
    var quantity: Float {
        return quantityView.quantity
    }
    
    
    var onViewDidLoad: (() -> Void)?
    
    fileprivate var swipeToIncrementHelper: SwipeToIncrementHelper?
    
    fileprivate var fractions: RealmSwift.List<DBFraction>? {
        didSet {
            fractionsCollectionView.reloadData()
        }
    }
    
    fileprivate var unitsDataSource: UnitsDataSource?
    fileprivate var unitsDelegate: UnitsDelegate? // arc
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        onViewDidLoad?()
        
        quantityView.delegate = self
        quantityView.quantity = 1
        
        swipeToIncrementHelper = SwipeToIncrementHelper(view: quantityBackgroundView)
        swipeToIncrementHelper?.delegate = self
         
        titleLabelsFont = itemNameLabel.font // NOTE: Assumes that all labels in title have same font
        
        initUnitsCollectionView()
        loadFractions()
        
        updateInputsAndTitle()
        
        initSubmitButton()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(onTap(_:)))
        tap.delegate = self
        view.addGestureRecognizer(tap)
        
        // For the most part intrinsic size worked but there were some issues particularly after removing some cells, the input cell (the last one) would shift to the right until being outside of the collection view. After switching to sizeForItemAt this still happened! (though it seemed to be less frequently?). Then I added invalidateLayout() after the cell removals. This apparently has fixed it. It may be that invalidateLayout() makes it work correctly also with the intrinsic size but I don't have more time for this right now.
//        // Set estimated size, this makes collection view use intrinsic cell size
//        if let flow = fractionsCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
//            flow.estimatedItemSize = CGSize(width: 100, height: 50)
//        } else {
//            QL4("No flow layout")
//        }
//        if let flow = unitsCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
//            flow.estimatedItemSize = CGSize(width: 100, height: 50)
//        } else {
//            QL4("No flow layout")
//        }
    }
    
    fileprivate func initUnitsCollectionView() {

        let delegate = UnitsDelegate(delegate: self)
        unitsCollectionView.delegate = delegate
        unitsDelegate = delegate
        
        Prov.unitProvider.units(successHandler{[weak self] units in
            
            let dataSource = UnitsDataSource(units: units)
            dataSource.delegate = self
            self?.unitsDataSource = dataSource
            self?.unitsCollectionView.dataSource = dataSource
            
            self?.unitNames = units.map{$0.name} // see comment on var why this is necessary
            
            self?.unitsCollectionView.reloadData()
        })
    }
    
    func loadFractions() {
        Prov.fractionProvider.fractions(successHandler {fractions in
            self.fractions = fractions
        })
    }
    
    func onTap(_ sender: UIView) {
        guard let fractions = fractions else {QL4("No fractions"); return}
        
        if let currentNewFractionInput = currentNewFractionInput {
            
            let dbFraction = DBFraction(numerator: currentNewFractionInput.numerator, denominator: currentNewFractionInput.denominator)
            Prov.fractionProvider.add(fraction: dbFraction, successHandler {[weak self] isNew in guard let weakSelf = self else {return}
                
                if isNew {
                    weakSelf.fractionsCollectionView.insertItems(at: [IndexPath(row: fractions.count - 1, section: 0)])
                    if let editCell = weakSelf.fractionsCollectionView.cellForItem(at: IndexPath(row: fractions.count, section: 0)) as? EditableFractionCell {
                        editCell.editableFractionView.clear()
                    }
                }
                
                weakSelf.currentNewFractionInput = nil
            })
            
        } else {
            /// Clear possible marked to delete fractions - we use "tap outside" as the way to cancel the delete-status
            clearToDeleteFractions()
        }
        
        
        if let currentNewUnitInput = currentNewUnitInput {
            
            guard let dataSource = unitsCollectionView.dataSource else {QL4("No data source"); return}
            guard let unitsDataSource = dataSource as? UnitsDataSource else {QL4("Data source has wrong type: \(type(of: dataSource))"); return}

            Prov.unitProvider.getOrCreate(name: currentNewUnitInput, successHandler{[weak self] (unit, isNew) in guard let weakSelf = self else {return}
                if isNew {
                    
                    weakSelf.unitsCollectionView.insertItems(at: [IndexPath(row: (unitsDataSource.units?.count ?? 0) - 1, section: 0)])
                    if let editCell = weakSelf.unitsCollectionView.cellForItem(at: IndexPath(row: (unitsDataSource.units?.count ?? 0), section: 0)) as? UnitEditableCell {
                        editCell.editableUnitView.clear()
                    }
                }
                
                weakSelf.currentNewUnitInput = nil
            })
            
        } else {
            /// Clear possible marked to delete fractions - we use "tap outside" as the way to cancel the delete-status
            clearToDeleteUnits()
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let view = touch.view else {return false}
        if view.hasAncestor(type: FractionCell.self) || view.hasAncestor(type: EditableFractionCell.self) || view.hasAncestor(type: UnitCell.self) || view.hasAncestor(type: UnitEditableCell.self) {
            return false
        } else {
            return true
        }
    }

    
    fileprivate func initSubmitButton() {
        guard self.submitView == nil else {QL1("Already showing a submit view"); return}
        guard let parentViewForAddButton = delegate?.parentViewForAddButton() else {QL4("No delegate: \(delegate)"); return}
//        guard let tabBarHeight = tabBarController?.tabBar.bounds.size.height else {QL4("No tabBarController"); return}
        
        let height = Theme.submitViewHeight
        let submitView = SubmitView(frame: CGRect(x: 0, y: parentViewForAddButton.frame.maxY, width: parentViewForAddButton.width, height: height))
        submitView.delegate = self
        submitView.setButtonTitle(title: "select_ingredient_data_submit")
        parentViewForAddButton.addSubview(submitView)
        
        anim(3) {
            submitView.y = parentViewForAddButton.frame.maxY - height
//            submitView.height = height
        }
        
        self.submitView = submitView
    }
    
    func onClose() {
        guard let parentViewForAddButton = delegate?.parentViewForAddButton() else {QL4("No delegate: \(delegate)"); submitView?.removeFromSuperview(); return}

        anim(3, {[weak self] in
            self?.submitView?.y = parentViewForAddButton.frame.maxY
//            self?.submitView?.height = 0
            
        }, onFinish:{[weak self] in
            self?.submitView?.removeFromSuperview()
        })
    }
    
    
    deinit {
        QL1("\(type(of: self)) deinit")
    }
    
    func onTextChange(_ sender: UITextField) {
        updateInputsAndTitle()
    }

    func onRequestUpdateQuantity(_ delta: Float) {
        quantityView.quantity += delta
        updateTitle(inputs: inputs)
    }
    
    // MARK: - SwipeToIncrementHelperDelegate
    
    func currentQuantity() -> Float {
        return quantity
    }
    
    func onQuantityUpdated(_ quantity: Float) {
        quantityView.quantity = quantity
        updateTitle(inputs: inputs)
    }
    
    func onFinishSwipe() {
        // do nothing
    }
    
    // MARK: - SubmitViewDelegate
    
    func onSubmitButton() {
        submit()
    }
    
    // MARK: - Private
    
    fileprivate func updateInputsAndTitle() {
        inputs.quantity = quantity

        updateTitle(inputs: inputs)
    }
    
    fileprivate func updateTitle(inputs: SelectIngredientDataControllerInputs) {
        guard let titleLabelsFont = titleLabelsFont else {QL4("No title labels font. Can't update title."); return}
        
        let fractionStr = inputs.fraction.isValidAndNotZeroOrOneByOne ? inputs.fraction.description : ""
        // Don't show quantity if it's 0 and there's a fraction. If there's no fraction we show quantity 0, because otherwise there wouldn't be any number and this doesn't make sense.
        let wholeNumberStr = quantity == 0 ? (fractionStr.isEmpty ? quantity.quantityString : "") : "\(quantity.quantityString)"
        let unitStr = inputs.unitName.isEmpty ? "unit" : inputs.unitName
        
        let boldTime: Double = 1
        
        if fractionLabel.text != fractionStr {
            fractionLabel.animateBold(boldTime, regularFont: titleLabelsFont)
        }
        if wholeNumberLabel.text != wholeNumberStr {
            wholeNumberLabel.animateBold(boldTime, regularFont: titleLabelsFont)
        }
        if unitLabel.text != unitStr {
            unitLabel.animateBold(boldTime, regularFont: titleLabelsFont)
        }
        
        fractionLabel.text = fractionStr
        wholeNumberLabel.text = wholeNumberStr
        unitLabel.text = unitStr
        
        wholeNumberTrailingConstraint.constant = wholeNumberStr.isEmpty || fractionStr.isEmpty ? 0 : 10
        fractionTrailingConstraint.constant = wholeNumberStr.isEmpty && fractionStr.isEmpty ? 0 : 10
    }
    
    // TODO validation - don't allow e.g. to add item with 0 quantity
    
    fileprivate func onSelect(fraction: DBFraction) {
        inputs.fraction = Fraction(wholeNumber: 0, numerator: fraction.numerator, denominator: fraction.denominator)
        
        updateInputsAndTitle()
    }
    
    fileprivate func onSelect(unit: Providers.Unit) {
        inputs.unitName = unit.name
        
        updateInputsAndTitle()
    }
    
    fileprivate func submit() {
        guard let item = item else {QL4("Illegal state: no item. Can't submit"); return}
        
        delegate?.onSubmitIngredientInputs(item: item, inputs: inputs)
    }
}

extension SelectIngredientDataController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, FractionCellDelegate, EditableFractionViewDelegate {
    
    // TODO!!!!!!!!!!!!!!!!!!!!! on select suggestion the top label should also be updated. doesn't seem to be the case currently
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fractions.map{$0.count + 1} ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let fractions = fractions else {QL4("No fractions"); return UICollectionViewCell()}
        
        if indexPath.row < fractions.count {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! FractionCell
            let fraction = fractions[indexPath.row]
            cell.fractionView.fraction = fraction
            cell.fractionView.backgroundColor = Theme.fractionsBGColor
            cell.fractionView.layer.cornerRadius = DimensionsManager.quickAddCollectionViewCellCornerRadius
            cell.fractionView.markedToDelete = false
            cell.delegate = self
            
            let selected = inputs.fraction.numerator == fraction.numerator && inputs.fraction.denominator == fraction.denominator
            cell.fractionView.showSelected(selected: selected, animated: false)
            
            return cell
            
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "editableCell", for: indexPath) as! EditableFractionCell
            cell.editableFractionView.backgroundColor = Theme.fractionsBGColor
            cell.editableFractionView.layer.cornerRadius = DimensionsManager.quickAddCollectionViewCellCornerRadius
            cell.editableFractionView.delegate = self
            cell.editableFractionView.prefill(fraction: currentNewFractionInput)
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let fractions = fractions else {QL4("No fractions"); return}

        
        let cellMaybe = fractionsCollectionView.cellForItem(at: indexPath) as? FractionCell
        
        if cellMaybe?.fractionView.markedToDelete ?? false {
        
            let fraction = fractions[indexPath.row]
            
            Prov.fractionProvider.remove(fraction: fraction, successHandler {[weak self] in
                self?.fractionsCollectionView.deleteItems(at: [indexPath])
                self?.fractionsCollectionView?.collectionViewLayout.invalidateLayout() // seems to fix weird space appearing before last cell (input cell) sometimes
            })
            
        } else {
            clearToDeleteFractions()
            clearSelectedFractions()
            
            if let cell = cellMaybe {
                if isSelected(cell: cell) {
                    cellMaybe?.fractionView.showSelected(selected: false, animated: true)
                    inputs.fraction = Fraction(wholeNumber: 0, numerator: 1, denominator: 1)
                    updateTitle(inputs: inputs)
                    
                } else {
                    cellMaybe?.fractionView.showSelected(selected: true, animated: true)
                    onSelect(fraction: fractions[indexPath.row])
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if (fractions.map{fractions in
            indexPath.row < fractions.count
        }) ?? false {
            return CGSize(width: 70, height: 50)
        } else {
            return CGSize(width: 120, height: 50)
        }
    }
    
    fileprivate func clearToDeleteFractions() {
        for cell in fractionsCollectionView.visibleCells {
            if let fractionCell = cell as? FractionCell { // Note that we cast individual cells, because the collection view is mixed
                fractionCell.fractionView.mark(toDelete: false, animated: true)
            }
        }
    }

    fileprivate func clearSelectedFractions() {
        for cell in fractionsCollectionView.visibleCells {
            if let fractionCell = cell as? FractionCell { // Note that we cast individual cells, because the collection view is mixed
                fractionCell.fractionView.showSelected(selected: false, animated: true)
            }
        }
    }
    
    
    fileprivate func clearToDeleteUnits() {
        for cell in unitsCollectionView.visibleCells {
            if let fractionCell = cell as? UnitCell { // Note that we cast individual cells, because the collection view is mixed
                fractionCell.unitView.mark(toDelete: false, animated: true)
            }
        }
    }
    
    fileprivate func clearSelectedUnits() {
        for cell in unitsCollectionView.visibleCells {
            if let fractionCell = cell as? UnitCell { // Note that we cast individual cells, because the collection view is mixed
                fractionCell.unitView.showSelected(selected: false, animated: true)
            }
        }
    }
    
    fileprivate func isSelected(cell: FractionCell) -> Bool {
        guard let fractionViewFraction = cell.fractionView.fraction else {return false}
        
        return fractionViewFraction.numerator == inputs.fraction.numerator && fractionViewFraction.denominator == inputs.fraction.denominator
    }
    
    fileprivate func isSelected(cell: UnitCell) -> Bool {
        guard let unitViewUnit = cell.unitView.unit else {return false}
        
        return unitViewUnit.name == inputs.unitName
    }
    
    // MARK: - EditableFractionViewDelegate
    
    func onFractionInputChange(fractionInput: Fraction?) {
        currentNewFractionInput = fractionInput
    }
    
    // MARK: - FractionCellDelegate
    
    func onLongPress(cell: FractionCell) {        
        cell.fractionView.markedToDelete = true
        cell.fractionView.mark(toDelete: true, animated: true)
    }
    
    fileprivate func indexPathForFraction(fraction: DBFraction) -> IndexPath? {
        guard let fractions = fractions else {QL4("No fractions"); return nil}
        
        for (index, f) in fractions.enumerated() {
            if f.numerator == fraction.numerator && f.denominator == fraction.denominator {
                return IndexPath(row: index, section: 0)
            }
        }
        
        return nil
        
    }
    
}


extension SelectIngredientDataController: UnitsCollectionViewDataSourceDelegate, UnitsCollectionViewDelegateDelegate {
    
    // MARK: - UnitsCollectionViewDataSourceDelegate
    
    func onUpdateUnitNameInput(nameInput: String) {
        currentNewUnitInput = nameInput
    }
    
    // MARK: - UnitsCollectionViewDelegateDelegate

    func didSelectUnit(indexPath: IndexPath) {
        guard let dataSource = unitsCollectionView.dataSource else {QL4("No data source"); return}
        guard let unitsDataSource = dataSource as? UnitsDataSource else {QL4("Data source has wrong type: \(type(of: dataSource))"); return}
        guard let units = unitsDataSource.units else {QL4("Invalid state: Data source has no units"); return}
        
        let cellMaybe = unitsCollectionView.cellForItem(at: indexPath) as? UnitCell
        
        if cellMaybe?.unitView.markedToDelete ?? false {
            
            let unit = units[indexPath.row]
            Prov.unitProvider.delete(name: unit.name, successHandler {[weak self] in
                self?.unitsCollectionView.deleteItems(at: [indexPath])
                self?.unitsCollectionView?.collectionViewLayout.invalidateLayout() // seems to fix weird space appearing before last cell (input cell) sometimes
            })
            
        } else {
            clearToDeleteUnits()
            clearSelectedUnits()
            
            if let cell = cellMaybe {
                if isSelected(cell: cell) {
                    cellMaybe?.unitView.showSelected(selected: false, animated: true)
                    inputs.unitName = ""
                    updateTitle(inputs: inputs)
                    
                } else {
                    cellMaybe?.unitView.showSelected(selected: true, animated: true)
                    onSelect(unit: units[indexPath.row])
                }
            }
        }
    }
    
    func sizeFotUnitCell(indexPath: IndexPath) -> CGSize {
        if (unitsDataSource?.units.map{unit in
            indexPath.row < unit.count
        }) ?? false {
            return CGSize(width: 70, height: 50)
        } else {
            return CGSize(width: 120, height: 50)
        }
    }
}



protocol UnitsCollectionViewDataSourceDelegate {
    var inputs: SelectIngredientDataControllerInputs {get}
    func onUpdateUnitNameInput(nameInput: String)
}

class UnitsDataSource: NSObject, UICollectionViewDataSource, UnitCellDelegate, UnitEditableViewDelegate, UICollectionViewDelegateFlowLayout {

    var units: Results<Providers.Unit>?

    var delegate: UnitsCollectionViewDataSourceDelegate?
    
    init(units: Results<Providers.Unit>?) {
        self.units = units
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return units.map{$0.count + 1} ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let units = units else {QL4("No units"); return UICollectionViewCell()}
        
        if indexPath.row < units.count {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "unitCell", for: indexPath) as! UnitCell
            let unit = units[indexPath.row]
            cell.unitView.unit = unit
            cell.unitView.bgColor = Theme.unitsBGColor
            cell.unitView.layer.cornerRadius = DimensionsManager.quickAddCollectionViewCellCornerRadius
            cell.unitView.markedToDelete = false
            cell.delegate = self

            
            if let delegate = delegate {
                let selected = delegate.inputs.unitName == unit.name
                cell.unitView.showSelected(selected: selected, animated: false)
                
            } else {
                QL4("No delegate - can't update selected state")
            }
            
            // HACK: For some reason after scrolled the label doesn't use its center constraint and appears aligned to the left. Debugging view hierarchy shows the label has the correct constraints, parent also has correct size but for some reason it's aligned at the left.
            cell.unitView.nameLabel.center = cell.unitView.center
//            cell.setNeedsLayout()
            
            return cell
            
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "unitEditableCell", for: indexPath) as! UnitEditableCell
            cell.editableUnitView.backgroundColor = Theme.unitsBGColor
            cell.editableUnitView.layer.cornerRadius = DimensionsManager.quickAddCollectionViewCellCornerRadius
            cell.editableUnitView.delegate = self
            
            if let delegate = delegate {
                cell.editableUnitView.prefill(name: delegate.inputs.unitName)
            } else {
                QL4("No delegate - prefill input cell")
            }

            return cell
        }
    }
    
    // MARK: - UnitCellDelegate
    
    func onLongPress(cell: UnitCell) {
        cell.unitView.markedToDelete = true
        cell.unitView.mark(toDelete: true, animated: true)
    }
    
    
    // MARK: - EditableUnitCellDelegate
    
    func onUnitInputChange(nameInput: String) {
        delegate?.onUpdateUnitNameInput(nameInput: nameInput)
    }
}


protocol UnitsCollectionViewDelegateDelegate: class {
    func sizeFotUnitCell(indexPath: IndexPath) -> CGSize
    func didSelectUnit(indexPath: IndexPath)
}

class UnitsDelegate: NSObject, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    fileprivate weak var delegate: UnitsCollectionViewDelegateDelegate?
    
    init(delegate: UnitsCollectionViewDelegateDelegate) {
        self.delegate = delegate
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.didSelectUnit(indexPath: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return delegate?.sizeFotUnitCell(indexPath: indexPath) ?? CGSize.zero
    }
    
    
}

