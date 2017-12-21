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

    override func registerCell() {
        collectionView.register(UINib(nibName: "UnitCell", bundle: nil), forCellWithReuseIdentifier: "unitCell")
    }

    override func createDataSource(items: Results<Providers.Unit>) -> UnitOrBaseDataSource<Providers.Unit> {
        return UnitsDataSourceNew(items: items)
    }

    override func fetchItems(controller: UIViewController, onSucces: @escaping (Results<Providers.Unit>) -> Void) {
        Prov.unitProvider.units(buyable: nil, controller.successHandler{ units in
            onSucces(units)
        })
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
        cell.unitView.markedToDelete = false
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
        cell.unitView.nameLabel.center = cell.unitView.center
        //            cell.setNeedsLayout()

        return cell
    }
}
