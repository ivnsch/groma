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

    //    var inputs: SelectIngredientDataControllerInputs = SelectIngredientDataControllerInputs()
    fileprivate(set) var myCollectionView: UICollectionView!
    //    weak var unitDelegate: SelectUnitControllerDelegate?
    fileprivate(set) var dataSource: UnitOrBaseDataSource<T>?
    fileprivate var itemsDelegate: CollectionViewDelegate? // arc
    fileprivate var itemNames: [String] = [] // we need this because we can't touch the Realm Units in the autocompletions thread (get diff. thread exception). So we have to map to Strings in advance.
    fileprivate var currentNewUnitInput: String?

    fileprivate(set) weak var controller: UIViewController?

    fileprivate var onSelectItem: ((T?) -> Void)?
    var selectedItem: (() -> String?)?
    var onMarkedItemToDelete: ((String?) -> Void)?
    var itemMarkedToDelete: (() -> String?)? // returns name (assumed to be unique)
    var willDeleteItem: ((T) -> Void)?
    var clearToDeleteItemsState: (() -> Void)? // Used by popup on cancel
    var onFetchedData: (() -> Void)?
    var fetchFunc: (() -> AnyRealmCollection<T>?)?
    var reloadContainerData: (() -> Void)?

    let rowsSpacing: CGFloat = 4
    let topCollectionViewPadding: CGFloat = 20
    let bottomCollectionViewPadding: CGFloat = 20
    let leftRightCollectionViewPadding: CGFloat = 30

    fileprivate var canDeselect: Bool = false // if it's allowed to de-select items (with this we can enforce that there's always an item selected)

    var notificationToken: NotificationToken? // Exposed for subclasses

    func sizeFotItemCell(indexPath: IndexPath) -> CGSize {
        fatalError("Override")
    }

    func calculateCollectionViewContentsHeight(collectionViewWidth: CGFloat, items: AnyRealmCollection<T>) -> CGFloat {
        fatalError("Override")
    }

    init() {
//        let flowLayout = UICollectionViewFlowLayout()
        let flowLayout = LeftAlignedCollectionViewFlowLayout()
        flowLayout.sectionInset = UIEdgeInsets.init(top: topCollectionViewPadding, left: leftRightCollectionViewPadding, bottom: bottomCollectionViewPadding, right: leftRightCollectionViewPadding)
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.minimumLineSpacing = rowsSpacing

        myCollectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: flowLayout)

        myCollectionView.bounces = false
        myCollectionView.backgroundColor = UIColor.clear

        myCollectionView.isScrollEnabled = false
    }

    func collectionViewContentHeight() -> CGFloat {
        guard let items = dataSource?.items else { logger.d("No items (yet?), returning 0 contents height"); return 0 }
        return calculateCollectionViewContentsHeight(collectionViewWidth: collectionView.width, items: items)
    }

    func configure(controller: UIViewController, canDeselect: Bool, onSelectItem: @escaping ((T?) -> Void)) {

        self.controller = controller
        self.canDeselect = canDeselect
        self.onSelectItem = onSelectItem

        // TODO# ? remove todo after test? seems to be done already
        let delegate = CollectionViewDelegate(delegate: self)
        myCollectionView.delegate = delegate
        itemsDelegate = delegate

        registerCell()
    }

    func loadItems() {
        guard let controller = controller else { logger.e("No controller", .ui); return }

        func onHasItems(items: AnyRealmCollection<T>) {
            let dataSource = self.createDataSource(items: items)
            dataSource.delegate = self
            self.myCollectionView.dataSource = dataSource
            self.dataSource = dataSource

            self.itemNames = items.map{ $0.uniqueName } // see comment on var why this is necessary

            self.myCollectionView.reloadData()

            self.onFetchedData?()
        }

        if let fetchFunc = self.fetchFunc {
            if let items = fetchFunc() {
                onHasItems(items: items)
            } else {
                logger.i("Fetch function didn't return items - maybe not available yet", .ui)
            }
        } else {
            fetchItems(controller: controller) { items in
                onHasItems(items: items)
            }
        }
    }

    /////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////
    // TODO refactor these - code is the same but one has Results as parameter the other RealmSwift.List

    func observeResults(_ items: Results<T>) {
        notificationToken = items.observe({ [weak self] changes in
            switch changes {
            case .initial: break
            case .update(_, let deletions, let insertions, let modifications):
                logger.d("Bases notification, deletions: \(deletions), let insertions: \(insertions), let modifications: \(modifications)")

                self?.update(insertions: insertions, deletions: deletions, modifications: modifications)

            case .error(let error):
                // An error occurred while opening the Realm file on the background worker thread
                fatalError(String(describing: error))
            }
        })
    }

    func observeList(_ items: RealmSwift.List<T>) {
        notificationToken = items.observe({ [weak self] changes in
            switch changes {
            case .initial: break
            case .update(_, let deletions, let insertions, let modifications):
                logger.d("Bases notification, deletions: \(deletions), let insertions: \(insertions), let modifications: \(modifications)")

                self?.update(insertions: insertions, deletions: deletions, modifications: modifications)

            case .error(let error):
                // An error occurred while opening the Realm file on the background worker thread
                fatalError(String(describing: error))
            }
        })
    }

    /////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////

    // Realm notifications entry point
    func update(insertions: [Int], deletions: [Int], modifications: [Int]) {
        myCollectionView.performBatchUpdates({
            myCollectionView.insertItems(at: insertions.map { IndexPath(row: $0, section: 0) })
            myCollectionView.deleteItems(at: deletions.map { IndexPath(row: $0, section: 0) })
            myCollectionView.reloadItems(at: modifications.map { IndexPath(row: $0, section: 0) })
        }) { _ in }
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

    func delete(item: T, controller: UIViewController, onFinish: @escaping () -> Void) {
        fatalError("Override")
    }

    func reload() {
        collectionView.reloadData()
    }

    func confirmRemoveItemPopupMessage(item: T) -> String {
        fatalError("Override")
    }

    func allowRemoveItem(item: T, controller: UIViewController) -> Bool {
        // Optional override
        return true
    }
}


extension DefaultCollectionViewItemManager: UnitOrBaseDataSourceDelegate {

    // MARK: - UnitsCollectionViewDataSourceDelegate

    var currentItemName: String {
        return selectedItem?() ?? ""
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
        clearToDeleteItems()
        onMarkedItemToDelete?(uniqueName)
    }

    var collectionView: UICollectionView {
        return myCollectionView
    }

    fileprivate func onSelect(item: T?) {
        onSelectItem?(item)

        //        inputs.unitName = unit.name
        //
        //        updateInputsAndTitle()
        //
        //        unitDelegate?.onSelectUnit(unit: unit)
    }

    fileprivate func isSelected(cell: DefaultItemMeasureCell) -> Bool {
        let selectedItemName: String? = selectedItem?()
        return selectedItemName.map { $0 == cell.itemName } ?? false
    }

    func clearSelectedItems() {
        let cells = myCollectionView.visibleCells as! [DefaultItemMeasureCell]
        for cell in cells {
            cell.show(selected: false, animated: true)
        }
    }

    func clearToDeleteItems() {
        clearToDeleteItemsState?()
        let cells = myCollectionView.visibleCells as! [DefaultItemMeasureCell]
        for cell in cells {
            cell.show(toDelete: false, animated: true)
        }
    }

    fileprivate func updateTitle(inputs: SelectIngredientDataControllerInputs) {
    }

    func markUnitToDelete(unit: Providers.Unit) {
        clearToDeleteItems()

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

        guard let dataSource = myCollectionView.dataSource else {logger.e("No data source"); return }
        guard let unitsOrBaseDataSource = dataSource as? UnitOrBaseDataSource<T> else {
            logger.e("Data source has wrong type: \(type(of: dataSource))"); return }
        guard let items = unitsOrBaseDataSource.items else {logger.e("Invalid state: Data source has no units"); return }
        guard let itemMarkedToDelete = itemMarkedToDelete else {logger.e("Invalid state: No item marked to delete function"); return }

        let selectedItem = items[indexPath.row]

        let cellMaybe = myCollectionView.cellForItem(at: indexPath) as? DefaultItemMeasureCell

        if itemMarkedToDelete() == selectedItem.uniqueName && allowRemoveItem(item: selectedItem, controller: controller) {

            controller.view.endEditing(true)

            MyPopupHelper.showPopup(parent: controller, type: .warning, message: confirmRemoveItemPopupMessage(item: selectedItem), onOk: { [weak self] in
                self?.willDeleteItem?(selectedItem)
                self?.delete(item: selectedItem, controller: controller, onFinish: { [weak self] in
                    self?.myCollectionView.deleteItems(at: [indexPath])
                    self?.myCollectionView.collectionViewLayout.invalidateLayout() // seems to fix weird space appearing before last cell (input cell) sometimes
                    // If we deleted the currently selected unit, the container changed the active to "none" - reload collection view to reflect this. Remember that there has to be always something selected - otherwise we need validation and we don't want this. Note: A delay less than 0.5 (or 0.2 at least, which I tried first) doesn't work!
                    delay(0.5) {
                        self?.myCollectionView.reloadData()
                    }
                })
            }, onCancel: { [weak self] in
                self?.clearToDeleteItems()
            })

        } else {

            if let cell = cellMaybe {
                if isSelected(cell: cell) {
                    if canDeselect {
                        clearToDeleteItems()
                        clearSelectedItems()

                        onSelect(item: nil)
                        cellMaybe?.show(selected: false, animated: true)
                        //                    inputs.unitName = ""
                        //                    updateTitle(inputs: inputs)
                    }
                } else {
                    clearToDeleteItems()
                    clearSelectedItems()

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
