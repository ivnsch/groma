//
//  ListItemGroup.swift
//  shoppin
//
//  Created by ischuetz on 13/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

class ListItemGroup: Identifiable, Equatable {

    let uuid: String
    let name: String
    let bgColor: UIColor
    var order: Int
    var fav: Int
    
    //////////////////////////////////////////////
    // sync properties - FIXME - while Realm allows to return Realm objects from async op. This shouldn't be in model objects.
    // the idea is that we can return the db objs from query and then do sync directly with these objs so no need to put sync attributes in model objs
    // we could map the db objects to other db objs in order to work around the Realm issue, but this adds even more overhead, we make a lot of mappings already
    let lastServerUpdate: NSDate?
    let removed: Bool
    //////////////////////////////////////////////
    
    init(uuid: String, name: String, bgColor: UIColor, order: Int, fav: Int = 0, lastServerUpdate: NSDate? = nil, removed: Bool = false) {
        self.uuid = uuid
        self.name = name
        self.bgColor = bgColor
        self.order = order
        self.fav = fav
        self.lastServerUpdate = lastServerUpdate
        self.removed = removed
    }
    
    func copy(uuid uuid: String? = nil, name: String? = nil, bgColor: UIColor? = nil, order: Int? = nil, fav: Int? = nil, lastServerUpdate: NSDate? = nil, removed: Bool? = nil) -> ListItemGroup {
        return ListItemGroup(
            uuid: uuid ?? self.uuid,
            name: name ?? self.name,
            bgColor: bgColor ?? self.bgColor,
            order: order ?? self.order,
            fav: fav ?? self.fav,
            lastServerUpdate: lastServerUpdate ?? self.lastServerUpdate,
            removed: removed ?? self.removed
        )
    }
    
    func same(rhs: ListItemGroup) -> Bool {
        return uuid == rhs.uuid
    }

    var shortDebugDescription: String {
        return "{uuid: \(uuid), name: \(name), order: \(order)}"
    }

    var debugDescription: String {
        return "{\(self.dynamicType) uuid: \(uuid), name: \(name), bgColor: \(bgColor.hexStr), order: \(order), fav: \(fav), removed: \(removed), lastServerUpdate: \(lastServerUpdate), removed: \(removed)}"
    }
}

func ==(lhs: ListItemGroup, rhs: ListItemGroup) -> Bool {
    return lhs.uuid == rhs.uuid && lhs.name == rhs.name && lhs.bgColor.hexStr == rhs.bgColor.hexStr && lhs.order == rhs.order && lhs.fav == rhs.fav
}