//
//  GroupItemWithGroup.swift
//  shoppin
//
//  Created by ischuetz on 11/12/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

final class GroupItemWithGroup {
    let groupItem: GroupItem
    let group: ProductGroup
    init (groupItem: GroupItem, group: ProductGroup) {
        self.groupItem = groupItem
        self.group = group
    }
}
