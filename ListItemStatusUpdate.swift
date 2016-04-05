//
//  ListItemStatusUpdate.swift
//  shoppin
//
//  Created by ischuetz on 05/04/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation

class ListItemStatusUpdate {

    let src: ListItemStatus
    let dst: ListItemStatus
    
    init(src: ListItemStatus, dst: ListItemStatus) {
        self.src = src
        self.dst = dst
    }
}