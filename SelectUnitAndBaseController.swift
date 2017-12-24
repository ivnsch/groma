//
//  SelectUnitAndBaseController.swift
//  groma
//
//  Created by Ivan Schuetz on 20.12.17.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import Providers

struct SelectUnitAndBaseControllerInputs {
    var unitId: UnitId? = nil
    var unitName: String? = nil // assumed to be unique
    var baseQuantityName: String? = nil // assumed to be unique // TODO remove this

    var baseQuantity: Float? = nil // assumed to be unique

    var unitMarkedToDelete: String? = nil // name (assumed to be unique)
    var baseQuantityMarkedToDelete: String? = nil // name (assumed to be unique)
}

struct SelectUnitAndBaseControllerResult {
    var unitId: UnitId // TODO remove unitName?
    var unitName: String // assumed to be unique
    var baseQuantity: Float // assumed to be unique
}

class SelectUnitAndBaseController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    fileprivate var unitsManager = UnitCollectionViewManager(filterBuyable: true)
    fileprivate var baseQuantitiesManager = BaseQuantitiesCollectionViewManager()

    fileprivate var inputs = SelectUnitAndBaseControllerInputs()

    fileprivate var unitsViewHeight: CGFloat?
    fileprivate var baseQuantitiesViewHeight: CGFloat?

    var onSubmit: ((SelectUnitAndBaseControllerResult) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        initTableView()
        configUnitsManager()
        configBaseQuantitiesManager()
    }

    func config(selectedUnitId: UnitId, selectedUnitName: String, selectedBaseQuantity: Float) {
        // TODO redundancy - only one identifier for unit and base respectively
        inputs.unitId = selectedUnitId
        inputs.unitName = selectedUnitName
        inputs.baseQuantity = selectedBaseQuantity
        inputs.baseQuantityName = selectedBaseQuantity.quantityString

        unitsManager.reload()
        baseQuantitiesManager.reload()
    }

    fileprivate func initTableView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.register(UINib(nibName: "IngredientDataSubHeaderCell", bundle: nil), forCellReuseIdentifier: "subHeaderCell")
        tableView.register(UINib(nibName: "AddNewItemInputCell", bundle: nil), forCellReuseIdentifier: "inputCell")
    }

    fileprivate func configUnitsManager() {
        unitsManager.configure(controller: self, onSelectItem: { [weak self] unit in
            self?.inputs.unitName = unit?.name
            delay(0.2) { [weak self] in // make it less abrubt
                self?.tableView.scrollToRow(at: IndexPath(row: 2, section: 0), at: .top, animated: true)
            }
        })

        unitsManager.onSelectItem = { [weak self] unit in
            self?.inputs.unitMarkedToDelete = nil // clear possible marked to delete unit
            self?.inputs.unitId = unit?.id
            self?.inputs.unitName = unit?.name
        }
        unitsManager.onMarkedItemToDelete = { [weak self] uniqueName in
            self?.inputs.unitMarkedToDelete = nil // clear possible marked to delete unit
            self?.inputs.unitMarkedToDelete = uniqueName
            //            if let unit = unit {
            //                self?.unitsManager.markUnitToDelete(unit: unit)
            //            }
        }
        unitsManager.itemMarkedToDelete = { [weak self] in
            return self?.inputs.unitMarkedToDelete
        }
        // for now clear variables BEFORE of realm delete - reason: clear possible selected unit - we have to compare with deleted unit to see if it's the same, and this crashes if it is, because after realm delete the object is invalid.
        // TODO possible solution: Don't retain any Realm objects here, only ids.
        unitsManager.willDeleteItem = { [weak self] unit in
            self?.inputs.unitMarkedToDelete = nil
            if unit.name == self?.inputs.unitName {
                self?.inputs.unitName = nil
            }
        }

        unitsManager.clearToDeleteItemsState = { [weak self] in
            self?.inputs.unitMarkedToDelete = nil
        }

        unitsManager.selectedItem = { [weak self] in
            return self?.inputs.unitName
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Here collection view width (needed to calculate the content height) is corrent
        initVariableCellHeights()
    }

    fileprivate func initVariableCellHeights() {
        unitsViewHeight = unitsManager.collectionViewContentHeight()
        baseQuantitiesViewHeight = baseQuantitiesManager.collectionViewContentHeight()
        tableView.reloadData()
    }

    fileprivate func configBaseQuantitiesManager() {
        baseQuantitiesManager.configure(controller: self, onSelectItem: { [weak self] baseQuantity in
            self?.inputs.baseQuantityName = baseQuantity?.val.quantityString
        })

        baseQuantitiesManager.onSelectItem = { [weak self] base in
            self?.inputs.baseQuantityMarkedToDelete = nil // clear possible marked to delete unit
            self?.inputs.baseQuantity = base?.val
        }
        baseQuantitiesManager.onMarkedItemToDelete = { [weak self] base in
            self?.inputs.baseQuantityMarkedToDelete = nil // clear possible marked to delete unit
            self?.inputs.baseQuantityMarkedToDelete = base
            //            if let unit = unit {
            //                self?.unitsManager.markUnitToDelete(unit: unit)
            //            }
        }
        baseQuantitiesManager.itemMarkedToDelete = { [weak self] in
            return self?.inputs.baseQuantityMarkedToDelete
        }
        // for now clear variables BEFORE of realm delete - reason: clear possible selected unit - we have to compare with deleted unit to see if it's the same, and this crashes if it is, because after realm delete the object is invalid.
        // TODO possible solution: Don't retain any Realm objects here, only ids.
        baseQuantitiesManager.willDeleteItem = { [weak self] base in
            self?.inputs.baseQuantityMarkedToDelete = nil
            if base.val.quantityString == self?.inputs.baseQuantityName {
                self?.inputs.baseQuantityName = nil
            }
        }

        baseQuantitiesManager.clearToDeleteItemsState = { [weak self] in
            self?.inputs.baseQuantityMarkedToDelete = nil
        }

        baseQuantitiesManager.selectedItem = { [weak self] in
            return self?.inputs.baseQuantityName
        }
    }

    fileprivate func submit() {
        // TODO ensure that there's always a unit and a base selected!
        guard let unitId = inputs.unitId else { logger.e("Can't submit without a unit"); return }
        guard let unitName = inputs.unitName else { logger.e("Can't submit without unit name"); return } // TODO remove name?
        guard let baseQuantity = inputs.baseQuantity else { logger.e("Can't submit without base"); return }

        // Possible creation of unit/base quantity, if they were entered via text input
        Prov.unitProvider.getOrCreate(name: unitName) { result in
            if !result.success {
                logger.e("Couldn't get/create unit: \(unitName)", .db)
            }
            Prov.unitProvider.getOrCreate(baseQuantity: baseQuantity) { [weak self] result in
                if !result.success {
                    logger.e("Couldn't get/create unit: \(unitName)", .db)
                }

                let result = SelectUnitAndBaseControllerResult(
                    unitId: unitId,
                    unitName: unitName,
                    baseQuantity: baseQuantity
                )
                self?.onSubmit?(result)
            }
        }
    }
}

extension SelectUnitAndBaseController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 6
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let submitView = SubmitView()
        submitView.setButtonTitle(title: trans("update_base_unit_submit_button_title"))
        submitView.delegate = self
        return submitView
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return Theme.submitViewHeight
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        func dequeueDefaultCell() -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            cell.selectionStyle = .none
            cell.contentView.removeSubviews()
            return cell
        }

        switch indexPath.row {
        case 1:
            let cell = dequeueDefaultCell()
            let view = unitsManager.view
            cell.contentView.addSubview(view)
            view.frame = cell.contentView.bounds // appears to be necessary
            view.fillSuperview()
            return cell
        case 4:
            let cell = dequeueDefaultCell()
            let view = baseQuantitiesManager.view
            cell.contentView.addSubview(view)
            view.frame = cell.contentView.bounds // appears to be necessary
            view.fillSuperview()
            return cell
        case 0, 3: // headers
            let header = tableView.dequeueReusableCell(withIdentifier: "subHeaderCell", for: indexPath) as! IngredientDataSubHeaderCell
            header.title.text = indexPath.row == 0 ? trans("select_ingredient_data_header_units") : trans("select_ingredient_data_header_quantity")
            return header
        case 2: // unit input
            let itemInputCell = tableView.dequeueReusableCell(withIdentifier: "inputCell", for: indexPath) as! AddNewItemInputCell
            itemInputCell.configure(placeholder: trans("enter_custom_unit_placeholder"), onInputUpdate: { [weak self] unitInput in
                self?.inputs.unitId = .custom
                self?.inputs.unitName = unitInput.isEmpty ? nil : unitInput
                if !unitInput.isEmpty {
                    self?.unitsManager.clearSelectedItems() // Input overwrites possible selection
                    self?.unitsManager.clearToDeleteItems() // Clear delete state too
                }
            })
            return itemInputCell
        case 5: // base input
            let itemInputCell = tableView.dequeueReusableCell(withIdentifier: "inputCell", for: indexPath) as! AddNewItemInputCell
            itemInputCell.configure(placeholder: trans("enter_custom_base_quantity_placeholder"), onInputUpdate: { [weak self] baseInput in
                self?.inputs.baseQuantityName = baseInput.isEmpty ? nil : baseInput
                self?.inputs.baseQuantity = baseInput.isEmpty ? nil : baseInput.floatValue
                if !baseInput.isEmpty {
                    self?.baseQuantitiesManager.clearSelectedItems() // Input overwrites possible selection
                    self?.baseQuantitiesManager.clearToDeleteItems() // Clear delete state too
                }
            })
            return itemInputCell
        default: fatalError("Not supported index: \(indexPath.row)")
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row {
        case 1: return unitsViewHeight ?? 600 // dummy big default size, with 0 constraint errors in console (at the beginning the collection collection view has no width)
        case 4: return baseQuantitiesViewHeight ?? 600
        case 0, 3: return 50 // header
        case 2, 5: return 80 // text inputs
        default: fatalError("Not supported index: \(indexPath.row)")
        }
    }
}

extension SelectUnitAndBaseController: SubmitViewDelegate {

    func onSubmitButton() {
        submit()
    }
}
