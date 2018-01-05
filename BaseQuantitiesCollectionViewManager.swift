//
//  BaseQuantitiesCollectionViewManager.swift
//  groma
//
//  Created by Ivan Schuetz on 21.12.17.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import Providers
import RealmSwift

class BaseQuantitiesCollectionViewManager: DefaultCollectionViewItemManager<BaseQuantity> {

    override func calculateCollectionViewContentsHeight(collectionViewWidth: CGFloat, items: AnyRealmCollection<BaseQuantity>) -> CGFloat {

        let availableWidth = collectionViewWidth - (leftRightCollectionViewPadding * 2)

        var rowsCount = 1
        var currentRowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0
        for item in items {
            let itemSize = calculateItemSize(item: item)
            if rowHeight == 0 { // take any item height - we take the first
                rowHeight = itemSize.height + 2 + 14 // 2->mystery height delta with actual cells in view hierarchy + 10 vertical row spacing
            }
            currentRowWidth += itemSize.width // add item to row
            if currentRowWidth > availableWidth { // row is too big now!
                rowsCount += 1 // new row
                currentRowWidth = itemSize.width // start new row with this item
            }
        }

        return CGFloat(rowsCount) * rowHeight
    }

    func calculateItemSize(item: BaseQuantity) -> CGSize {
        let itemTextSize = item.val.quantityString.size(UIFont.systemFont(ofSize: LabelMore.mapToFontSize(30) ?? 12))

        let interItemHSpace: CGFloat = 20
        let interItemVSpace: CGFloat = 14
        let leftRightPadding: CGFloat = 16 // From base quantity view nib
        let topBottomPadding: CGFloat = 8 // From base quantity view nib

        return CGSize(width: leftRightPadding * 2 + itemTextSize.width + interItemHSpace, height: topBottomPadding * 2 + itemTextSize.height + interItemVSpace)
    }

    override func sizeFotItemCell(indexPath: IndexPath) -> CGSize {
        guard let items = dataSource?.items else { logger.e("No items"); return CGSize.zero }
        let item = items[indexPath.row]
        return calculateItemSize(item: item)
    }
    
    override func registerCell() {
        collectionView.register(UINib(nibName: "BaseQuantityCell", bundle: nil), forCellWithReuseIdentifier: "baseCell")
    }

    override func createDataSource(items: AnyRealmCollection<BaseQuantity>) -> UnitOrBaseDataSource<BaseQuantity> {
        return BaseQuantitiesDataSource(items: items)
    }

    override func fetchItems(controller: UIViewController, onSucces: @escaping (AnyRealmCollection<BaseQuantity>) -> Void) {
        Prov.unitProvider.baseQuantities(controller.successHandler{ bases in
            onSucces(AnyRealmCollection(bases))
        })
    }

    override func delete(item: BaseQuantity, controller: UIViewController, onFinish: @escaping () -> Void) {
        Prov.unitProvider.delete(baseQuantity: item.val, controller.successHandler {
            onFinish()
        })
    }

    override func confirmRemoveItemPopupMessage(item: BaseQuantity) -> String {
        return trans("popup_remove_base_completion_confirm", item.val.quantityString)
    }

    override func allowRemoveItem(item: BaseQuantity, controller: UIViewController) -> Bool {
        if item.val == 1 {
            AlertPopup.show(message: trans("popup_you_cant_delete_default_base_quantity"), controller: controller)
            return false
        } else {
            return true
        }
    }
}

// TODO implement edit also with this and remove UnitsDataSource, previous controller. Rename this in UnitsDataSource.
class BaseQuantitiesDataSource: UnitOrBaseDataSource<BaseQuantity> {

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let items = items else { logger.e("No items"); return UICollectionViewCell() }

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "baseCell", for: indexPath) as! BaseQuantityCell
        let base = items[indexPath.row]
        cell.baseQuantityView.base = base
        cell.delegate = self

        if let delegate = delegate {
            if delegate.highlightSelected {
                let selected = delegate.currentItemName == base.val.quantityString
                cell.baseQuantityView.showSelected(selected: selected, animated: false)
            }
        } else {
            logger.e("No delegate")
        }
//
//        // HACK: For some reason after scrolled the label doesn't use its center constraint and appears aligned to the left. Debugging view hierarchy shows the label has the correct constraints, parent also has correct size but for some reason it's aligned at the left.
//        cell.baseQuantityView.nameLabel.center = cell.unitView.center
//        //            cell.setNeedsLayout()

        return cell
    }
}
