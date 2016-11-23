//
//  TableViewSectionDelegate.swift
//  TrainerApp
//
//  Created by Ivan Schuetz on 09/12/14.
//  Copyright (c) 2014 eGym. All rights reserved.
//

import UIKit

protocol TableViewSectionDelegate {
    func cellReuseIdentifierForRow(_ row:Int) -> String
    
    //CQA: dynamic solution to get the cells to register for tableView.registerClass, so we don't have to remember
    //to register cells forehand. Use CellSpecification for this
//    func cellsToRegister() -> NSSet
    
    func heightForRow(_ row: Int) -> Float
    
    func heightForHeader() -> Float
    
    func heightForFooter() -> Float
    
    func viewForHeader() -> UIView?
    
    func viewForFooter() -> UIView?
    
    func tableView(_ tableView:UITableView, cellForRow:NSInteger) -> UITableViewCell
    
    func numberOfRows() -> Int
}
