//
//  HeaderCellManager.swift
//  shoppin
//
//  Created by ischuetz on 03/04/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Cocoa

class HeaderCellManager: CellManager {
    
    let section: Section
    
    init(section: Section) {
        self.section = section
    }
    
    override func makeCell(tableView: NSTableView, tableColumn: NSTableColumn?, row: Int) -> NSTableCellView {
        let cell = HeaderCell() // TODO reuse
       
        cell.title = self.section.name
        
        return cell
    }
}
