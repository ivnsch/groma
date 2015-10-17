//
//  ListItemGroup.swift
//  shoppin
//
//  Created by ischuetz on 13/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

class ListItemGroup {

    let uuid: String
    let name: String
    var items: [GroupItem]
    
    init(uuid: String, name: String, items: [GroupItem] = []) {
        self.uuid = uuid
        self.name = name
        self.items = items
    }
}
