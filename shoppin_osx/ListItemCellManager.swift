//
//  ListItemCellManager.swift
//  shoppin
//
//  Created by ischuetz on 03/04/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Cocoa

protocol ListItemCellManagerDelegate: class {
    func rowAddTapped(cell: NSTableCellView, listItemRow: ListItemRow)
    func rowDeleteTapped(cell: NSTableCellView, listItemRow: ListItemRow)
    func rowUpTapped(cell: NSTableCellView, listItemRow: ListItemRow)
    func rowDownTapped(cell: NSTableCellView, listItemRow: ListItemRow)
    func rowEditTapped(cell: NSTableCellView, listItemRow: ListItemRow)
}

class ListItemCellManager: CellManager, ListItemCellDelegate {
    
    var listItemRow: ListItemRow!
   
    weak var delegate: ListItemCellManagerDelegate?
   
    required convenience init(listItem: ListItem, delegate: ListItemCellManagerDelegate) {
        self.init()
        self.listItemRow = ListItemRow(listItem)
        self.delegate = delegate
    }
    
    override func makeCell(tableView: NSTableView, tableColumn: NSTableColumn?, row: Int) -> NSTableCellView {
        let cell = tableView.makeViewWithIdentifier("listItem", owner:self) as! ListItemCell
        
        cell.delegate = self
        cell.listItemRow = self.listItemRow
        
        return cell
    }
    
    func rowAddTapped(rowIndex: NSTableCellView, listItemRow: ListItemRow) {
        self.delegate?.rowAddTapped(rowIndex, listItemRow: listItemRow)
    }
    
    func rowDeleteTapped(rowIndex: NSTableCellView, listItemRow: ListItemRow) {
        self.delegate?.rowDeleteTapped(rowIndex, listItemRow: listItemRow)
    }
    
    func rowUpTapped(rowIndex: NSTableCellView, listItemRow: ListItemRow) {
        self.delegate?.rowUpTapped(rowIndex, listItemRow: listItemRow)
    }

    func rowDownTapped(rowIndex: NSTableCellView, listItemRow: ListItemRow) {
        self.delegate?.rowDownTapped(rowIndex, listItemRow: listItemRow)
    }
    
    func rowEditTapped(rowIndex: NSTableCellView, listItemRow: ListItemRow) {
        self.delegate?.rowEditTapped(rowIndex, listItemRow: listItemRow)
    }
    
    override func overridableEquals(other: CellManager) -> Bool {
        if let otherListItemCellManager = other as? ListItemCellManager {
            return self.listItemRow.listItem == otherListItemCellManager.listItemRow.listItem
        }
        return super.overridableEquals(other)
    }
    
    // MARK: - NSCoding
    
    // maybe we can add later a more sofisticated way to serialise, if more use cases
    // a rather simple solution would be to serialise just the list item id and let the decoder fetch the object from core data - less code and less error prone
    // but maybe not good for performance? async while dropping possible?
    
    private let productIdKey = "productId"
    private let productNameKey = "productName"
    private let productPriceKey = "productPrice"
    private let listIdKey = "listId"
    private let listNameKey = "listName"
    private let sectionNameKey = "sectionName"
    private let listItemQuantityKey = "listItemQuantity"
    private let listItemOrderKey = "listItemOrder"
    private let listItemIdKey = "listItemId"
    private let listItemDoneKey = "listItemDone"
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
       
        if aDecoder.containsValueForKey(listIdKey) {
            let listId = aDecoder.decodeObjectForKey(listIdKey) as! String
            let listName = aDecoder.decodeObjectForKey(listNameKey) as! String
            let list = List(id: listId, name: listName, listItems: [])
            
            let productId = aDecoder.decodeObjectForKey(productIdKey) as! String
            let productName = aDecoder.decodeObjectForKey(productNameKey) as! String
            let productPrice = aDecoder.decodeFloatForKey(productPriceKey)
            let product = Product(id: productId, name: productName, price: productPrice)
            
            let sectionName = aDecoder.decodeObjectForKey(sectionNameKey) as! String
            let section = Section(name: sectionName)
            
            let listItemId = aDecoder.decodeObjectForKey(listItemIdKey) as! String
            let listItemQuantity = aDecoder.decodeIntegerForKey(listItemQuantityKey)
            let listItemOrder = aDecoder.decodeIntegerForKey(listItemOrderKey)
            let listItemDone = aDecoder.decodeBoolForKey(listItemDoneKey)
            let listItem = ListItem(id: listItemId, done: listItemDone, quantity: listItemQuantity, product: product, section: section, list: list, order: listItemOrder)
            
            self.listItemRow = ListItemRow(listItem)
        }
    }

    required init() {
        super.init()
    }
    
    override func encodeWithCoder(aCoder: NSCoder) {
        
        let listItem = self.listItemRow.listItem
        
        aCoder.encodeObject(listItem.list.id, forKey: listIdKey)
        aCoder.encodeObject(listItem.list.name, forKey: listNameKey)
        
        aCoder.encodeObject(listItem.product.id, forKey: productIdKey)
        aCoder.encodeObject(listItem.product.name, forKey: productNameKey)
        aCoder.encodeFloat(listItem.product.price, forKey: productPriceKey)

        aCoder.encodeObject(listItem.section.name, forKey: sectionNameKey)
        
        aCoder.encodeInteger(listItem.quantity, forKey: listItemQuantityKey)
        aCoder.encodeInteger(listItem.order, forKey: listItemOrderKey)
        aCoder.encodeObject(listItem.id, forKey: listItemIdKey)
        aCoder.encodeBool(listItem.done, forKey: listItemDoneKey)
    }
}