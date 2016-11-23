//
//  Section.swift
//  shoppin
//
//  Created by ischuetz on 23.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import Foundation

final class Section: Identifiable, CustomDebugStringConvertible {
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
    let lastServerUpdate: Int64?
    let removed: Bool
    //////////////////////////////////////////////
    
    init(uuid: String, name: String, color: UIColor, list: List, todoOrder: Int, doneOrder: Int, stashOrder: Int, lastServerUpdate: Int64? = nil, removed: Bool = false) {
        self.uuid = uuid
        self.name = name
        self.color = color
        self.list = list

        self.todoOrder = todoOrder
        self.doneOrder = doneOrder
        self.stashOrder = stashOrder
        
        self.lastServerUpdate = lastServerUpdate
        self.removed = removed
    }
    
    convenience init(uuid: String, name: String, color: UIColor, list: List, order: ListItemStatusOrder, lastServerUpdate: Int64? = nil, removed: Bool = false) {
        let (todoOrder, doneOrder, stashOrder): (Int, Int, Int) = {
            switch(order.status) {
            case .todo: return (order.order, 0, 0)
            case .done: return (0, order.order, 0)
            case .stash: return (0, 0, order.order)
            }
        }()
        self.init(uuid: uuid, name: name, color: color, list: list, todoOrder: todoOrder, doneOrder: doneOrder, stashOrder: stashOrder, lastServerUpdate: lastServerUpdate, removed: removed)
    }
    
    var shortOrderDebugDescription: String {
        return "[\(name)], todo: \(todoOrder), done: \(doneOrder), stash: \(stashOrder)"
    }
    
    var debugDescription: String {
        return "{\(type(of: self)) uuid: \(uuid), name: \(name), color: \(color), listUuid: \(list), todoOrder: \(todoOrder), doneOrder: \(doneOrder), stashOrder: \(stashOrder), lastServerUpdate: \(lastServerUpdate)::\(lastServerUpdate?.millisToEpochDate()), removed: \(removed)}}"
    }
    
    func copy(uuid: String? = nil, name: String? = nil, color: UIColor? = nil, list: List? = nil, todoOrder: Int? = nil, doneOrder: Int? = nil, stashOrder: Int? = nil, lastServerUpdate: Int64? = nil, removed: Bool? = nil) -> Section {
        return Section(
            uuid: uuid ?? self.uuid,
            name: name ?? self.name,
            color: color ?? self.color,
            list: list ?? self.list,
            
            todoOrder: todoOrder ?? self.todoOrder,
            doneOrder: doneOrder ?? self.doneOrder,
            stashOrder: stashOrder ?? self.stashOrder,
            
            lastServerUpdate: lastServerUpdate ?? self.lastServerUpdate,
            removed: removed ?? self.removed
        )
    }
    
    func same(_ section: Section) -> Bool {
        return section.uuid == self.uuid
    }
    
    func order(_ status: ListItemStatus) -> Int {
        switch status {
        case .todo: return todoOrder
        case .done: return doneOrder
        case .stash: return stashOrder
        }
    }
    
    func updateOrderMutable(_ order: ListItemStatusOrder) {
        switch order.status {
        case .todo: todoOrder = order.order
        case .done: doneOrder = order.order
        case .stash: stashOrder = order.order
        }
    }
    
    func updateOrder(_ order: ListItemStatusOrder) -> Section {
        return copy(
            todoOrder: order.status == .todo ? order.order : todoOrder,
            doneOrder: order.status == .done ? order.order : doneOrder,
            stashOrder: order.status == .stash ? order.order : stashOrder
        )
    }
    
    func equalsExcludingSyncAttributes(_ rhs: Section) -> Bool {
        return uuid == rhs.uuid && name == rhs.name && color == rhs.color && list == rhs.list && todoOrder == rhs.todoOrder && doneOrder == rhs.doneOrder && stashOrder == rhs.stashOrder
    }
}

func ==(lhs: Section, rhs: Section) -> Bool {
    return lhs.equalsExcludingSyncAttributes(rhs) && lhs.lastServerUpdate == rhs.lastServerUpdate && lhs.removed == rhs.removed
}
