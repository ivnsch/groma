//
//  HeaderCellManager.swift
//  shoppin
//
//  Created by ischuetz on 03/04/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Cocoa

protocol HeaderCellManagerDelegate: class {
    func headerDeleteTapped(cell: HeaderCell, section: Section)
}

class HeaderCellManager: CellManager, HeaderCellDelegate {
    
    let section: Section
    
    weak var delegate: HeaderCellManagerDelegate?
    
    init(section: Section, delegate: HeaderCellManagerDelegate) {
        self.section = section
        self.delegate = delegate
    }
    
    override func makeCell(tableView: NSTableView, tableColumn: NSTableColumn?, row: Int) -> NSTableCellView {
        let cell = HeaderCell() // TODO reuse
       
        cell.title = self.section.name
        cell.delegate = self
        
        return cell
    }
    
    func headerDeleteTapped(cell: HeaderCell) {
        self.delegate?.headerDeleteTapped(cell, section: self.section)
    }
}
