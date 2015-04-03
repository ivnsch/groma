//
//  CellManager.swift
//  shoppin
//
//  Created by ischuetz on 03/04/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Cocoa

class CellManager {
  
    func makeCell(tableView: NSTableView, tableColumn: NSTableColumn?, row: Int) -> NSTableCellView {
        fatalError("must override")
    }
}
