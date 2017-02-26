//
//  TableViewHitTest.swift
//  shoppin
//
//  Created by Ivan Schuetz on 26/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit

class TableViewHitTest: UITableView {

    var onHit: ((Bool) -> Void)? // true: inside (in a cell), false: outside (not in a cell)
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let isInCell = indexPathForRow(at: point) != nil
        
        onHit?(isInCell)

        if isInCell {
            return super.hitTest(point, with: event)
        } else {
            return nil
        }
    }
    

}
