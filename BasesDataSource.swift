//
//  BasesDataSource.swift
//  shoppin
//
//  Created by Ivan Schuetz on 22/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import RealmSwift

import Providers

protocol BaseQuantitiesDataSourceSourceDelegate {
    var currentBaseQuantity: Float {get}
    func onUpdateBaseQuantityInput(valueInput: Float)
    var minBaseQuantityTextFieldWidth: CGFloat {get}
    var highlightSelectedBaseQuantity: Bool {get}
}

class BasesDataSource: NSObject, UICollectionViewDataSource, BaseQuantityCellDelegate, UnitEditableViewDelegate, UICollectionViewDelegateFlowLayout {
    
    var bases: RealmSwift.List<BaseQuantity>?
    
    var delegate: BaseQuantitiesDataSourceSourceDelegate?
    
    init(bases: RealmSwift.List<BaseQuantity>?) {
        self.bases = bases
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return bases.map{$0.count + 1} ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let bases = bases else {logger.e("No bases"); return UICollectionViewCell()}
        
        if indexPath.row < bases.count {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "baseCell", for: indexPath) as! BaseQuantityCell
            let base = bases[indexPath.row]
            cell.baseQuantityView.base = base
            cell.baseQuantityView.bgColor = Theme.baseQuantitiesBGColor
            cell.baseQuantityView.fgColor = Theme.baseQuantitiesFGColor
            cell.baseQuantityView.layer.cornerRadius = DimensionsManager.quickAddCollectionViewCellCornerRadius
            cell.baseQuantityView.markedToDelete = false
            cell.delegate = self
            
            if let delegate = delegate {
                if delegate.highlightSelectedBaseQuantity {
                    let selected = delegate.currentBaseQuantity == base.val
                    cell.baseQuantityView.showSelected(selected: selected, animated: false)
                }
            } else {
                logger.e("No delegate")
            }
            
            // HACK: For some reason after scrolled the label doesn't use its center constraint and appears aligned to the left. Debugging view hierarchy shows the label has the correct constraints, parent also has correct size but for some reason it's aligned at the left.
            cell.baseQuantityView.baseQuantityLabel.center = cell.baseQuantityView.center
            //            cell.setNeedsLayout()
            
            return cell
            
        } else /*if indexPath.row == bases.count*/ {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "unitEditableCell", for: indexPath) as! UnitEditableCell
            cell.editableUnitView.backgroundColor = Theme.baseQuantitiesBGColor
            cell.editableUnitView.nameTextField.textColor = Theme.baseQuantitiesFGColor
            cell.editableUnitView.layer.cornerRadius = DimensionsManager.quickAddCollectionViewCellCornerRadius
            cell.editableUnitView.delegate = self
            
            
            if let delegate = delegate {
                cell.editableUnitView.prefill(name: delegate.currentBaseQuantity.quantityString)
                
                cell.setMinTextFieldWidth(delegate.minBaseQuantityTextFieldWidth)
                
            } else {
                logger.e("No delegate")
            }
            
            return cell
            
        }
    }
    
    // MARK: - BaseQuantityCellDelegate
    
    func onLongPress(cell: BaseQuantityCell) {
        cell.baseQuantityView.markedToDelete = true
        cell.baseQuantityView.mark(toDelete: true, animated: true)
    }
    
    // MARK: - EditableUnitCellDelegate
    
    func onUnitInputChange(nameInput: String) {
        if let _ = nameInput.floatValue {
            delegate?.onUpdateBaseQuantityInput(valueInput: nameInput.floatValue ?? 1)
        } else {
            logger.e("Invalid base input: \(nameInput)")
        }
    }
}
