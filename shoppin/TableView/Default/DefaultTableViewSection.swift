//
//  PremiumInactiveTableViewSection.swift
//  TrainerApp
//
//  Created by Ivan Schuetz on 09/12/14.
//  Copyright (c) 2014 eGym. All rights reserved.
//

import UIKit

class DefaultTableViewSection: NSObject, TableViewSectionDelegate {
    
    func heightForHeader() -> Float {
        return 0
    }
    
    func heightForFooter() -> Float {
        return 0
    }
    
    func cellReuseIdentifierForRow(_ row:Int) -> String {
        fatalError("This method must be overridden")
    }
    
    func viewForHeader() -> UIView? {
        return nil
    }
    
    func viewForFooter() -> UIView? {
        return nil
    }
    
    func heightForRow(_ row: Int) -> Float {
        return 0
    }
    
//    func cellsToRegister() -> NSSet {
//        return NSSet()
//    }
    
    func tableView(_ tableView: UITableView, cellForRow: NSInteger) -> UITableViewCell {
        fatalError("This method must be overridden")
    }
    
    func numberOfRows() -> Int {
        return 0
    }
    
    func numberOfSectionsInTableView(_ tableView: UITableView) -> Int {
        return 0
    }
    
    func dividerViewWithTitle(_ title:String) -> UIView? {
        return nil
    }
}
