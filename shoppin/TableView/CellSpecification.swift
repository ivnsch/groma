//
//  CellSpecification.swift
//  TrainerApp
//
//  Created by Ivan Schuetz on 08/12/14.
//  Copyright (c) 2014 eGym. All rights reserved.
//

import UIKit

class CellSpecification<T> {
    
    let modelObject:T
    
    let cellIdentifier:String
    let cellHeight:Float
    
    init(cellIdentifier:String, cellHeight:Float, modelObject:T) {
        self.cellIdentifier = cellIdentifier
        self.cellHeight = cellHeight
        self.modelObject = modelObject
    }
    
    func generateCellForTableView(tableView:UITableView) -> UITableViewCell {
        return tableView.dequeueReusableCellWithIdentifier(self.cellIdentifier) as! UITableViewCell
    }
}