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
    
    var section: Section!
    
    weak var delegate: HeaderCellManagerDelegate?
   
    required convenience init(section: Section, delegate: HeaderCellManagerDelegate) {
        self.init()
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
    
    override func overridableEquals(other: CellManager) -> Bool {
        if let otherHeaderCellManager = other as? HeaderCellManager {
            return self.section == otherHeaderCellManager.section
        }
        return super.overridableEquals(other)
    }
    
    // MARK: - NSCoding
    // required for drag & drop
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    required init() {
        super.init()
    }
    
    override func encodeWithCoder(aCoder: NSCoder) {
    }
}
