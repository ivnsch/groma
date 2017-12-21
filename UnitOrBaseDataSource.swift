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

protocol UnitOrBaseDataSourceDelegate {
    var currentItemName: String {get}
    var itemToDeleteName: String { get }
    func onUpdateItemNameInput(nameInput: String)
    var minItemTextFieldWidth: CGFloat {get}
    var highlightSelected: Bool {get}
    func onMarkUnitToDelete(uniqueName: String)
    var collectionView: UICollectionView { get }
}

class UnitOrBaseDataSource<T: DBSyncable & WithUniqueName>: NSObject, UICollectionViewDataSource, UnitCellDelegate, UnitEditableViewDelegate, UICollectionViewDelegateFlowLayout {
    
    var items: Results<T>?
    
    var delegate: UnitOrBaseDataSourceDelegate?
    
    fileprivate var addNewUnitCell: UnitEditableCell? // to ask if it has focus
    
    init(items: Results<T>?) {
        self.items = items
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //        return units.map{$0.count + 1} ?? 0 // no input in collection view anymore
        return items.map{$0.count} ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        fatalError("Override")
    }
    
    
    // MARK: - UnitCellDelegate
    
    func onLongPress(cell: UnitCell) {
        guard let delegate = delegate else { logger.e("No delegate"); return }
        guard let indexPath = delegate.collectionView.indexPath(for: cell) else {
            logger.e("Couldn't find cell!", .ui)
            return
        }
        guard let items = items else { logger.e("No units"); return }
        let item = items[indexPath.row]
        delegate.onMarkUnitToDelete(uniqueName: item.uniqueName)
        //        cell.unitView.markedToDelete = true
        cell.unitView.mark(toDelete: true, animated: true)
    }
    
    
    // MARK: - EditableUnitCellDelegate
    
    func onUnitInputChange(nameInput: String) {
        delegate?.onUpdateItemNameInput(nameInput: nameInput)
    }
    
    // MARK: -
    
    // TODO maybe do "focusFrame" or something instead. We need the actual possition. Currently we make assumptions about it
    var hasUnitInputFocus: Bool {
        return addNewUnitCell?.hasFocus ?? false
    }
}


