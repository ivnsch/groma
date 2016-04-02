//
//  Section.swift
//  shoppin
//
//  Created by ischuetz on 23.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import Foundation

final class Section: Hashable, Identifiable, CustomDebugStringConvertible {
    let uuid: String
    let name: String
//    let order: Int
    let color: UIColor
    var list: List

    var todoOrder: Int
    var doneOrder: Int
    var stashOrder: Int
    
    // TODO! list reference - a section belongs to a list
    
    //////////////////////////////////////////////
    // sync properties - FIXME - while Realm allows to return Realm objects from async op. This shouldn't be in model objects.
    // the idea is that we can return the db objs from query and then do sync directly with these objs so no need to put sync attributes in model objs
    // we could map the db objects to other db objs in order to work around the Realm issue, but this adds even more overhead, we make a lot of mappings already
    let lastUpdate: NSDate
    let lastServerUpdate: NSDate?
    let removed: Bool
    //////////////////////////////////////////////
    
    init(uuid: String, name: String, color: UIColor, list: List, todoOrder: Int, doneOrder: Int, stashOrder: Int, lastUpdate: NSDate = NSDate(), lastServerUpdate: NSDate? = nil, removed: Bool = false) {
        self.uuid = uuid
        self.name = name
        self.color = color
        self.list = list

        self.todoOrder = todoOrder
        self.doneOrder = doneOrder
        self.stashOrder = stashOrder
        
        self.lastUpdate = lastUpdate
        self.lastServerUpdate = lastServerUpdate
        self.removed = removed
    }
    
    convenience init(uuid: String, name: String, color: UIColor, list: List, order: ListItemStatusOrder, lastUpdate: NSDate = NSDate(), lastServerUpdate: NSDate? = nil, removed: Bool = false) {
        let (todoOrder, doneOrder, stashOrder): (Int, Int, Int) = {
            switch(order.status) {
            case .Todo: return (order.order, 0, 0)
            case .Done: return (0, order.order, 0)
            case .Stash: return (0, 0, order.order)
            }
        }()
        self.init(uuid: uuid, name: name, color: color, list: list, todoOrder: todoOrder, doneOrder: doneOrder, stashOrder: stashOrder, lastUpdate: lastUpdate, lastServerUpdate: lastServerUpdate, removed: removed)
    }
    
    var hashValue: Int {
        return uuid.hashValue
    }
    
    var shortOrderDebugDescription: String {
        return "[\(name)], todo: \(todoOrder), done: \(doneOrder), stash: \(stashOrder)"
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) uuid: \(uuid), name: \(name), color: \(color), listUuid: \(list), todoOrder: \(todoOrder), doneOrder: \(doneOrder), stashOrder: \(stashOrder), lastUpdate: \(lastUpdate), lastServerUpdate: \(lastServerUpdate), removed: \(removed)}}"
    }
    
    func copy(uuid uuid: String? = nil, name: String? = nil, color: UIColor? = nil, list: List? = nil, todoOrder: Int? = nil, doneOrder: Int? = nil, stashOrder: Int? = nil, lastUpdate: NSDate? = nil, lastServerUpdate: NSDate? = nil, removed: Bool? = nil) -> Section {
        return Section(
            uuid: uuid ?? self.uuid,
            name: name ?? self.name,
            color: color ?? self.color,
            list: list ?? self.list,
            
            todoOrder: todoOrder ?? self.todoOrder,
            doneOrder: doneOrder ?? self.doneOrder,
            stashOrder: stashOrder ?? self.stashOrder,
            
            lastUpdate: lastUpdate ?? self.lastUpdate,
            lastServerUpdate: lastServerUpdate ?? self.lastServerUpdate,
            removed: removed ?? self.removed
        )
    }
    
    func same(section: Section) -> Bool {
        return section.uuid == self.uuid
    }
    
    func order(status: ListItemStatus) -> Int {
        switch status {
        case .Todo: return todoOrder
        case .Done: return doneOrder
        case .Stash: return stashOrder
        }
    }
    
    func updateOrderMutable(order: ListItemStatusOrder) {
        switch order.status {
        case .Todo: todoOrder = order.order
        case .Done: doneOrder = order.order
        case .Stash: stashOrder = order.order
        }
    }
}

func ==(lhs: Section, rhs: Section) -> Bool {
    return lhs.uuid == rhs.uuid && lhs.name == rhs.name && lhs.color == rhs.color && lhs.list.uuid == rhs.list.uuid
}
