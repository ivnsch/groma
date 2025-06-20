//
//  UnitsDataSource.swift
//  shoppin
//
//  Created by Ivan Schuetz on 20/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import RealmSwift

import Providers

// TODO remove this file

protocol UnitCellDelegate {
    func onLongPress(cell: UnitCell)
}

protocol BaseQuantityCellDelegate {
    func onLongPress(cell: BaseQuantityCell)
}

protocol UnitsCollectionViewDataSourceDelegate {
    var currentUnitName: String {get}
    var unitToDeleteName: String { get }
    func onUpdateUnitNameInput(nameInput: String)
    var minUnitTextFieldWidth: CGFloat {get}
    var highlightSelected: Bool {get}
    func onMarkUnitToDelete(unit: Providers.Unit)
    var collectionView: UICollectionView { get }
}

class UnitsDataSource: NSObject, UICollectionViewDataSource, UnitCellDelegate, UnitEditableViewDelegate, UICollectionViewDelegateFlowLayout {
    
    var units: Results<Providers.Unit>?
    
    var delegate: UnitsCollectionViewDataSourceDelegate?
    
    fileprivate var addNewUnitCell: UnitEditableCell? // to ask if it has focus
    
    init(units: Results<Providers.Unit>?) {
        self.units = units
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return units.map{$0.count + 1} ?? 0 // no input in collection view anymore
        return units.map{$0.count} ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        fatalError("Remove this file")
//        guard let units = units else {logger.e("No units"); return UICollectionViewCell()}
//
//        if indexPath.row < units.count {
//            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "unitCell", for: indexPath) as! UnitCell
//            let unit = units[indexPath.row]
//            cell.unitView.unit = unit
//            cell.unitView.fgColor = Theme.unitsFGColor
//            cell.delegate = self
//
//
//            if let delegate = delegate {
//                if delegate.highlightSelected {
//                    let selected = delegate.currentUnitName == unit.name
//                    cell.unitView.showSelected(selected: selected, animated: false)
//                }
//            } else {
//                logger.e("No delegate")
//            }
//
//            // HACK: For some reason after scrolled the label doesn't use its center constraint and appears aligned to the left. Debugging view hierarchy shows the label has the correct constraints, parent also has correct size but for some reason it's aligned at the left.
//            cell.unitView.nameLabel.center = cell.unitView.center
//            //            cell.setNeedsLayout()
//
//            return cell
//
//        } else /*if indexPath.row == units.count*/ {
//            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "unitEditableCell", for: indexPath) as! UnitEditableCell
//            cell.editableUnitView.backgroundColor = Theme.unitsBGColor
//            cell.editableUnitView.nameTextField.textColor = Theme.unitsFGColor
//            cell.editableUnitView.layer.cornerRadius = DimensionsManager.quickAddCollectionViewCellCornerRadius
//            cell.editableUnitView.delegate = self
//
//            addNewUnitCell = cell
//
//            if let delegate = delegate {
//                cell.editableUnitView.prefill(name: delegate.currentUnitName)
//
//                cell.setMinTextFieldWidth(delegate.minUnitTextFieldWidth)
//
//            } else {
//                logger.e("No delegate")
//            }
//
//            return cell
//
//        }
//        else {
//            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "submitCell", for: indexPath) as! UnitSubmitCell
//            cell.layer.cornerRadius = DimensionsManager.quickAddCollectionViewCellCornerRadius
//            return cell
//        }
    }


    // MARK: - UnitCellDelegate
    
    func onLongPress(cell: UnitCell) {
        guard let delegate = delegate else { logger.e("No delegate"); return }
        guard let indexPath = delegate.collectionView.indexPath(for: cell) else {
            logger.e("Couldn't find cell!", .ui)
            return
        }
        guard let units = units else { logger.e("No units"); return }
        let unit = units[indexPath.row]
        delegate.onMarkUnitToDelete(unit: unit)
//        cell.unitView.markedToDelete = true
        cell.unitView.mark(toDelete: true, animated: true)
    }
    
    
    // MARK: - EditableUnitCellDelegate
    
    func onUnitInputChange(nameInput: String) {
        delegate?.onUpdateUnitNameInput(nameInput: nameInput)
    }
    
    // MARK: -
    
    // TODO maybe do "focusFrame" or something instead. We need the actual possition. Currently we make assumptions about it
    var hasUnitInputFocus: Bool {
        return addNewUnitCell?.hasFocus ?? false
    }
}

