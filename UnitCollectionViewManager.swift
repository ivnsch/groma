//
//  UnitCollectionViewManager.swift
//  groma
//
//  Created by Ivan Schuetz on 20.12.17.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import Providers
import RealmSwift

class UnitCollectionViewManager: DefaultCollectionViewItemManager<Providers.Unit> {

    fileprivate let unitCellSize = CGSize(width: 60, height: 76)

    fileprivate let filterBuyable: Bool

    init(filterBuyable: Bool = false) {
        self.filterBuyable = filterBuyable
    }

    override func sizeFotItemCell(indexPath: IndexPath) -> CGSize {
        if (dataSource?.items.map{unit in
            indexPath.row < unit.count
            }) ?? false {
            return unitCellSize
        } else {
            return CGSize(width: 120, height: 50)
        }
    }

    override func calculateCollectionViewContentsHeight(collectionViewWidth: CGFloat, items: AnyRealmCollection<Providers.Unit>) -> CGFloat {
        let collectionViewWidth = myCollectionView.width
        guard collectionViewWidth > 0 else { return 0 } // avoid division by 0
        let unitCount = dataSource?.items?.count ?? 0
        let unitsPerRow = floor((collectionViewWidth - leftRightCollectionViewPadding * 2) / unitCellSize.width)
//        let unitsPerRow = CGFloat(5) // for now hardcoded. Calculating it returns 6 (wrong) + using the collection width causes constraint error (because this is called 2-3 times at the beginning with a width of 0) and collapses entirely the collection view. TODO not hardcoded
        let rowCount = ceil(CGFloat(unitCount) / unitsPerRow)
        return rowCount * (unitCellSize.height + rowsSpacing) + topCollectionViewPadding + bottomCollectionViewPadding
    }

    override func registerCell() {
        collectionView.register(UINib(nibName: "UnitCell", bundle: nil), forCellWithReuseIdentifier: "unitCell")
    }

    override func createDataSource(items: AnyRealmCollection<Providers.Unit>) -> UnitOrBaseDataSource<Providers.Unit> {
        return UnitsDataSourceNew(items: items)
    }

    override func fetchItems(controller: UIViewController, onSucces: @escaping (AnyRealmCollection<Providers.Unit>) -> Void) {
        Prov.unitProvider.units(buyable: filterBuyable ? true : nil, controller.successHandler{ [weak self] units in
            onSucces(AnyRealmCollection(units))
            self?.observeResults(units)
        })
    }

    override func delete(item: Providers.Unit, controller: UIViewController, onFinish: @escaping () -> Void) {
        guard let notificationToken = self.notificationToken else { logger.e("No notification token!"); return }
        Prov.unitProvider.delete(name: item.uniqueName, notificationToken: notificationToken, controller.successHandler {
            onFinish()
        })
    }

    override func confirmRemoveItemPopupMessage(item: Providers.Unit) -> String {
        return trans("popup_remove_unit_completion_confirm", item.name)
    }

    override func allowRemoveItem(item: Providers.Unit, controller: UIViewController) -> Bool {
        if item.id == .none {
            MyPopupHelper.showPopup(parent: controller, type: .info, message: trans("popup_you_cant_delete_default_unit"), centerYOffset: -80)
            return false
        } else {
            return true
        }
    }
}

// TODO implement edit also with this and remove UnitsDataSource, previous controller. Rename this in UnitsDataSource.
class UnitsDataSourceNew: UnitOrBaseDataSource<Providers.Unit> {

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let units = items else {logger.e("No units"); return UICollectionViewCell()}

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "unitCell", for: indexPath) as! UnitCell
        let unit = units[indexPath.row]
        cell.unitView.unit = unit
        cell.unitView.fgColor = Theme.unitsFGColor
        cell.delegate = self

        if let delegate = delegate {
            if delegate.highlightSelected {
                let selected = delegate.currentItemName == unit.name
                cell.unitView.showSelected(selected: selected, animated: false)
            }
        } else {
            logger.e("No delegate")
        }

        // HACK: For some reason after scrolled the label doesn't use its center constraint and appears aligned to the left. Debugging view hierarchy shows the label has the correct constraints, parent also has correct size but for some reason it's aligned at the left.
//        cell.unitView.nameLabel.center = cell.unitView.center
        //            cell.setNeedsLayout()


        // To center label horizontally in some cases - see note in UnitView.layoutSubviews
        cell.unitView.setNeedsLayout()
        cell.unitView.layoutIfNeeded()

        return cell
    }
}
