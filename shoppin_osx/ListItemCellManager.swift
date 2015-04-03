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

class ListItemCellManager: CellManager, EditListItemButtonsCellDelegate {
    
    let listItemRow: ListItemRow
   
    weak var delegate: ListItemCellManagerDelegate?
    
    init(listItem: ListItem, delegate: ListItemCellManagerDelegate) {
        self.listItemRow = ListItemRow(listItem)
        
        self.delegate = delegate
    }

    private func makeButtonsCell(columnIdentifier: ListItemColumnIdentifier, tableView: NSTableView, row: Int) -> EditListItemButtonsCell {
        
        let cell = tableView.makeViewWithIdentifier(columnIdentifier.rawValue, owner:self) as! EditListItemButtonsCell
        
        cell.listItemRow = self.listItemRow
        cell.delegate = self
        
        return cell
    }
    
    private func makeDefaultCell(columnIdentifier: ListItemColumnIdentifier, tableView: NSTableView, row: Int) -> NSTableCellView {
        
        let cell = tableView.makeViewWithIdentifier(columnIdentifier.rawValue, owner:self) as! NSTableCellView
        
        if let columnString = self.listItemRow.getColumnString(columnIdentifier) {
            cell.textField?.stringValue = columnString
        }
        
        return cell
    }
    
    override func makeCell(tableView: NSTableView, tableColumn: NSTableColumn?, row: Int) -> NSTableCellView {
        
        let columnIdentifier = ListItemColumnIdentifier(rawValue: tableColumn!.identifier)!
        
        switch columnIdentifier {
        case .Edit:
            return self.makeButtonsCell(columnIdentifier, tableView: tableView, row: row)
        default:
            return self.makeDefaultCell(columnIdentifier, tableView: tableView, row: row)
        }
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
