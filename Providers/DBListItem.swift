//
//  ListItem.swift
//  shoppin
//
//  Created by ischuetz on 14/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift


public enum ListItemStatus: Int {
    // Note: the raw values are used in server communication, don't change.
    case todo = 0, done = 1, stash = 2
}

public typealias ListItemStatusQuantity = (status: ListItemStatus, quantity: Float)
public typealias ListItemStatusOrder = (status: ListItemStatus, order: Int) // TODO rename as this is used now for sections too


public class ListItem: DBSyncable, Identifiable {
    
    // TODO maybe remove references to Section and List
    
    @objc public dynamic var uuid: String = ""
    @objc dynamic var sectionOpt: Section? = Section()
    @objc dynamic var productOpt: StoreProduct? = StoreProduct()
    @objc dynamic var listOpt: List? = List()
    @objc public dynamic var note: String = "" // TODO review if we can use optionals in realm, if not check if in newer version
    
    
    // TODO!!!!!!!!!!!!!!!!! remove this
    @objc public dynamic var todoQuantity: Float = 0
    @objc public dynamic var todoOrder: Int = 0
    @objc public dynamic var doneQuantity: Float = 0
    @objc public dynamic var doneOrder: Int = 0
    @objc public dynamic var stashQuantity: Float = 0
    @objc public dynamic var stashOrder: Int = 0
    
    
    @objc public dynamic var quantity: Float = 0
    
    public var list: List {
        get {
            return listOpt ?? List()
        }
        set(newList) {
            listOpt = newList
        }
    }
    
    public var section: Section {
        get {
            return sectionOpt ?? Section()
        }
        set(newSection) {
            sectionOpt = newSection
        }
    }
    
    public var product: StoreProduct {
        get {
            return productOpt ?? StoreProduct()
        }
        set(newProduct) {
            productOpt = newProduct
        }
    }
    
    // Returns the total price for listitem in a certain status
    // If e.g. we have 2x "tomatos" with a price of 2€ in "todo", we get a total price of 4€ for the status "todo".
    public func totalPrice() -> Float {
        return quantity * product.basePrice
    }
    
    public override static func primaryKey() -> String? {
        return "uuid"
    }
    

    // TODO use only this initializer?
    public convenience init(uuid: String, product: StoreProduct, section: Section, list: List, note: String?, quantity: Float) {
        
        self.init()
        
        self.uuid = uuid
        self.product = product
        self.section = section
        self.list = list
        self.note = note ?? ""
        
        self.quantity = quantity
    }
    
    
    public convenience init(uuid: String, product: StoreProduct, section: Section, list: List, note: String?, todoQuantity: Float, todoOrder: Int, doneQuantity: Float, doneOrder: Int, stashQuantity: Float, stashOrder: Int, lastServerUpdate: Int64? = nil, removed: Bool = false) {
        
        self.init()
        
        self.uuid = uuid
        self.product = product
        self.section = section
        self.list = list
        self.note = note ?? ""
        
        self.todoQuantity = todoQuantity
        self.todoOrder = todoOrder
        self.doneQuantity = doneQuantity
        self.doneOrder = doneOrder
        self.stashQuantity = stashQuantity
        self.stashOrder = stashOrder
        
        if let lastServerUpdate = lastServerUpdate {
            self.lastServerUpdate = lastServerUpdate
        }
        self.removed = removed
    }
    
    public convenience init(uuid: String, product: StoreProduct, section: Section, list: List, note: String? = nil, statusOrder: ListItemStatusOrder, statusQuantity: ListItemStatusQuantity, lastServerUpdate: Int64? = nil, removed: Bool = false) {

        func quantity(_ selfStatus: ListItemStatus, _ statusQuantity: ListItemStatusQuantity) ->Float {
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

    public convenience init(uuid: String, product: StoreProduct, section: Section, list: List, note: String? = nil, todoQuantity: Float, todoOrder: Int) {
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
    public func quantityForStatus(_ status: ListItemStatus) -> Float {
        switch status {
        case .todo: return todoQuantity
        case .done: return doneQuantity
        case .stash: return stashQuantity
        }
    }

    public func hasStatus(_ status: ListItemStatus) -> Bool {
        return quantityForStatus(status) > 0
    }
    
    // Increments all the quantity fields (todo, done, stash) by the quantity fields of listItem
    public func increment(_ listItem: ListItem) -> ListItem {
        return increment(listItem.todoQuantity, doneQuantity: listItem.doneQuantity, stashQuantity: listItem.stashQuantity)
    }

    public func increment(_ todoQuantity: Float, doneQuantity: Float, stashQuantity: Float) -> ListItem {

        let newTodo = self.todoQuantity + todoQuantity
        let newDone = self.doneQuantity + doneQuantity
        let newStash = self.stashQuantity + stashQuantity

        // Sometimes got -1 in .Todo (no server involved) TODO find out why and fix, these checks shouldn't be necessary
        if newTodo < 0 {
            logger.e("New todo quantity: \(newTodo) for item: \(self)")
        }
        if newDone < 0 {
            logger.e("New done quantity: \(newDone) for item: \(self)")
        }
        if newStash < 0 {
            logger.e("New stash quantity: \(newStash) for item: \(self)")
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

    public func increment(_ quantity: ListItemStatusQuantity) -> ListItem {
        let increments: (todo: Float, done: Float, stash: Float) = {
            switch quantity.status {
                case .todo: return (quantity.quantity, 0, 0)
                case .done: return (0, quantity.quantity, 0)
                case .stash: return (0, 0, quantity.quantity)
            }
        }()
        return increment(increments.todo, doneQuantity: increments.done, stashQuantity: increments.stash)
    }

    
    public func copy(uuid: String? = nil, product: StoreProduct? = nil, section: Section? = nil, list: List? = nil, note: String? = nil, todoQuantity: Float? = nil, todoOrder: Int? = nil, doneQuantity: Float? = nil, doneOrder: Int? = nil, stashQuantity: Float? = nil, stashOrder: Int? = nil) -> ListItem {
        return ListItem(
            uuid: uuid ?? self.uuid,
            product: product ?? self.product.copy(),
            section: section ?? self.section.copy(),
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
    
    // MARK: - Filters
    
    static func createFilter(_ uuid: String) -> String {
        return "uuid == '\(uuid)'"
    }

    static func createFilterForUuids(_ uuids: [String]) -> String {
        let uuidsStr: String = uuids.map{"'\($0)'"}.joined(separator: ",")
        return "uuid IN {\(uuidsStr)}"
    }
    
    static func createFilterList(_ listUuid: String) -> String {
        return "listOpt.uuid == '\(listUuid)'"
    }

    static func createFilter(inventoryUuid: String) -> String {
        return "listOpt.inventoryOpt.uuid == '\(inventoryUuid)'"
    }

    static func createFilter(listUuid: String, status: ListItemStatus) -> String {
        let statusKey: String = {
            switch status {
            case .todo: return "todoQuantity"
            case .done: return "doneQuantity"
            case .stash: return "stashQuantity"
            }
        }()
        
        return "\(createFilterList(listUuid)) AND \(statusKey) > 0"
    }
    
    static func createFilter(_ list: List, product: Product) -> String {
        return createFilterUniqueInList(product.item.name, productBrand: product.brand, list: list)
    }

    static func createFilterUniqueInList(_ productName: String, productBrand: String, list: List) -> String {
        return "\(createFilterList(list.uuid)) AND productOpt.productOpt.productOpt.itemOpt.name == '\(productName)' AND productOpt.productOpt.productOpt.brand == '\(productBrand)'"
    }

//     AND productOpt.productOpt.unit.name == '\(unit)' AND productOpt.productOpt.baseQuantity == \(baseQuantity)
    static func createFilterUniqueInListNotUuid(_ productName: String, productBrand: String, notUuid: String, list: List) -> String {
        return "\(createFilterList(list.uuid)) AND productOpt.productOpt.productOpt.itemOpt.name == '\(productName)' AND productOpt.productOpt.productOpt.brand == '\(productBrand)' AND uuid != '\(notUuid)'"
    }
    
    static func createFilterWithStoreProducts(_ uuids: [String]) -> String {
        let uuidsStr: String = uuids.map{"'\($0)'"}.joined(separator: ",")
        return "productOpt.uuid IN {\(uuidsStr)}"
    }
    
    static func createFilterWithProductName(_ productName: String, listUuid: String) -> String {
        return "productOpt.productOpt.productOpt.itemOpt.name == '\(productName)' && listOpt.uuid == '\(listUuid)'"
    }
    
    static func createFilterWithQuantifiableProduct(name: String, unit: Unit) -> String {
        return "productOpt.productOpt.productOpt.itemOpt.name == '\(name)' AND productOpt.productOpt.unitOpt.name == '\(unit.name)'"
    }

    static func createFilterWithSection(_ sectionUuid: String) -> String {
        return "sectionOpt.uuid == '\(sectionUuid)'"
    }
    
    
    
    
    
    
    
    static func createFilter(quantifiableProductUnique: QuantifiableProductUnique) -> String {
        return "productOpt.productOpt.productOpt.itemOpt.name == '\(quantifiableProductUnique.name)' AND productOpt.productOpt.productOpt.brand == '\(quantifiableProductUnique.brand)' AND productOpt.productOpt.unitOpt.name == '\(quantifiableProductUnique.unit)' AND productOpt.productOpt.baseQuantity == \(quantifiableProductUnique.baseQuantity)"
    }
   
    
    
    
    // Finds list items that have the same product names as listItems and are in the same list
    // WARN: Assumes all the list items belong to the same list (list uuid of first list item is used)
//    // TODO? in case we have to enable this again, check if we need product unit, store etc. here
//    public static func createFilterListItems(_ listItems: [ListItem]) -> String {
//        let productNamesStr: String = listItems.map{"'\($0.product.product.product.name)'"}.joined(separator: ",")
//        let listUuid = listItems.first?.list.uuid ?? ""
//        return "productOpt.name IN {\(productNamesStr)} AND listOpt.uuid = '\(listUuid)'"
//    }
    
    // MARK: - CustomDebugStringConvertible
    
    public override var debugDescription: String {
//        return shortDebugDescription
//        return longDebugDescription
        return quantityOrderDebugDescription
//        return quantityAndOrderDebugDescription
    }

    public var shortOrderDebugDescription: String {
        return "[\(product.product.product.item.name)], unit: \(product.product.unit), todo: \(todoOrder), done: \(doneOrder), stash: \(stashOrder)"
    }

    public var shortDebugDescription: String {
        return "[\(product.product.product.item.name), quantity: \(quantity), uuid: \(uuid), section: \(section.name)]"
    }

    public var quantityDebugDescription: String {
        return "\(uuid), \(product.product.product.item.name), todoQuantity: \(todoQuantity), doneQuantity: \(doneQuantity), stashQuantity: \(stashQuantity)"
    }

    public var quantityOrderDebugDescription: String {
        return "\(uuid), \(product.product.product.item.name), TODO: (q: \(todoQuantity), o: \(todoOrder)), DONE: (q: \(doneQuantity), o; \(doneOrder)), STASH: (q: \(stashQuantity), o: \(stashOrder))"
//        , section: \(section.shortOrderDebugDescription)
    }

    fileprivate var quantityAndOrderDebugDescription: String {
        return "\(uuid), \(product.product.product.item.name), todoQuantity: \(todoQuantity), doneQuantity: \(doneQuantity), stashQuantity: \(stashQuantity), todoOrder: \(todoOrder), doneOrder: \(doneOrder), stashOrder: \(stashOrder)"
    }

    fileprivate var longDebugDescription: String {
        return "{\(type(of: self)) uuid: \(uuid), note: \(note), productUuid: \(product), sectionUuid: \(section), listUuid: \(list), todoQuantity: \(todoQuantity), todoOrder: \(todoOrder), doneQuantity: \(doneQuantity), doneOrder: \(doneOrder), stashQuantity: \(stashQuantity), stashOrder: \(stashOrder)}"
    }
    
    static func fromDict(_ dict: [String: AnyObject], section: Section, product: StoreProduct, list: List) -> ListItem {
        let item = ListItem()
        item.uuid = dict["uuid"]! as! String
        item.section = section
        item.product = product
        item.list = list
        item.note = dict["note"]! as! String
        item.todoQuantity = dict["todoQuantity"]! as! Float
        item.todoOrder = dict["todoOrder"]! as! Int
        item.doneQuantity = dict["doneQuantity"]! as! Float
        item.doneOrder = dict["doneOrder"]! as! Int
        item.stashQuantity = dict["stashQuantity"]! as! Float
        item.stashOrder = dict["stashOrder"]! as! Int
        item.setSyncableFieldswithRemoteDict(dict)
        return item
    }
    
    func toDict() -> [String: AnyObject] {
        var dict = [String: AnyObject]()
        dict["uuid"] = uuid as AnyObject?
        dict["sectionInput"] = section.toDict() as AnyObject?
        dict["storeProductInput"] = product.toDict() as AnyObject?
        // TODO fix sync input models
//        dict["list"] = list.toDict()
        dict["listUuid"] = list.uuid as AnyObject?
        dict["listName"] = list.name as AnyObject?
        
        dict["note"] = note as AnyObject?
        dict["todoQuantity"] = todoQuantity as AnyObject?
        dict["todoOrder"] = todoOrder as AnyObject?
        dict["doneQuantity"] = doneQuantity as AnyObject?
        dict["doneOrder"] = doneOrder as AnyObject?
        dict["stashQuantity"] = stashQuantity as AnyObject?
        dict["stashOrder"] = stashOrder as AnyObject?
        setSyncableFieldsInDict(&dict)
        return dict
    }
    
    public override static func ignoredProperties() -> [String] {
        return ["list", "section", "product", "swiped"]
    }
    
    static func timestampUpdateDict(_ uuid: String, lastUpdate: Int64) -> [String: AnyObject] {
        return DBSyncable.timestampUpdateDict(uuid, lastServerUpdate: lastUpdate)
    }
    
    // MARK: -
    
    public static func quantityFieldName(_ status: ListItemStatus) -> String {
        switch status {
        case .todo: return "todoQuantity"
        case .done: return "doneQuantity"
        case .stash: return "stashQuantity"
        }
    }
    
    public static func orderFieldName(_ status: ListItemStatus) -> String {
        switch status {
        case .todo: return "todoOrder"
        case .done: return "doneOrder"
        case .stash: return "stashOrder"
        }
    }
    
    public func quantity(_ status: ListItemStatus) -> Float {
        switch status {
        case .todo: return todoQuantity
        case .done: return doneQuantity
        case .stash: return stashQuantity
        }
    }

    public func order(_ status: ListItemStatus) -> Int {
        switch status {
        case .todo: return todoOrder
        case .done: return doneOrder
        case .stash: return stashOrder
        }
    }
    
    public func updateOrderMutable(_ order: ListItemStatusOrder) {
        switch order.status {
        case .todo: todoOrder = order.order
        case .done: doneOrder = order.order
        case .stash: stashOrder = order.order
        }
    }
    
    public func updateQuantity(_ quantity: ListItemStatusQuantity) -> ListItem {
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

    public func updateOrder(_ order: ListItemStatusOrder) -> ListItem {
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
    
    public func copyIncrement(uuid: String? = nil, product: StoreProduct? = nil, section: Section? = nil, list: List? = nil, note: String?, todoOrder: Int? = nil, doneOrder: Int? = nil, stashOrder: Int? = nil, statusQuantity: ListItemStatusQuantity) -> ListItem {

        // returns self quantity incremented if self status is the same as statusQuantity status, or returns self quantity unchanged
        func incr(_ selfQuantity: Float, _ selfStatus: ListItemStatus, _ statusQuantity: ListItemStatusQuantity) -> Float {
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

    
    public func switchStatusQuantityMutable(_ status: ListItemStatus, targetStatus: ListItemStatus) {

        // Capture variables. We have to do this because when setting the fields they reference each other, and they all need to access the previous, not new state
        let capturedQuantity: (ListItemStatus) -> Float = {[todoQuantity, doneQuantity, stashQuantity] status  in
            switch status {
            case .todo: return todoQuantity
            case .done: return doneQuantity
            case .stash: return stashQuantity
            }
        }

        func fieldQuantity(_ fieldStatus: ListItemStatus, status: ListItemStatus, targetStatus: ListItemStatus) -> Float {

            // had to be rewriten to add bounds check, see TODO below
//            return status == fieldStatus ? 0 : (targetStatus == fieldStatus ? capturedQuantity(status) + quantity(targetStatus) : quantity(fieldStatus))
            if status == fieldStatus {
                return 0
            } else {
                if targetStatus == fieldStatus {
                    // Sometimes got -1 in .Todo (no server involved) TODO find out why and fix, these checks shouldn't be necessary
                    let newQuantity = capturedQuantity(status) + quantity(targetStatus)
                    if newQuantity < 0 {
                        logger.e("New done quantity: \(newQuantity), fieldStatus: \(fieldStatus), status: \(status), targetStatus: \(targetStatus) for item: \(self)")
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
    
    public func update(storeProduct: StoreProduct) -> ListItem {
        return copy(product: product, note: nil)
    }

    public func update(product: QuantifiableProduct) -> ListItem {
        let updatedStoreProduct = self.product.copy(product: product)
        return copy(product: updatedStoreProduct, note: nil)
    }
    
    public func incrementQuantity(_ delta: Float) {
        let updatedQuantity = quantity + delta
        if updatedQuantity >= 0 {
            quantity = quantity + delta
        } else {
            logger.v("Trying to decrement quantity to less than zero. Current quantity: \(quantity), delta: \(delta). Setting it to 0.")
            quantity = 0
        }
    }
    
    public func same(_ listItem: ListItem) -> Bool {
        return self.uuid == listItem.uuid
    }
    
    public func quantityTextWithoutName() -> String {

        let baseQuantityText = product.product.baseQuantity > 1 ? QuantifiableProduct.baseQuantityNumberFormatter.string(from: NSNumber(value: product.product.baseQuantity))! : ""
        let finalBaseQuantityText = baseQuantityText.isEmpty ? "" : "x \(baseQuantityText)"

        let unitText: String = {
            if product.product.unit.id == .none {
                if quantity == 1 {
                    return trans("unit_unit")
                } else {
                    return trans("unit_unit_pl")
                }
            } else {
                return product.product.unit.name
            }
        } ()

        let unitSeparator = !product.product.unit.name.isEmpty && !baseQuantityText.isEmpty ? " " : ""
        let baseAndUnitText = "\(finalBaseQuantityText)\(unitSeparator)\(unitText)"
        
        return "\(quantity.quantityString) \(baseAndUnitText)"
    }
    
    // MARK: - UI additions
    // For now we will avoid having to create additional classes to manage UI related state and will just put it here
    
    public var swiped: Bool = false // rename in open?
}

// convenience (redundant) holder to avoid having to iterate through listitems to find unique products, sections, list
// so products, sections arrays and list are the result of extracting the unique products, sections and list from listItems array
public typealias ListItemsWithRelations = (listItems: [ListItem], storeProducts: [StoreProduct], products: [Product], sections: [Section])


//
//public enum ListItemStatus: Int {
//    // Note: the raw values are used in server communication, don't change.
//    case todo = 0, done = 1, stash = 2
//}
//
//public typealias ListItemStatusQuantity = (status: ListItemStatus, quantity: Int)
//public typealias ListItemStatusOrder = (status: ListItemStatus, order: Int) // TODO rename as this is used now for sections too
//
//public final class ListItem: Equatable, Identifiable, CustomDebugStringConvertible {
//    public let uuid: String
//    public let product: StoreProduct
//    public var section: Section
//    public var list: List
//
//    public var note: String?
//
//    public var todoQuantity: Int
//    public var todoOrder: Int
//    public var doneQuantity: Int
//    public var doneOrder: Int
//    public var stashQuantity: Int
//    public var stashOrder: Int
//
//    //////////////////////////////////////////////
//    // sync properties - FIXME - while Realm allows to return Realm objects from async op. This shouldn't be in model objects.
//    // the idea is that we can return the db objs from query and then do sync directly with these objs so no need to put sync attributes in model objs
//    // we could map the db objects to other db objs in order to work around the Realm issue, but this adds even more overhead, we make a lot of mappings already
//    public let lastServerUpdate: Int64?
//    public let removed: Bool
//    //////////////////////////////////////////////
//
//    // Returns the total price for listitem in a certain status
//    // If e.g. we have 2x "tomatos" with a price of 2€ in "todo", we get a total price of 4€ for the status "todo".
//    public func totalPrice(_ status: ListItemStatus) -> Float {
//        return Float(quantity(status)) * product.price / product.baseQuantity
//    }
//
//    public func quantity(_ status: ListItemStatus) -> Int {
//        switch status {
//        case .todo: return todoQuantity
//        case .done: return doneQuantity
//        case .stash: return stashQuantity
//        }
//    }
//
//    public func order(_ status: ListItemStatus) -> Int {
//        switch status {
//        case .todo: return todoOrder
//        case .done: return doneOrder
//        case .stash: return stashOrder
//        }
//    }
//
//    public init(uuid: String, product: StoreProduct, section: Section, list: List, note: String? = nil, todoQuantity: Int, todoOrder: Int, doneQuantity: Int, doneOrder: Int, stashQuantity: Int, stashOrder: Int, lastServerUpdate: Int64? = nil, removed: Bool = false) {
//        self.uuid = uuid
//        self.product = product
//        self.section = section
//        self.list = list
//        self.note = note
//
//        self.todoQuantity = todoQuantity
//        self.todoOrder = todoOrder
//        self.doneQuantity = doneQuantity
//        self.doneOrder = doneOrder
//        self.stashQuantity = stashQuantity
//        self.stashOrder = stashOrder
//
//        self.lastServerUpdate = lastServerUpdate
//        self.removed = removed
//    }
//
//    public convenience init(uuid: String, product: StoreProduct, section: Section, list: List, note: String? = nil, statusOrder: ListItemStatusOrder, statusQuantity: ListItemStatusQuantity, lastServerUpdate: Int64? = nil, removed: Bool = false) {
//
//        func quantity(_ selfStatus: ListItemStatus, _ statusQuantity: ListItemStatusQuantity) -> Int {
//            return statusQuantity.status == selfStatus ? statusQuantity.quantity : 0
//        }
//
//        func order(_ selfStatus: ListItemStatus, _ statusOrder: ListItemStatusOrder) -> Int {
//            return statusOrder.status == selfStatus ? statusOrder.order : 0
//        }
//
//        self.init(
//            uuid: uuid,
//            product: product,
//            section: section,
//            list: list,
//            note: note,
//            todoQuantity: quantity(.todo, statusQuantity),
//            todoOrder: order(.todo, statusOrder),
//            doneQuantity: quantity(.done, statusQuantity),
//            doneOrder: order(.done, statusOrder),
//            stashQuantity: quantity(.stash, statusQuantity),
//            stashOrder: order(.stash, statusOrder),
//            lastServerUpdate: lastServerUpdate,
//            removed: removed
//        )
//    }
//
//    public convenience init(uuid: String, product: StoreProduct, section: Section, list: List, note: String? = nil, todoQuantity: Int, todoOrder: Int) {
//        self.init(
//            uuid: uuid,
//            product: product,
//            section: section,
//            list: list,
//            note: note,
//            todoQuantity: todoQuantity,
//            todoOrder: todoOrder,
//            doneQuantity: 0,
//            doneOrder: 0,
//            stashQuantity: 0,
//            stashOrder: 0
//        )
//    }
//
//    // Quantity of listitem in a specific status
//    fileprivate func quantityForStatus(_ status: ListItemStatus) -> Int {
//        switch status {
//        case .todo: return todoQuantity
//        case .done: return doneQuantity
//        case .stash: return stashQuantity
//        }
//    }
//
//    // If this listitem exist in a specific status
//    // E.g. if status "done", return true means there is a listitem in done (there can also be one in todo and stash at the same time - this only tells us there's one in done). Return "false" means there's no item in "done"
//    // An item is defined to be in a status when it has a quantity > 0 in this status.
//    public func hasStatus(_ status: ListItemStatus) -> Bool {
//        return quantityForStatus(status) > 0
//    }
//
//    public func same(_ listItem: ListItem) -> Bool {
//        return self.uuid == listItem.uuid
//    }
//
//    public var debugDescription: String {
////        return shortDebugDescription
////        return longDebugDescription
//        return quantityOrderDebugDescription
////        return quantityAndOrderDebugDescription
//    }
//
//    public var shortOrderDebugDescription: String {
//        return "[\(product.product.name)], todo: \(todoOrder), done: \(doneOrder), stash: \(stashOrder)"
//    }
//
//    fileprivate var shortDebugDescription: String {
//        return "[\(product.product.name)], todo: \(todoQuantity), done: \(doneQuantity), stash: \(stashQuantity)"
//    }
//
//    public var quantityDebugDescription: String {
//        return "\(uuid), \(product.product.name), todoQuantity: \(todoQuantity), doneQuantity: \(doneQuantity), stashQuantity: \(stashQuantity)"
//    }
//
//    public var quantityOrderDebugDescription: String {
//        return "\(uuid), \(product.product.name), TODO: (q: \(todoQuantity), o: \(todoOrder)), DONE: (q: \(doneQuantity), o; \(doneOrder)), STASH: (q: \(stashQuantity), o: \(stashOrder))"
////        , section: \(section.shortOrderDebugDescription)
//    }
//
//    fileprivate var quantityAndOrderDebugDescription: String {
//        return "\(uuid), \(product.product.name), todoQuantity: \(todoQuantity), doneQuantity: \(doneQuantity), stashQuantity: \(stashQuantity), todoOrder: \(todoOrder), doneOrder: \(doneOrder), stashOrder: \(stashOrder)"
//    }
//
//    fileprivate var longDebugDescription: String {
//        return "{\(type(of: self)) uuid: \(uuid), note: \(note), productUuid: \(product), sectionUuid: \(section), listUuid: \(list), todoQuantity: \(todoQuantity), todoOrder: \(todoOrder), doneQuantity: \(doneQuantity), doneOrder: \(doneOrder), stashQuantity: \(stashQuantity), stashOrder: \(stashOrder), lastServerUpdate: \(lastServerUpdate)::\(lastServerUpdate?.millisToEpochDate()), removed: \(removed)}"
//    }
//
//    public func copy(uuid: String? = nil, product: StoreProduct? = nil, section: Section? = nil, list: List? = nil, note: String?, todoQuantity: Int? = nil, todoOrder: Int? = nil, doneQuantity: Int? = nil, doneOrder: Int? = nil, stashQuantity: Int? = nil, stashOrder: Int? = nil) -> ListItem {
//        return ListItem(
//            uuid: uuid ?? self.uuid,
//            product: product ?? self.product.copy(),
//            section: section ?? self.section,
//            list: list ?? self.list.copy(),
//            note: note ?? self.note,
//
//            todoQuantity: todoQuantity ?? self.todoQuantity,
//            todoOrder: todoOrder ?? self.todoOrder,
//            doneQuantity: doneQuantity ?? self.doneQuantity,
//            doneOrder: doneOrder ?? self.doneOrder,
//            stashQuantity: stashQuantity ?? self.stashQuantity,
//            stashOrder: stashOrder ?? self.stashOrder,
//
//            lastServerUpdate: self.lastServerUpdate,
//            removed: self.removed
//        )
//    }
//
//    // Increments all the quantity fields (todo, done, stash) by the quantity fields of listItem
//    public func increment(_ listItem: ListItem) -> ListItem {
//        return increment(listItem.todoQuantity, doneQuantity: listItem.doneQuantity, stashQuantity: listItem.stashQuantity)
//    }
//
//    public func increment(_ todoQuantity: Int, doneQuantity: Int, stashQuantity: Int) -> ListItem {
//
//        let newTodo = self.todoQuantity + todoQuantity
//        let newDone = self.doneQuantity + doneQuantity
//        let newStash = self.stashQuantity + stashQuantity
//
//        // Sometimes got -1 in .Todo (no server involved) TODO find out why and fix, these checks shouldn't be necessary
//        if newTodo < 0 {
//            logger.e("New todo quantity: \(newTodo) for item: \(self)")
//        }
//        if newDone < 0 {
//            logger.e("New done quantity: \(newDone) for item: \(self)")
//        }
//        if newStash < 0 {
//            logger.e("New stash quantity: \(newStash) for item: \(self)")
//        }
//        let checkedTodo = max(0, newTodo)
//        let checkedDone = max(0, newDone)
//        let checkedStash = max(0, newStash)
//
//        return copy(
//            note: note,
//            todoQuantity: checkedTodo,
//            doneQuantity: checkedDone,
//            stashQuantity: checkedStash
//        )
//    }
//
//    public func increment(_ quantity: ListItemStatusQuantity) -> ListItem {
//        let increments: (todo: Int, done: Int, stash: Int) = {
//            switch quantity.status {
//                case .todo: return (quantity.quantity, 0, 0)
//                case .done: return (0, quantity.quantity, 0)
//                case .stash: return (0, 0, quantity.quantity)
//            }
//        }()
//        return increment(increments.todo, doneQuantity: increments.done, stashQuantity: increments.stash)
//    }
//
//    public func copyIncrement(uuid: String? = nil, product: StoreProduct? = nil, section: Section? = nil, list: List? = nil, note: String?, todoOrder: Int? = nil, doneOrder: Int? = nil, stashOrder: Int? = nil, statusQuantity: ListItemStatusQuantity) -> ListItem {
//
//        // returns self quantity incremented if self status is the same as statusQuantity status, or returns self quantity unchanged
//        func incr(_ selfQuantity: Int, _ selfStatus: ListItemStatus, _ statusQuantity: ListItemStatusQuantity) -> Int {
//            return statusQuantity.status == selfStatus ? (selfQuantity + statusQuantity.quantity) : selfQuantity
//        }
//
//        return copy(
//            uuid: uuid,
//            product: product,
//            section: section,
//            list: list,
//            note: note,
//            todoQuantity: incr(todoQuantity, .todo, statusQuantity),
//            todoOrder: todoOrder,
//            doneQuantity: incr(doneQuantity, .done, statusQuantity),
//            doneOrder: doneOrder,
//            stashQuantity: incr(stashQuantity, .stash, statusQuantity),
//            stashOrder: stashOrder
//        )
//    }
//
//    public func updateOrder(_ order: ListItemStatusOrder) -> ListItem {
//        return copy(
//            uuid: uuid,
//            product: product,
//            section: section,
//            list: list,
//            note: note,
//            todoQuantity: todoQuantity,
//            todoOrder: order.status == .todo ? order.order : todoOrder,
//            doneQuantity: doneQuantity,
//            doneOrder: order.status == .done ? order.order : doneOrder,
//            stashQuantity: stashQuantity,
//            stashOrder: order.status == .stash ? order.order : stashOrder
//        )
//    }
//
//    public func updateOrderMutable(_ order: ListItemStatusOrder) {
//        switch order.status {
//        case .todo: todoOrder = order.order
//        case .done: doneOrder = order.order
//        case .stash: stashOrder = order.order
//        }
//    }
//
//    public func updateQuantity(_ quantity: ListItemStatusQuantity) -> ListItem {
//        return copy(
//            uuid: uuid,
//            product: product,
//            section: section,
//            list: list,
//            note: note,
//            todoQuantity: quantity.status == .todo ? quantity.quantity : todoQuantity,
//            todoOrder: todoOrder,
//            doneQuantity: quantity.status == .done ? quantity.quantity : doneQuantity,
//            doneOrder: doneOrder,
//            stashQuantity: quantity.status == .stash ? quantity.quantity : stashQuantity,
//            stashOrder: stashOrder
//        )
//    }
//
//    // Overwrite all fields with fields of listItem, except uuid
//    public func update(_ listItem: ListItem) -> ListItem {
//        return update(listItem, storeProduct: listItem.product)
//    }
//
//    // Updates self and its dependencies with listItem, the references to the dependencies (uuid) are not changed
//    public func updateWithoutChangingReferences(_ listItem: ListItem) -> ListItem {
//        let updatedStoreProduct = product.updateWithoutChangingReferences(listItem.product)
//        return update(listItem, storeProduct: updatedStoreProduct)
//    }
//
//    fileprivate func update(_ listItem: ListItem, storeProduct: StoreProduct) -> ListItem {
//        return copy(
//            uuid: uuid,
//            product: storeProduct,
//            section: listItem.section,
//            list: listItem.list,
//            note: listItem.note,
//            todoQuantity: listItem.todoQuantity,
//            todoOrder: listItem.todoOrder,
//            doneQuantity: listItem.doneQuantity,
//            doneOrder: listItem.doneOrder,
//            stashQuantity: listItem.stashQuantity,
//            stashOrder: listItem.stashOrder
//        )
//    }
//
//    public func markAsDone() -> ListItem {
//        return copy(
//            note: note,
//            todoQuantity: 0,
//            doneQuantity: doneQuantity + todoQuantity
//        )
//    }
//
//    public func update(_ product: StoreProduct) -> ListItem {
//        return copy(product: product, note: nil)
//    }
//
//    public func update(_ product: Product) -> ListItem {
//        let updatedStoreProduct = self.product.copy(product: product)
//        return copy(product: updatedStoreProduct, note: nil)
//    }
//
//    public func switchStatusQuantity(_ status: ListItemStatus, targetStatus: ListItemStatus) -> ListItem {
//
//        func updateFieldQuantity(_ fieldStatus: ListItemStatus, status: ListItemStatus, targetStatus: ListItemStatus) -> Int {
//
//            // had to be rewriten to add bounds check, see TODO below
////            return status == fieldStatus ? 0 : (targetStatus == fieldStatus ? quantity(status) + quantity(targetStatus) : quantity(targetStatus))
//            if status == fieldStatus {
//                return 0
//
//            } else {
//                if targetStatus == fieldStatus {
//                    // Sometimes got -1 in .Todo (no server involved) TODO find out why and fix, these checks shouldn't be necessary
//                    let newQuantity = quantity(status) + quantity(targetStatus)
//                    if newQuantity < 0 {
//                        logger.e("New done quantity: \(newQuantity), status: \(status), targetStatus: \(targetStatus) for item: \(self)")
//                    }
//                    let checkedQuantity = max(0, newQuantity)
//                    return checkedQuantity
//
//                } else {
//                    return quantity(targetStatus)
//                }
//            }
//        }
//
//        return copy(
//            note: note,
//            todoQuantity: updateFieldQuantity(.todo, status: status, targetStatus: targetStatus),
//            doneQuantity: updateFieldQuantity(.done, status: status, targetStatus: targetStatus),
//            stashQuantity: updateFieldQuantity(.stash, status: status, targetStatus: targetStatus)
//        )
//    }
//
//    public static func quantityFieldName(_ status: ListItemStatus) -> String {
//        switch status {
//        case .todo: return "todoQuantity"
//        case .done: return "doneQuantity"
//        case .stash: return "stashQuantity"
//        }
//    }
//
//    public static func orderFieldName(_ status: ListItemStatus) -> String {
//        switch status {
//        case .todo: return "todoOrder"
//        case .done: return "doneOrder"
//        case .stash: return "stashOrder"
//        }
//    }
//
//    public func switchStatusQuantityMutable(_ status: ListItemStatus, targetStatus: ListItemStatus) {
//
//        // Capture variables. We have to do this because when setting the fields they reference each other, and they all need to access the previous, not new state
//        let capturedQuantity: (ListItemStatus) -> Int = {[todoQuantity, doneQuantity, stashQuantity] status  in
//            switch status {
//            case .todo: return todoQuantity
//            case .done: return doneQuantity
//            case .stash: return stashQuantity
//            }
//        }
//
//        func fieldQuantity(_ fieldStatus: ListItemStatus, status: ListItemStatus, targetStatus: ListItemStatus) -> Int {
//
//            // had to be rewriten to add bounds check, see TODO below
////            return status == fieldStatus ? 0 : (targetStatus == fieldStatus ? capturedQuantity(status) + quantity(targetStatus) : quantity(fieldStatus))
//            if status == fieldStatus {
//                return 0
//            } else {
//                if targetStatus == fieldStatus {
//                    // Sometimes got -1 in .Todo (no server involved) TODO find out why and fix, these checks shouldn't be necessary
//                    let newQuantity = capturedQuantity(status) + quantity(targetStatus)
//                    if newQuantity < 0 {
//                        logger.e("New done quantity: \(newQuantity), fieldStatus: \(fieldStatus), status: \(status), targetStatus: \(targetStatus) for item: \(self)")
//                    }
//                    let checkedQuantity = max(0, newQuantity)
//                    return checkedQuantity
//
//                } else {
//                    return quantity(fieldStatus)
//                }
//            }
//        }
//
//        todoQuantity = fieldQuantity(.todo, status: status, targetStatus: targetStatus)
//        doneQuantity = fieldQuantity(.done, status: status, targetStatus: targetStatus)
//        stashQuantity = fieldQuantity(.stash, status: status, targetStatus: targetStatus)
//    }
//
//    func equalsExcludingSyncAttributes(_ rhs: ListItem) -> Bool {
//        return uuid == rhs.uuid && product == rhs.product && section == rhs.section && list == rhs.list && note == rhs.note && todoQuantity == rhs.todoQuantity && todoOrder == rhs.todoOrder && doneQuantity == rhs.doneQuantity && doneOrder == rhs.doneOrder && stashQuantity == rhs.stashQuantity && stashOrder == rhs.stashOrder
//    }
//}
//
//
//public func ==(lhs: ListItem, rhs: ListItem) -> Bool {
//    return lhs.equalsExcludingSyncAttributes(rhs) && lhs.lastServerUpdate == rhs.lastServerUpdate && lhs.removed == rhs.removed
//}
//
//// convenience (redundant) holder to avoid having to iterate through listitems to find unique products, sections, list
//// so products, sections arrays and list are the result of extracting the unique products, sections and list from listItems array
//public typealias ListItemsWithRelations = (listItems: [ListItem], storeProducts: [StoreProduct], products: [Product], sections: [Section])
