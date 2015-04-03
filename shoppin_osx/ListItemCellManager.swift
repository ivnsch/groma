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
    
    let listItemRow: ListItemRow
   
    weak var delegate: ListItemCellManagerDelegate?
    
    init(listItem: ListItem, delegate: ListItemCellManagerDelegate) {
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
}
