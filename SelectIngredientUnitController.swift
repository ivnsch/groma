//
//  SelectIngredientUnitController.swift
//  shoppin
//
//  Created by Ivan Schuetz on 26/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import RealmSwift
import Providers
import QorumLogs

class SelectIngredientUnitController: UIViewController, UnitsCollectionViewDataSourceDelegate, UnitsCollectionViewDelegateDelegate, UIGestureRecognizerDelegate {

    @IBOutlet weak var unitsCollectionView: UICollectionView!
    @IBOutlet weak var collectionViewHeight: NSLayoutConstraint!
    
    weak var delegate: SelectUnitControllerDelegate?

    fileprivate var units: Results<Providers.Unit>?
    
    fileprivate var unitsDataSource: UnitsDataSource?
    fileprivate var unitsDelegate: UnitsDelegate? // arc
    
    
    fileprivate var selectedUnit: Providers.Unit?
    
    fileprivate var currentNewUnitInput: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        initUnitsCollectionView()
        
        addBackgroundTap()
    }
    
    fileprivate func addBackgroundTap() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(onTap(_:)))
        tap.delegate = self
        view.addGestureRecognizer(tap)
    }
    
    func onTap(_ sender: UIView) {
        
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
            /// Clear possible marked to delete units - we use "tap outside" as the way to cancel the delete-status
            clearToDeleteUnits()
        }
    }
    
    // MARK: - UIGestureRecognizerDelegate
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let view = touch.view else {return false}
        if view.hasAncestor(type: UnitCell.self) || view.hasAncestor(type: UnitEditableCell.self) {
            return false
        } else {
            return true
        }
    }
    
    // MARK: -
    
    fileprivate func initUnitsCollectionView() {
        
        let delegate = UnitsDelegate(delegate: self)
        unitsCollectionView.delegate = delegate
        unitsDelegate = delegate
        
        Prov.unitProvider.units(buyable: nil, successHandler{[weak self] units in guard let weakSelf = self else {return}
            
            let dataSource = UnitsDataSource(units: units)
            dataSource.delegate = self
            weakSelf.unitsDataSource = dataSource
            weakSelf.unitsCollectionView.dataSource = dataSource
            
            weakSelf.units = units
     
            weakSelf.unitsCollectionView.reloadData()
     
            let size = weakSelf.unitsCollectionView.collectionViewLayout.collectionViewContentSize
            
            weakSelf.collectionViewHeight.constant = size.height
            
            weakSelf.delegate?.onCalculatedUnitsCollectionViewSize(size)
        })
    }
    
    func selectUnit(unit: Providers.Unit) {
        
        clearSelectedUnits()
        
        selectedUnit = unit
        
        if let indexPath = findIndexPath(unit: unit) {
            if let cell = unitsCollectionView.cellForItem(at: indexPath) as? UnitCell {
                cell.unitView.showSelected(selected: true, animated: true)
            } else {
                QL2("No cell for index path: \(indexPath) or wrong type")
            }
        } else {
            QL4("Didn't find index path to select unit: \(unit)")
        }
    }
    
    fileprivate func findIndexPath(unit: Providers.Unit) -> IndexPath? {
        guard let dataSource = unitsCollectionView.dataSource else {QL4("No data source"); return nil}
        guard let unitsDataSource = dataSource as? UnitsDataSource else {QL4("Data source has wrong type: \(type(of: dataSource))"); return nil}
        guard let units = unitsDataSource.units else {QL4("Invalid state: Data source has no units"); return nil}
        
        for (index, u) in units.enumerated() {
            if u.same(unit) {
                return IndexPath(row: index, section: 0)
            }
        }
        return nil
    }
    
    fileprivate func onSelect(unit: Providers.Unit) {
        selectedUnit = unit
        
        delegate?.onSelectUnit(unit: unit)
    }
    
    fileprivate func isSelected(cell: UnitCell) -> Bool {
        guard let unitViewUnit = cell.unitView.unit else {return false}
        
        return selectedUnit.map{$0.name == unitViewUnit.name} ?? false
    }
    
    fileprivate func clearSelectedUnits() {
        for cell in unitsCollectionView.visibleCells {
            if let fractionCell = cell as? UnitCell { // Note that we cast individual cells, because the collection view is mixed
                fractionCell.unitView.showSelected(selected: false, animated: true)
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
    // MARK: - UnitsCollectionViewDataSourceDelegate
    
    var currentUnitName: String {
        return selectedUnit?.name ?? ""
    }
    
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
                if isSelected(cell: cell) { // clear selection
                    cellMaybe?.unitView.showSelected(selected: false, animated: true)
                    selectedUnit = nil
//                    updateTitle(inputs: inputs) // TODO!!!!!!!!!!!!!
                    
                } else { // select
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
            return CGSize(width: 70, height: DimensionsManager.ingredientsUnitCellHeight)
        } else {
            return CGSize(width: 120, height: DimensionsManager.ingredientsUnitCellHeight)
        }
    }
    
    internal var minUnitTextFieldWidth: CGFloat {
        return 70
    }
    
    var highlightSelected: Bool {
        return true
    }
    
    var isUnitInputFocused: Bool {
        return unitsDataSource?.hasUnitInputFocus ?? false
    }
}
