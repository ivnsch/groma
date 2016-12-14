//
//  ListItem.swift
//  shoppin
//
//  Created by ischuetz on 13.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

enum ListItemStatus: Int {
    // Note: the raw values are used in server communication, don't change.
    case todo = 0, done = 1, stash = 2
}

typealias ListItemStatusQuantity = (status: ListItemStatus, quantity: Int)
typealias ListItemStatusOrder = (status: ListItemStatus, order: Int) // TODO rename as this is used now for sections too

final class ListItem: Equatable, Identifiable, CustomDebugStringConvertible {
    let uuid: String
    let product: StoreProduct
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
    let lastServerUpdate: Int64?
    let removed: Bool
    //////////////////////////////////////////////

    // Returns the total price for listitem in a certain status
    // If e.g. we have 2x "tomatos" with a price of 2€ in "todo", we get a total price of 4€ for the status "todo".
    func totalPrice(_ status: ListItemStatus) -> Float {
        return Float(quantity(status)) * product.price / product.baseQuantity
    }
    
    func quantity(_ status: ListItemStatus) -> Int {
        switch status {
        case .todo: return todoQuantity
        case .done: return doneQuantity
        case .stash: return stashQuantity
        }
    }
    
    func order(_ status: ListItemStatus) -> Int {
        switch status {
        case .todo: return todoOrder
        case .done: return doneOrder
        case .stash: return stashOrder
        }
    }
    
    init(uuid: String, product: StoreProduct, section: Section, list: List, note: String? = nil, todoQuantity: Int, todoOrder: Int, doneQuantity: Int, doneOrder: Int, stashQuantity: Int, stashOrder: Int, lastServerUpdate: Int64? = nil, removed: Bool = false) {
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

        self.lastServerUpdate = lastServerUpdate
        self.removed = removed
    }

    convenience init(uuid: String, product: StoreProduct, section: Section, list: List, note: String? = nil, statusOrder: ListItemStatusOrder, statusQuantity: ListItemStatusQuantity, lastServerUpdate: Int64? = nil, removed: Bool = false) {
        
        func quantity(_ selfStatus: ListItemStatus, _ statusQuantity: ListItemStatusQuantity) -> Int {
            return statusQuantity.status == selfStatus ? statusQuantity.quantity : 0
        }
        
        func order(_ selfStatus: ListItemStatus, _ statusOrder: ListItemStatusOrder) -> Int {
            return statusOrder.status == selfStatus ? statusOrder.order : 0
        }
        
        self.init(
            uuid: uuid,
            product: product,
            section: section,
            list: list,
            note: note,
            todoQuantity: quantity(.todo, statusQuantity),
            todoOrder: order(.todo, statusOrder),
            doneQuantity: quantity(.done, statusQuantity),
            doneOrder: order(.done, statusOrder),
            stashQuantity: quantity(.stash, statusQuantity),
            stashOrder: order(.stash, statusOrder),
            lastServerUpdate: lastServerUpdate,
            removed: removed
        )
    }

    convenience init(uuid: String, product: StoreProduct, section: Section, list: List, note: String? = nil, todoQuantity: Int, todoOrder: Int) {
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
    fileprivate func quantityForStatus(_ status: ListItemStatus) -> Int {
        switch status {
        case .todo: return todoQuantity
        case .done: return doneQuantity
        case .stash: return stashQuantity
        }
    }
    
    // If this listitem exist in a specific status
    // E.g. if status "done", return true means there is a listitem in done (there can also be one in todo and stash at the same time - this only tells us there's one in done). Return "false" means there's no item in "done"
    // An item is defined to be in a status when it has a quantity > 0 in this status.
    func hasStatus(_ status: ListItemStatus) -> Bool {
        return quantityForStatus(status) > 0
    }
    
    func same(_ listItem: ListItem) -> Bool {
        return self.uuid == listItem.uuid
    }
    
    var debugDescription: String {
//        return shortDebugDescription
//        return longDebugDescription
        return quantityOrderDebugDescription
//        return quantityAndOrderDebugDescription
    }
    
    var shortOrderDebugDescription: String {
        return "[\(product.product.name)], todo: \(todoOrder), done: \(doneOrder), stash: \(stashOrder)"
    }
    
    fileprivate var shortDebugDescription: String {
        return "[\(product.product.name)], todo: \(todoQuantity), done: \(doneQuantity), stash: \(stashQuantity)"
    }
    
    var quantityDebugDescription: String {
        return "\(uuid), \(product.product.name), todoQuantity: \(todoQuantity), doneQuantity: \(doneQuantity), stashQuantity: \(stashQuantity)"
    }
    
    var quantityOrderDebugDescription: String {
        return "\(uuid), \(product.product.name), TODO: (q: \(todoQuantity), o: \(todoOrder)), DONE: (q: \(doneQuantity), o; \(doneOrder)), STASH: (q: \(stashQuantity), o: \(stashOrder))"
//        , section: \(section.shortOrderDebugDescription)
    }
    
    fileprivate var quantityAndOrderDebugDescription: String {
        return "\(uuid), \(product.product.name), todoQuantity: \(todoQuantity), doneQuantity: \(doneQuantity), stashQuantity: \(stashQuantity), todoOrder: \(todoOrder), doneOrder: \(doneOrder), stashOrder: \(stashOrder)"
    }
    
    fileprivate var longDebugDescription: String {
        return "{\(type(of: self)) uuid: \(uuid), note: \(note), productUuid: \(product), sectionUuid: \(section), listUuid: \(list), todoQuantity: \(todoQuantity), todoOrder: \(todoOrder), doneQuantity: \(doneQuantity), doneOrder: \(doneOrder), stashQuantity: \(stashQuantity), stashOrder: \(stashOrder), lastServerUpdate: \(lastServerUpdate)::\(lastServerUpdate?.millisToEpochDate()), removed: \(removed)}"
    }
    
    func copy(uuid: String? = nil, product: StoreProduct? = nil, section: Section? = nil, list: List? = nil, note: String?, todoQuantity: Int? = nil, todoOrder: Int? = nil, doneQuantity: Int? = nil, doneOrder: Int? = nil, stashQuantity: Int? = nil, stashOrder: Int? = nil) -> ListItem {
        return ListItem(
            uuid: uuid ?? self.uuid,
            product: product ?? self.product.copy(),
            section: section ?? self.section,
            list: list ?? self.list.copy(),
            note: note ?? self.note,
            
            todoQuantity: todoQuantity ?? self.todoQuantity,
            todoOrder: todoOrder ?? self.todoOrder,
            doneQuantity: doneQuantity ?? self.doneQuantity,
            doneOrder: doneOrder ?? self.doneOrder,
            stashQuantity: stashQuantity ?? self.stashQuantity,
            stashOrder: stashOrder ?? self.stashOrder,
            
            lastServerUpdate: self.lastServerUpdate,
            removed: self.removed
        )
    }
    
    // Increments all the quantity fields (todo, done, stash) by the quantity fields of listItem
    func increment(_ listItem: ListItem) -> ListItem {
        return increment(listItem.todoQuantity, doneQuantity: listItem.doneQuantity, stashQuantity: listItem.stashQuantity)
    }

    func increment(_ todoQuantity: Int, doneQuantity: Int, stashQuantity: Int) -> ListItem {
        
        let newTodo = self.todoQuantity + todoQuantity
        let newDone = self.doneQuantity + doneQuantity
        let newStash = self.stashQuantity + stashQuantity
        
        // Sometimes got -1 in .Todo (no server involved) TODO find out why and fix, these checks shouldn't be necessary
        if newTodo < 0 {
            QL4("New todo quantity: \(newTodo) for item: \(self)")
        }
        if newDone < 0 {
            QL4("New done quantity: \(newDone) for item: \(self)")
        }
        if newStash < 0 {
            QL4("New stash quantity: \(newStash) for item: \(self)")
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
    
    func increment(_ quantity: ListItemStatusQuantity) -> ListItem {
        let increments: (todo: Int, done: Int, stash: Int) = {
            switch quantity.status {
                case .todo: return (quantity.quantity, 0, 0)
                case .done: return (0, quantity.quantity, 0)
                case .stash: return (0, 0, quantity.quantity)
            }
        }()
        return increment(increments.todo, doneQuantity: increments.done, stashQuantity: increments.stash)
    }
    
    func copyIncrement(uuid: String? = nil, product: StoreProduct? = nil, section: Section? = nil, list: List? = nil, note: String?, todoOrder: Int? = nil, doneOrder: Int? = nil, stashOrder: Int? = nil, statusQuantity: ListItemStatusQuantity) -> ListItem {
        
        // returns self quantity incremented if self status is the same as statusQuantity status, or returns self quantity unchanged
        func incr(_ selfQuantity: Int, _ selfStatus: ListItemStatus, _ statusQuantity: ListItemStatusQuantity) -> Int {
            return statusQuantity.status == selfStatus ? (selfQuantity + statusQuantity.quantity) : selfQuantity
        }
        
        return copy(
            uuid: uuid,
            product: product,
            section: section,
            list: list,
            note: note,
            todoQuantity: incr(todoQuantity, .todo, statusQuantity),
            todoOrder: todoOrder,
            doneQuantity: incr(doneQuantity, .done, statusQuantity),
            doneOrder: doneOrder,
            stashQuantity: incr(stashQuantity, .stash, statusQuantity),
            stashOrder: stashOrder
        )
    }
    
    func updateOrder(_ order: ListItemStatusOrder) -> ListItem {
        return copy(
            uuid: uuid,
            product: product,
            section: section,
            list: list,
            note: note,
            todoQuantity: todoQuantity,
            todoOrder: order.status == .todo ? order.order : todoOrder,
            doneQuantity: doneQuantity,
            doneOrder: order.status == .done ? order.order : doneOrder,
            stashQuantity: stashQuantity,
            stashOrder: order.status == .stash ? order.order : stashOrder
        )
    }

    func updateOrderMutable(_ order: ListItemStatusOrder) {
        switch order.status {
        case .todo: todoOrder = order.order
        case .done: doneOrder = order.order
        case .stash: stashOrder = order.order
        }
    }
    
    func updateQuantity(_ quantity: ListItemStatusQuantity) -> ListItem {
        return copy(
            uuid: uuid,
            product: product,
            section: section,
            list: list,
            note: note,
            todoQuantity: quantity.status == .todo ? quantity.quantity : todoQuantity,
            todoOrder: todoOrder,
            doneQuantity: quantity.status == .done ? quantity.quantity : doneQuantity,
            doneOrder: doneOrder,
            stashQuantity: quantity.status == .stash ? quantity.quantity : stashQuantity,
            stashOrder: stashOrder
        )
    }
    
    // Overwrite all fields with fields of listItem, except uuid
    func update(_ listItem: ListItem) -> ListItem {
        return update(listItem, storeProduct: listItem.product)
    }

    // Updates self and its dependencies with listItem, the references to the dependencies (uuid) are not changed
    func updateWithoutChangingReferences(_ listItem: ListItem) -> ListItem {
        let updatedStoreProduct = product.updateWithoutChangingReferences(listItem.product)
        return update(listItem, storeProduct: updatedStoreProduct)
    }
    
    fileprivate func update(_ listItem: ListItem, storeProduct: StoreProduct) -> ListItem {
        return copy(
            uuid: uuid,
            product: storeProduct,
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
    
    func update(_ product: StoreProduct) -> ListItem {
        return copy(product: product, note: nil)
    }

    func update(_ product: Product) -> ListItem {
        let updatedStoreProduct = self.product.copy(product: product)
        return copy(product: updatedStoreProduct, note: nil)
    }
    
    func switchStatusQuantity(_ status: ListItemStatus, targetStatus: ListItemStatus) -> ListItem {
        
        func updateFieldQuantity(_ fieldStatus: ListItemStatus, status: ListItemStatus, targetStatus: ListItemStatus) -> Int {
            
            // had to be rewriten to add bounds check, see TODO below
//            return status == fieldStatus ? 0 : (targetStatus == fieldStatus ? quantity(status) + quantity(targetStatus) : quantity(targetStatus))
            if status == fieldStatus {
                return 0
                
            } else {
                if targetStatus == fieldStatus {
                    // Sometimes got -1 in .Todo (no server involved) TODO find out why and fix, these checks shouldn't be necessary
                    let newQuantity = quantity(status) + quantity(targetStatus)
                    if newQuantity < 0 {
                        QL4("New done quantity: \(newQuantity), status: \(status), targetStatus: \(targetStatus) for item: \(self)")
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
            todoQuantity: updateFieldQuantity(.todo, status: status, targetStatus: targetStatus),
            doneQuantity: updateFieldQuantity(.done, status: status, targetStatus: targetStatus),
            stashQuantity: updateFieldQuantity(.stash, status: status, targetStatus: targetStatus)
        )
    }
    
    static func quantityFieldName(_ status: ListItemStatus) -> String {
        switch status {
        case .todo: return "todoQuantity"
        case .done: return "doneQuantity"
        case .stash: return "stashQuantity"
        }
    }

    static func orderFieldName(_ status: ListItemStatus) -> String {
        switch status {
        case .todo: return "todoOrder"
        case .done: return "doneOrder"
        case .stash: return "stashOrder"
        }
    }
    
    func switchStatusQuantityMutable(_ status: ListItemStatus, targetStatus: ListItemStatus) {
        
        // Capture variables. We have to do this because when setting the fields they reference each other, and they all need to access the previous, not new state
        let capturedQuantity: (ListItemStatus) -> Int = {[todoQuantity, doneQuantity, stashQuantity] status  in
            switch status {
            case .todo: return todoQuantity
            case .done: return doneQuantity
            case .stash: return stashQuantity
            }
        }
        
        func fieldQuantity(_ fieldStatus: ListItemStatus, status: ListItemStatus, targetStatus: ListItemStatus) -> Int {

            // had to be rewriten to add bounds check, see TODO below
//            return status == fieldStatus ? 0 : (targetStatus == fieldStatus ? capturedQuantity(status) + quantity(targetStatus) : quantity(fieldStatus))
            if status == fieldStatus {
                return 0
            } else {
                if targetStatus == fieldStatus {
                    // Sometimes got -1 in .Todo (no server involved) TODO find out why and fix, these checks shouldn't be necessary
                    let newQuantity = capturedQuantity(status) + quantity(targetStatus)
                    if newQuantity < 0 {
                        QL4("New done quantity: \(newQuantity), fieldStatus: \(fieldStatus), status: \(status), targetStatus: \(targetStatus) for item: \(self)")
                    }
                    let checkedQuantity = max(0, newQuantity)
                    return checkedQuantity
                    
                } else {
                    return quantity(fieldStatus)
                }
            }
        }

        todoQuantity = fieldQuantity(.todo, status: status, targetStatus: targetStatus)
        doneQuantity = fieldQuantity(.done, status: status, targetStatus: targetStatus)
        stashQuantity = fieldQuantity(.stash, status: status, targetStatus: targetStatus)
    }
    
    func equalsExcludingSyncAttributes(_ rhs: ListItem) -> Bool {
        return uuid == rhs.uuid && product == rhs.product && section == rhs.section && list == rhs.list && note == rhs.note && todoQuantity == rhs.todoQuantity && todoOrder == rhs.todoOrder && doneQuantity == rhs.doneQuantity && doneOrder == rhs.doneOrder && stashQuantity == rhs.stashQuantity && stashOrder == rhs.stashOrder
    }
}


func ==(lhs: ListItem, rhs: ListItem) -> Bool {
    return lhs.equalsExcludingSyncAttributes(rhs) && lhs.lastServerUpdate == rhs.lastServerUpdate && lhs.removed == rhs.removed
}

// convenience (redundant) holder to avoid having to iterate through listitems to find unique products, sections, list
// so products, sections arrays and list are the result of extracting the unique products, sections and list from listItems array
typealias ListItemsWithRelations = (listItems: [ListItem], storeProducts: [StoreProduct], products: [Product], sections: [Section])
