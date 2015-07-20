//
//  UITableView.swift
//  shoppin
//
//  Created by ischuetz on 01/04/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit

extension UITableView {
   
    func absoluteRow(indexPath: NSIndexPath) -> Int {
        var absRow = indexPath.row
        for section in 0..<indexPath.section {
            absRow += self.numberOfRowsInSection(section)
        }
        return absRow
    }
    
    func wrapUpdates(function: () -> ()) {
        self.beginUpdates()
        function()
        self.endUpdates()
    }
}
