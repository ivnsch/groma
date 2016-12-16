//
//  ListItemStatusUpdate.swift
//  shoppin
//
//  Created by ischuetz on 05/04/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation

public class ListItemStatusUpdate {

    public let src: ListItemStatus
    public let dst: ListItemStatus
    
    public init(src: ListItemStatus, dst: ListItemStatus) {
        self.src = src
        self.dst = dst
    }
}
