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

    override var collectionViewContentsHeight: CGFloat {
        fatalError("Remove")
//        let collectionViewWidth = myCollectionView.width
////        logger.w("collectionViewWidth: \(collectionViewWidth)", .wildcard)
//        guard collectionViewWidth > 0 else { return 0 } // avoid division by 0
//        let itemCount = dataSource?.items?.count ?? 0
//        let itemsPerRow = floor(collectionViewWidth / unitCellSize.width)
////        let unitsPerRow = CGFloat(5) // for now hardcoded. Calculating it returns 5 (wrong) + using the collection width causes constraint error (because this is called 2-3 times at the beginning with a width of 0) and collapses entirely the collection view. TODO not hardcoded
//        logger.w("collectionViewWidth: \(collectionViewWidth), items per row: \(itemsPerRow)", .wildcard)
//
//        let rowCount = ceil(CGFloat(itemCount) / itemsPerRow)
//        return rowCount * (unitCellSize.height + rowsSpacing) + topCollectionViewPadding + bottomCollectionViewPadding
    }

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
