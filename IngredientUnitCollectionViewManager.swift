//
//  IngredientUnitCollectionViewManager.swift
//  groma
//
//  Created by Ivan Schuetz on 17.12.17.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import Providers
import RealmSwift


// TODO remove this file
class IngredientUnitCollectionViewManager {

    var view: UIView {
        return unitsCollectionView
    }

    var units: Results<Providers.Unit>? {
        return unitsDataSource?.units
    }

//    var inputs: SelectIngredientDataControllerInputs = SelectIngredientDataControllerInputs()
    fileprivate var unitsCollectionView: UICollectionView!
//    weak var unitDelegate: SelectUnitControllerDelegate?
    fileprivate var unitsDataSource: UnitsDataSource?
    fileprivate var unitsDelegate: UnitsDelegate? // arc
    fileprivate var unitNames: [String] = [] // we need this because we can't touch the Realm Units in the autocompletions thread (get diff. thread exception). So we have to map to Strings in advance.
    fileprivate let unitCellSize = CGSize(width: 60, height: 76)
    fileprivate var currentNewUnitInput: String?

    fileprivate weak var controller: UIViewController?

    var onSelectUnit: ((Providers.Unit?) -> Void)?
    fileprivate var selectedUnit: (() -> Providers.Unit?)?
    var onMarkedUnitToDelete: ((Providers.Unit?) -> Void)?
    var unitMarkedToDelete: (() -> Providers.Unit?)?
    var willDeleteUnit: ((Providers.Unit) -> Void)?

    fileprivate let rowsSpacing: CGFloat = 4
    fileprivate let topCollectionViewPadding: CGFloat = 20
    fileprivate let bottomCollectionViewPadding: CGFloat = 20

    var unitContentsHeight: CGFloat {
        //        let collectionViewWidth = unitsCollectionView.width
        //        guard collectionViewWidth > 0 else { return 0 } // avoid division by 0
        let unitCount = unitsDataSource?.units?.count ?? 0
        //        let unitsPerRow = floor(collectionViewWidth / unitCellSize.width)
        let unitsPerRow = CGFloat(5) // for now hardcoded. Calculating it returns 5 (wrong) + using the collection width causes constraint error (because this is called 2-3 times at the beginning with a width of 0) and collapses entirely the collection view. TODO not hardcoded
        let rowCount = ceil(CGFloat(unitCount) / unitsPerRow)
        return rowCount * (unitCellSize.height + rowsSpacing) + topCollectionViewPadding + bottomCollectionViewPadding
    }

    func configure(controller: UIViewController, onSelectUnit: @escaping ((Providers.Unit?) -> Void)) {

        self.controller = controller
        self.onSelectUnit = onSelectUnit

        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.sectionInset = UIEdgeInsetsMake(20, 30, 20, 30)
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.minimumLineSpacing = rowsSpacing

        unitsCollectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: flowLayout)

        unitsCollectionView.bounces = false
        unitsCollectionView.backgroundColor = UIColor.clear

        let delegate = UnitsDelegate(delegate: self)
        unitsCollectionView.delegate = delegate
        unitsDelegate = delegate

        unitsCollectionView.register(UINib(nibName: "UnitCell", bundle: nil), forCellWithReuseIdentifier: "unitCell")

        Prov.unitProvider.units(buyable: nil, controller.successHandler{[weak self] units in

            let dataSource = UnitsDataSource(units: units)
            dataSource.delegate = self
            self?.unitsDataSource = dataSource
            self?.unitsCollectionView.dataSource = dataSource

            self?.unitNames = units.map{ $0.name } // see comment on var why this is necessary

            self?.unitsCollectionView.reloadData()
//            self?.reload()
        })
    }
}


extension IngredientUnitCollectionViewManager: UnitsCollectionViewDataSourceDelegate, UnitsCollectionViewDelegateDelegate {

    // MARK: - UnitsCollectionViewDataSourceDelegate

    var currentUnitName: String {
        return selectedUnit?()?.name ?? ""
    }

    var unitToDeleteName: String {
        return unitMarkedToDelete?()?.name ?? ""
    }

    func onUpdateUnitNameInput(nameInput: String) {
        currentNewUnitInput = nameInput
    }

    // MARK: - UnitsCollectionViewDelegateDelegate

    func didSelectUnit(indexPath: IndexPath) {
        guard let controller = controller else { logger.e("No controller!"); return }

        guard let dataSource = unitsCollectionView.dataSource else {logger.e("No data source"); return}
        guard let unitsDataSource = dataSource as? UnitsDataSource else {logger.e("Data source has wrong type: \(type(of: dataSource))"); return}
        guard let units = unitsDataSource.units else {logger.e("Invalid state: Data source has no units"); return}
        guard let unitMarkedToDelete = unitMarkedToDelete else {logger.e("Invalid state: Data source has no units"); return}

        let selectedUnit = units[indexPath.row]

        let cellMaybe = unitsCollectionView.cellForItem(at: indexPath) as? UnitCell

        if unitMarkedToDelete()?.name == selectedUnit.name {

            let unit = units[indexPath.row]
            willDeleteUnit?(unit)
            Prov.unitProvider.delete(name: unit.name, notificationToken: nil, controller.successHandler {[weak self] in
                self?.unitsCollectionView.deleteItems(at: [indexPath])
                self?.unitsCollectionView?.collectionViewLayout.invalidateLayout() // seems to fix weird space appearing before last cell (input cell) sometimes
            })

        } else {
            clearToDeleteUnits()
            clearSelectedUnits()

            if let cell = cellMaybe {
                if isSelected(cell: cell) {
                    cellMaybe?.unitView.showSelected(selected: false, animated: true)
//                    inputs.unitName = ""
//                    updateTitle(inputs: inputs)
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
            return unitCellSize
        } else {
            return CGSize(width: 120, height: 50)
        }
    }

    internal var minUnitTextFieldWidth: CGFloat {
        return 70
    }

    var highlightSelected: Bool {
        return true
    }

    func onMarkUnitToDelete(unit: Providers.Unit) {
        onMarkedUnitToDelete?(unit)
    }

    var collectionView: UICollectionView {
        return unitsCollectionView
    }

    fileprivate func onSelect(unit: Providers.Unit) {
        onSelectUnit?(unit)

        //        inputs.unitName = unit.name
        //
        //        updateInputsAndTitle()
        //
        //        unitDelegate?.onSelectUnit(unit: unit)
    }

    fileprivate func isSelected(cell: UnitCell) -> Bool {
        guard let unitViewUnit = cell.unitView.unit else {return false}
        let selectedUnitName: String? = selectedUnit?()?.name
        return selectedUnitName.map { $0 == unitViewUnit.name } ?? false
    }

    func clearSelectedUnits() {
        for cell in unitsCollectionView.visibleCells {
            if let unitCell = cell as? UnitCell { // Note that we cast individual cells, because the collection view is mixed
                unitCell.unitView.showSelected(selected: false, animated: true)
            }
        }
    }

    func clearToDeleteUnits() {
        for cell in unitsCollectionView.visibleCells {
            if let fractionCell = cell as? UnitCell { // Note that we cast individual cells, because the collection view is mixed
                fractionCell.unitView.mark(toDelete: false, animated: true)
            }
        }
    }

    fileprivate func updateTitle(inputs: SelectIngredientDataControllerInputs) {

    }

    func markUnitToDelete(unit: Providers.Unit) {
        for cell in unitsCollectionView.visibleCells {
            if let unitCell = cell as? UnitCell { // Note that we cast individual cells, because the collection view is mixed
                if let cellUnit = unitCell.unitView.unit {
                    if cellUnit.name == unit.name {
                        unitCell.unitView.mark(toDelete: true, animated: true)
                        break
                    }
                } else {
                    logger.e("Illegal state: cell without unit", .ui)
                }
            }
        }
    }
}


