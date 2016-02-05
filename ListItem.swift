//
//  ListItem.swift
//  shoppin
//
//  Created by ischuetz on 13.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import Foundation

enum ListItemStatus: Int {
    case Todo = 0, Done = 1, Stash = 2
}

typealias ListItemStatusQuantity = (status: ListItemStatus, quantity: Int)
typealias ListItemStatusOrder = (status: ListItemStatus, order: Int) // TODO rename as this is used now for sections too

final class ListItem: Equatable, Identifiable, CustomDebugStringConvertible {
    let uuid: String
    let product: Product
    var section: Section
    var list: List

    var note: String?
    
    var todoQuantity: Int
    var todoOrder: Int
    var doneQuantity: Int
    var doneOrder: Int
    var stashQuantity: Int
    var stashOrder: Int
    
    //////////////////////////////////////////////
    // sync properties - FIXME - while Realm allows to return Realm objects from async op. This shouldn't be in model objects.
    // the idea is that we can return the db objs from query and then do sync directly with these objs so no need to put sync attributes in model objs
    // we could map the db objects to other db objs in order to work around the Realm issue, but this adds even more overhead, we make a lot of mappings already
    let lastUpdate: NSDate
    let lastServerUpdate: NSDate?
    let removed: Bool
    //////////////////////////////////////////////

    // Returns the total price for listitem in a certain status
    // If e.g. we have 2x "tomatos" with a price of 2€ in "todo", we get a total price of 4€ for the status "todo".
    func totalPrice(status: ListItemStatus) -> Float {
        return Float(quantity(status)) * product.price / product.baseQuantity
    }
    
    func quantity(status: ListItemStatus) -> Int {
        switch status {
        case .Todo: return todoQuantity
        case .Done: return doneQuantity
        case .Stash: return stashQuantity
        }
    }
    
    func order(status: ListItemStatus) -> Int {
        switch status {
        case .Todo: return todoOrder
        case .Done: return doneOrder
        case .Stash: return stashOrder
        }
    }
    
    init(uuid: String, product: Product, section: Section, list: List, note: String? = nil, todoQuantity: Int, todoOrder: Int, doneQuantity: Int, doneOrder: Int, stashQuantity: Int, stashOrder: Int, lastUpdate: NSDate = NSDate(), lastServerUpdate: NSDate? = nil, removed: Bool = false) {
        self.uuid = uuid
        self.product = product
        self.section = section
        self.list = list
        self.note = note
            
        self.todoQuantity = todoQuantity
        self.todoOrder = todoOrder
        self.doneQuantity = doneQuantity
        self.doneOrder = doneOrder
        self.stashQuantity = stashQuantity
        self.stashOrder = stashOrder

        self.lastUpdate = lastUpdate
        self.lastServerUpdate = lastServerUpdate
        self.removed = removed
    }

    convenience init(uuid: String, product: Product, section: Section, list: List, note: String? = nil, statusOrder: ListItemStatusOrder, statusQuantity: ListItemStatusQuantity, lastUpdate: NSDate = NSDate(), lastServerUpdate: NSDate? = nil, removed: Bool = false) {
        
        func quantity(selfStatus: ListItemStatus, _ statusQuantity: ListItemStatusQuantity) -> Int {
            return statusQuantity.status == selfStatus ? statusQuantity.quantity : 0
        }
        
        func order(selfStatus: ListItemStatus, _ statusOrder: ListItemStatusOrder) -> Int {
            return statusOrder.status == selfStatus ? statusOrder.order : 0
        }
        
        self.init(
            uuid: uuid,
            product: product,
            section: section,
            list: list,
            note: note,
            todoQuantity: quantity(.Todo, statusQuantity),
            todoOrder: order(.Todo, statusOrder),
            doneQuantity: quantity(.Done, statusQuantity),
            doneOrder: order(.Done, statusOrder),
            stashQuantity: quantity(.Stash, statusQuantity),
            stashOrder: order(.Stash, statusOrder),
            lastUpdate: lastUpdate,
            lastServerUpdate: lastServerUpdate,
            removed: removed
        )
    }

    convenience init(uuid: String, product: Product, section: Section, list: List, note: String? = nil, todoQuantity: Int, todoOrder: Int) {
        self.init(
            uuid: uuid,
            product: product,
            section: section,
            list: list,
            note: note,
            todoQuantity: todoQuantity,
            todoOrder: todoOrder,
            doneQuantity: 0,
            doneOrder: 0,
            stashQuantity: 0,
            stashOrder: 0
        )
    }
    
    // Quantity of listitem in a specific status
    private func quantityForStatus(status: ListItemStatus) -> Int {
        switch status {
        case .Todo: return todoQuantity
        case .Done: return doneQuantity
        case .Stash: return stashQuantity
        }
    }
    
    // If this listitem exist in a specific status
    // E.g. if status "done", return true means there is a listitem in done (there can also be one in todo and stash at the same time - this only tells us there's one in done). Return "false" means there's no item in "done"
    // An item is defined to be in a status when it has a quantity > 0 in this status.
    func hasStatus(status: ListItemStatus) -> Bool {
        return quantityForStatus(status) > 0
    }
    
    func same(listItem: ListItem) -> Bool {
        return self.uuid == listItem.uuid
    }
    
    var debugDescription: String {
//        return shortDebugDescription
//        return longDebugDescription
        return quantityDebugDescription
    }
    
    private var shortDebugDescription: String {
        return "[\(product.name)], todo: \(todoQuantity), done: \(doneQuantity), stash: \(stashQuantity)"
    }
    
    private var quantityDebugDescription: String {
        return "\(uuid), \(product.name), todoQuantity: \(todoQuantity), doneQuantity: \(doneQuantity), stashQuantity: \(stashQuantity)"
    }
    
    private var longDebugDescription: String {
        return "{\(self.dynamicType) uuid: \(uuid), note: \(note), productUuid: \(product), sectionUuid: \(section), listUuid: \(list), todoQuantity: \(todoQuantity), todoOrder: \(todoOrder), doneQuantity: \(doneQuantity), doneOrder: \(doneOrder), stashQuantity: \(stashQuantity), stashOrder: \(stashOrder), lastUpdate: \(lastUpdate), lastServerUpdate: \(lastServerUpdate), removed: \(removed)}"
    }
    
    func copy(uuid uuid: String? = nil, product: Product? = nil, section: Section? = nil, list: List? = nil, note: String?, todoQuantity: Int? = nil, todoOrder: Int? = nil, doneQuantity: Int? = nil, doneOrder: Int? = nil, stashQuantity: Int? = nil, stashOrder: Int? = nil) -> ListItem {
        return ListItem(
            uuid: uuid ?? self.uuid,
            product: product ?? self.product,
            section: section ?? self.section,
            list: list ?? self.list,
            note: note ?? self.note,
            
            todoQuantity: todoQuantity ?? self.todoQuantity,
            todoOrder: todoOrder ?? self.todoOrder,
            doneQuantity: doneQuantity ?? self.doneQuantity,
            doneOrder: doneOrder ?? self.doneOrder,
            stashQuantity: stashQuantity ?? self.stashQuantity,
            stashOrder: stashOrder ?? self.stashOrder,
            
            lastUpdate: self.lastUpdate,
            lastServerUpdate: self.lastServerUpdate,
            removed: self.removed
        )
    }
    
    // Increments all the quantity fields (todo, done, stash) by the quantity fields of listItem
    func increment(listItem: ListItem) -> ListItem {
        return increment(listItem.todoQuantity, doneQuantity: listItem.doneQuantity, stashQuantity: listItem.stashQuantity)
    }

    func increment(todoQuantity: Int, doneQuantity: Int, stashQuantity: Int) -> ListItem {
        
        let newTodo = todoQuantity + todoQuantity
        let newDone = doneQuantity + doneQuantity
        let newStash = stashQuantity + stashQuantity
        
        // Sometimes got -1 in .Todo (no server involved) TODO find out why and fix, these checks shouldn't be necessary
        if newTodo < 0 {
            print("Error: ListItem.increment: New todo quantity: \(newTodo) for item: \(self)")
        }
        if newDone < 0 {
            print("Error: ListItem.increment: New done quantity: \(newDone) for item: \(self)")
        }
        if newStash < 0 {
            print("Error: ListItem.increment: New stash quantity: \(newStash) for item: \(self)")
        }
        let checkedTodo = max(0, newTodo)
        let checkedDone = max(0, newDone)
        let checkedStash = max(0, newStash)

        return copy(
            note: note,
            todoQuantity: checkedTodo,
            doneQuantity: checkedDone,
            stashQuantity: checkedStash
        )
    }
    
    func increment(quantity: ListItemStatusQuantity) -> ListItem {
        
        let newTodo = todoQuantity + quantity.quantity
        let newDone = doneQuantity + quantity.quantity
        let newStash = stashQuantity + quantity.quantity
        
        // Sometimes got -1 in .Todo (no server involved) TODO find out why and fix, these checks shouldn't be necessary
        if newTodo < 0 {
            print("Error: ListItem.increment(2): New todo quantity: \(newTodo) for item: \(self)")
        }
        if newDone < 0 {
            print("Error: ListItem.increment(2): New done quantity: \(newDone) for item: \(self)")
        }
        if newStash < 0 {
            print("Error: ListItem.increment(2): New stash quantity: \(newStash) for item: \(self)")
        }
        let checkedTodo = max(0, newTodo)
        let checkedDone = max(0, newDone)
        let checkedStash = max(0, newStash)
        
        switch quantity.status {
        case .Todo: return copy(note: note, todoQuantity: checkedTodo)
        case .Done: return copy(note: note, doneQuantity: checkedDone)
        case .Stash: return copy(note: note, stashQuantity: checkedStash)
        }
    }
    
    func copyIncrement(uuid uuid: String? = nil, product: Product? = nil, section: Section? = nil, list: List? = nil, note: String?, todoOrder: Int? = nil, doneOrder: Int? = nil, stashOrder: Int? = nil, statusQuantity: ListItemStatusQuantity) -> ListItem {
        
        // returns self quantity incremented if self status is the same as statusQuantity status, or returns self quantity unchanged
        func incr(selfQuantity: Int, _ selfStatus: ListItemStatus, _ statusQuantity: ListItemStatusQuantity) -> Int {
            return statusQuantity.status == selfStatus ? (selfQuantity + statusQuantity.quantity) : selfQuantity
        }
        
        return copy(
            uuid: uuid,
            product: product,
            section: section,
            list: list,
            note: note,
            todoQuantity: incr(todoQuantity, .Todo, statusQuantity),
            todoOrder: todoOrder,
            doneQuantity: incr(doneQuantity, .Done, statusQuantity),
            doneOrder: doneOrder,
            stashQuantity: incr(stashQuantity, .Stash, statusQuantity),
            stashOrder: stashOrder
        )
    }
    
    func updateOrderMutable(order: ListItemStatusOrder) {
        switch order.status {
        case .Todo: todoOrder = order.order
        case .Done: doneOrder = order.order
        case .Stash: stashOrder = order.order
        }
    }

    // Overwrite all fields with fields of listItem, except uuid
    func update(listItem: ListItem) -> ListItem {
        return copy(
            uuid: uuid,
            product: listItem.product,
            section: listItem.section,
            list: listItem.list,
            note: listItem.note,
            todoQuantity: listItem.todoQuantity,
            todoOrder: listItem.todoOrder,
            doneQuantity: listItem.doneQuantity,
            doneOrder: listItem.doneOrder,
            stashQuantity: listItem.stashQuantity,
            stashOrder: listItem.stashOrder
        )
    }
    
    func markAsDone() -> ListItem {
        return copy(
            note: note,
            todoQuantity: 0,
            doneQuantity: doneQuantity + todoQuantity
        )
    }
    
    func switchStatusQuantity(status: ListItemStatus, targetStatus: ListItemStatus) -> ListItem {
        
        func updateFieldQuantity(fieldStatus: ListItemStatus, status: ListItemStatus, targetStatus: ListItemStatus) -> Int {
            
            // had to be rewriten to add bounds check, see TODO below
//            return status == fieldStatus ? 0 : (targetStatus == fieldStatus ? quantity(status) + quantity(targetStatus) : quantity(targetStatus))
            if status == fieldStatus {
                return 0
                
            } else {
                if targetStatus == fieldStatus {
                    // Sometimes got -1 in .Todo (no server involved) TODO find out why and fix, these checks shouldn't be necessary
                    let newQuantity = quantity(status) + quantity(targetStatus)
                    if newQuantity < 0 {
                        print("Error: ListItem.switchStatusQuantity: New done quantity: \(newQuantity), status: \(status), targetStatus: \(targetStatus) for item: \(self)")
                    }
                    let checkedQuantity = max(0, newQuantity)
                    return checkedQuantity
                    
                } else {
                    return quantity(targetStatus)
                }
            }
        }
        
        return copy(
            note: note,
            todoQuantity: updateFieldQuantity(.Todo, status: status, targetStatus: targetStatus),
            doneQuantity: updateFieldQuantity(.Done, status: status, targetStatus: targetStatus),
            stashQuantity: updateFieldQuantity(.Stash, status: status, targetStatus: targetStatus)
        )
    }
    
    
    func switchStatusQuantityMutable(status: ListItemStatus, targetStatus: ListItemStatus) {
        
        // Capture variables. We have to do this because when setting the fields they reference each other, and they all need to access the previous, not new state
        let capturedQuantity: ListItemStatus -> Int = {[todoQuantity, doneQuantity, stashQuantity] status  in
            switch status {
            case .Todo: return todoQuantity
            case .Done: return doneQuantity
            case .Stash: return stashQuantity
            }
        }
        
        func fieldQuantity(fieldStatus: ListItemStatus, status: ListItemStatus, targetStatus: ListItemStatus) -> Int {

            // had to be rewriten to add bounds check, see TODO below
//            return status == fieldStatus ? 0 : (targetStatus == fieldStatus ? capturedQuantity(status) + quantity(targetStatus) : quantity(fieldStatus))
            if status == fieldStatus {
                return 0
            } else {
                if targetStatus == fieldStatus {
                    // Sometimes got -1 in .Todo (no server involved) TODO find out why and fix, these checks shouldn't be necessary
                    let newQuantity = capturedQuantity(status) + quantity(targetStatus)
                    if newQuantity < 0 {
                        print("Error: ListItem.switchStatusQuantityMutable: New done quantity: \(newQuantity), fieldStatus: \(fieldStatus), status: \(status), targetStatus: \(targetStatus) for item: \(self)")
                    }
                    let checkedQuantity = max(0, newQuantity)
                    return checkedQuantity
                    
                } else {
                    return quantity(fieldStatus)
                }
            }
        }

        todoQuantity = fieldQuantity(.Todo, status: status, targetStatus: targetStatus)
        doneQuantity = fieldQuantity(.Done, status: status, targetStatus: targetStatus)
        stashQuantity = fieldQuantity(.Stash, status: status, targetStatus: targetStatus)
    }
}

// TODO implement equality correctly, also in other model classes. Now we have Identifiable for this.
func ==(lhs: ListItem, rhs: ListItem) -> Bool {
    return lhs.uuid == rhs.uuid
}

// convenience (redundant) holder to avoid having to iterate through listitems to find unique products, sections, list
// so products, sections arrays and list are the result of extracting the unique products, sections and list from listItems array
typealias ListItemsWithRelations = (listItems: [ListItem], products: [Product], sections: [Section])