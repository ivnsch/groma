//
//  OrderUpdate.swift
//  shoppin
//
//  Created by ischuetz on 18/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation

struct OrderUpdate {
    let uuid: String
    let order: Int
    
    init(uuid: String, order: Int) {
        self.uuid = uuid
        self.order = order
    }
}
