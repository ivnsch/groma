//
//  DefaultCollectionViewItemManager.swift
//  groma
//
//  Created by Ivan Schuetz on 20.12.17.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import Providers
import RealmSwift

protocol WithUniqueName {
    var uniqueName: String { get }
}

extension Providers.Unit: WithUniqueName {
    var uniqueName: String {
        return name
    }
}

extension BaseQuantity: WithUniqueName {
    var uniqueName: String {
        return val.quantityString
    }
}


class DefaultItemMeasureCell: UICollectionViewCell {

    var itemName: String {
        fatalError("Override")
    }

    func show(selected: Bool, animated: Bool) {
        fatalError("Override")
    }

    func show(toDelete: Bool, animated: Bool) {
        fatalError("Override")
    }
}

// TODO "measure" also in this name
class DefaultCollectionViewItemManager<T: DBSyncable & WithUniqueName> {

    var view: UIView {
        return myCollectionView
    }

    var units: AnyRealmCollection<T>? {
        return dataSource?.items
    }

    //    var inputs: SelectIngredientDataControllerInputs = SelectIngredientDataControllerInputs()
    fileprivate(set) var myCollectionView: UICollectionView!
    //    weak var unitDelegate: SelectUnitControllerDelegate?
    fileprivate(set) var dataSource: UnitOrBaseDataSource<T>?
    fileprivate var itemsDelegate: CollectionViewDelegate? // arc
    fileprivate var itemNames: [String] = [] // we need this because we can't touch the Realm Units in the autocompletions thread (get diff. thread exception). So we have to map to Strings in advance.
    fileprivate var currentNewUnitInput: String?

    fileprivate(set) weak var controller: UIViewController?

    var onSelectItem: ((T?) -> Void)?
    fileprivate var selectedItem: (() -> T?)?
    var onMarkedItemToDelete: ((String?) -> Void)?
    var itemMarkedToDelete: (() -> String?)? // returns name (assumed to be unique)
    var willDeleteItem: ((T) -> Void)?

    let rowsSpacing: CGFloat = 4
    let topCollectionViewPadding: CGFloat = 20
    let bottomCollectionViewPadding: CGFloat = 20
    let leftRightCollectionViewPadding: CGFloat = 30

    var collectionViewContentsHeight: CGFloat {
        fatalError("Override")
    }

    func sizeFotItemCell(indexPath: IndexPath) -> CGSize {
        fatalError("Override")
    }

    func calculateCollectionViewContentsHeight(collectionViewWidth: CGFloat, items: AnyRealmCollection<T>) -> CGFloat {
        fatalError("Override")
    }

    init() {
//        let flowLayout = UICollectionViewFlowLayout()
        let flowLayout = LeftAlignedCollectionViewFlowLayout()
        flowLayout.sectionInset = UIEdgeInsetsMake(topCollectionViewPadding, leftRightCollectionViewPadding, bottomCollectionViewPadding, leftRightCollectionViewPadding)
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.minimumLineSpacing = rowsSpacing

        myCollectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: flowLayout)

        myCollectionView.bounces = false
        myCollectionView.backgroundColor = UIColor.clear
    }

    func collectionViewContentHeight() -> CGFloat {
        guard let items = dataSource?.items else { logger.d("No items (yet?), returning 0 contents height"); return 0 }
        return calculateCollectionViewContentsHeight(collectionViewWidth: collectionView.width, items: items)
    }

    func configure(controller: UIViewController, onSelectItem: @escaping ((T?) -> Void)) {

        self.controller = controller
        self.onSelectItem = onSelectItem

        // TODO# ? remove todo after test? seems to be done already
        let delegate = CollectionViewDelegate(delegate: self)
        myCollectionView.delegate = delegate
        itemsDelegate = delegate

        registerCell()

        fetchItems(controller: controller) { items in
            let dataSource = self.createDataSource(items: items)
            dataSource.delegate = self
            self.myCollectionView.dataSource = dataSource
            self.dataSource = dataSource

            self.itemNames = items.map{ $0.uniqueName } // see comment on var why this is necessary

            self.myCollectionView.reloadData()
        }
    }

    func registerCell() {
        myCollectionView.register(UINib(nibName: "UnitCell", bundle: nil), forCellWithReuseIdentifier: "unitCell")
    }

    func createDataSource(items: AnyRealmCollection<T>) -> UnitOrBaseDataSource<T> {
        fatalError("Override")
    }

    func fetchItems(controller: UIViewController, onSucces: @escaping (AnyRealmCollection<T>) -> Void) {
        fatalError("Override")
    }
}


extension DefaultCollectionViewItemManager: UnitOrBaseDataSourceDelegate {

    // MARK: - UnitsCollectionViewDataSourceDelegate

    var currentItemName: String {
        return selectedItem?()?.uniqueName ?? ""
    }

    var itemToDeleteName: String {
        return itemMarkedToDelete?() ?? ""
    }

    func onUpdateItemNameInput(nameInput: String) {
        currentNewUnitInput = nameInput
    }


    internal var minItemTextFieldWidth: CGFloat {
        return 70
    }

    var highlightSelected: Bool {
        return true
    }

    func onMarkUnitToDelete(uniqueName: String) {
        onMarkedItemToDelete?(uniqueName)
    }

    var collectionView: UICollectionView {
        return myCollectionView
    }

    fileprivate func onSelect(item: T) {
        onSelectItem?(item)

        //        inputs.unitName = unit.name
        //
        //        updateInputsAndTitle()
        //
        //        unitDelegate?.onSelectUnit(unit: unit)
    }

    fileprivate func isSelected(cell: DefaultItemMeasureCell) -> Bool {
        let selectedUnitName: String? = selectedItem?()?.uniqueName
        return selectedUnitName.map { $0 == cell.itemName } ?? false
    }

    func clearSelectedItems() {
        let cells = myCollectionView.visibleCells as! [DefaultItemMeasureCell]
        for cell in cells {
            cell.show(selected: false, animated: true)
        }
    }

    func clearToDeleteItems() {
        let cells = myCollectionView.visibleCells as! [DefaultItemMeasureCell]
        for cell in cells {
            cell.show(toDelete: false, animated: true)
        }
    }

    fileprivate func updateTitle(inputs: SelectIngredientDataControllerInputs) {
    }

    func markUnitToDelete(unit: Providers.Unit) {
        let cells = myCollectionView.visibleCells as! [DefaultItemMeasureCell]
        for cell in cells {
            if cell.itemName == unit.name {
                cell.show(toDelete: true, animated: true)
                break
            }
        }
    }
}

// MARK: - UnitsCollectionViewDelegateDelegate

extension DefaultCollectionViewItemManager: CollectionViewDelegateDelegate {

    // sizeFotItemCell implemented in main class to be able to override in subclasses
    
    func didSelectItem(indexPath: IndexPath) {
        guard let controller = controller else { logger.e("No controller!"); return }

        guard let dataSource = myCollectionView.dataSource else {logger.e("No data source"); return}
        guard let unitsOrBaseDataSource = dataSource as? UnitOrBaseDataSource<T> else {
            logger.e("Data source has wrong type: \(type(of: dataSource))"); return}
        guard let items = unitsOrBaseDataSource.items else {logger.e("Invalid state: Data source has no units"); return}
        guard let unitMarkedToDelete = itemMarkedToDelete else {logger.e("Invalid state: Data source has no units"); return}

        let selectedItem = items[indexPath.row]

        let cellMaybe = myCollectionView.cellForItem(at: indexPath) as? DefaultItemMeasureCell

        if unitMarkedToDelete() == selectedItem.uniqueName {

            let item = items[indexPath.row]
            willDeleteItem?(item)
            Prov.unitProvider.delete(name: item.uniqueName, controller.successHandler {[weak self] in
                self?.myCollectionView.deleteItems(at: [indexPath])
                self?.myCollectionView?.collectionViewLayout.invalidateLayout() // seems to fix weird space appearing before last cell (input cell) sometimes

                logger.w("Results count after delete: \(String(describing: self?.units?.count))", .wildcard)
            })

        } else {
            clearToDeleteItems()
            clearSelectedItems()

            if let cell = cellMaybe {
                if isSelected(cell: cell) {
                    cellMaybe?.show(selected: false, animated: true)
                    //                    inputs.unitName = ""
                    //                    updateTitle(inputs: inputs)
                } else {
                    cellMaybe?.show(selected: true, animated: true)
                    onSelect(item: items[indexPath.row])
                }
            }
        }
    }
}

// Our class can't implement directly the collection view delegates because it has a generic parameter (Swift...) so we use an intermediary
protocol CollectionViewDelegateDelegate: class {
    func sizeFotItemCell(indexPath: IndexPath) -> CGSize
    func didSelectItem(indexPath: IndexPath)
}

class CollectionViewDelegate: NSObject, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    fileprivate weak var delegate: CollectionViewDelegateDelegate?

    init(delegate: CollectionViewDelegateDelegate) {
        self.delegate = delegate
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.didSelectItem(indexPath: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return delegate?.sizeFotItemCell(indexPath: indexPath) ?? CGSize.zero
    }
}
