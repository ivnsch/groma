//
//  CellManager.swift
//  shoppin
//
//  Created by ischuetz on 03/04/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Cocoa

@objc // required for NSCoding
class CellManager: NSObject, NSCoding, Equatable {
    
    required override init() {
        super.init()
    }
    
    func makeCell(tableView: NSTableView, tableColumn: NSTableColumn?, row: Int) -> NSTableCellView {
        fatalError("must override")
    }
   
    // MARK: - NSCoding
    
    required init(coder aDecoder: NSCoder) {
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
    }
    
    func overridableEquals(other: CellManager) -> Bool {
        fatalError("must override")
    }
}

func ==(lhs: CellManager, rhs: CellManager) -> Bool {
    return lhs.overridableEquals(rhs)
}
