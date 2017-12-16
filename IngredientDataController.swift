//
//  IngredientDataController.swift
//  groma
//
//  Created by Ivan Schuetz on 16.12.17.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import Providers

class IngredientDataController: UITableViewController {

    weak var controller: QuickAddListItemViewController?

    var inputs: SelectIngredientDataControllerInputs = SelectIngredientDataControllerInputs()
    var unitsCollectionView: UICollectionView!
    weak var unitDelegate: SelectUnitControllerDelegate?
    fileprivate var unitsDataSource: UnitsDataSource?
    fileprivate var unitsDelegate: UnitsDelegate? // arc
    fileprivate var unitNames: [String] = [] // we need this because we can't touch the Realm Units in the autocompletions thread (get diff. thread exception). So we have to map to Strings in advance.

    fileprivate var currentNewUnitInput: String?

    var cellCount = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        let flowLayout = UICollectionViewFlowLayout()
        unitsCollectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: flowLayout)

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")

        initUnitsCollectionView()

        cellCount = 3
        reload()
    }

    fileprivate func initUnitsCollectionView() {
        let delegate = UnitsDelegate(delegate: self)
        unitsCollectionView.delegate = delegate
        unitsDelegate = delegate

        unitsCollectionView.register(UINib(nibName: "UnitCell", bundle: nil), forCellWithReuseIdentifier: "unitCell")

        Prov.unitProvider.units(buyable: nil, successHandler{[weak self] units in

            let dataSource = UnitsDataSource(units: units)
            dataSource.delegate = self
            self?.unitsDataSource = dataSource
            self?.unitsCollectionView.dataSource = dataSource

            self?.unitNames = units.map{ $0.name } // see comment on var why this is necessary

            self?.unitsCollectionView.reloadData()

            self?.reload()
        })
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = SelectIngredientDataHeader.createView()
        header.backgroundColor = UIColor.flatRed
        return header
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellCount
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.selectionStyle = .none

        cell.contentView.removeSubviews()

        switch indexPath.row {
        case 0:
            cell.contentView.addSubview(unitsCollectionView)
            unitsCollectionView.frame = cell.contentView.bounds
            unitsCollectionView.fillSuperview()
            return cell
        case 1: return cell
        case 2: return cell
        default: fatalError("Only 3 cells supported")
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row {
        case 0: return 400
        case 1: return 300
        case 2: return 300
        default: fatalError("Only 3 cells supported")
        }
    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        controller?.scrollableBottomAttacher?.onBottomViewDidScroll(scrollView)
    }
}

extension IngredientDataController: UnitsCollectionViewDataSourceDelegate, UnitsCollectionViewDelegateDelegate {

    // MARK: - UnitsCollectionViewDataSourceDelegate

    var currentUnitName: String {
        return inputs.unitName
    }

    func onUpdateUnitNameInput(nameInput: String) {
        currentNewUnitInput = nameInput
    }

    // MARK: - UnitsCollectionViewDelegateDelegate

    func didSelectUnit(indexPath: IndexPath) {
        guard let dataSource = unitsCollectionView.dataSource else {logger.e("No data source"); return}
        guard let unitsDataSource = dataSource as? UnitsDataSource else {logger.e("Data source has wrong type: \(type(of: dataSource))"); return}
        guard let units = unitsDataSource.units else {logger.e("Invalid state: Data source has no units"); return}

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

    internal var minUnitTextFieldWidth: CGFloat {
        return 70
    }

    var highlightSelected: Bool {
        return true
    }

    fileprivate func onSelect(unit: Providers.Unit) {
//        inputs.unitName = unit.name
//
//        updateInputsAndTitle()
//
//        unitDelegate?.onSelectUnit(unit: unit)
    }

    fileprivate func isSelected(cell: UnitCell) -> Bool {
        guard let unitViewUnit = cell.unitView.unit else {return false}

        return unitViewUnit.name == inputs.unitName
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

    fileprivate func updateTitle(inputs: SelectIngredientDataControllerInputs) {

    }
}
