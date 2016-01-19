//
//  DBListItem.swift
//  shoppin
//
//  Created by ischuetz on 14/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

class DBListItem: DBSyncable {
    
    dynamic var uuid: String = ""
    dynamic var section: DBSection = DBSection()
    dynamic var product: DBProduct = DBProduct()
    dynamic var list: DBList = DBList()
    dynamic var note: String = "" // TODO review if we can use optionals in realm, if not check if in newer version
    
    dynamic var todoQuantity: Int = 0
    dynamic var todoOrder: Int = 0
    dynamic var doneQuantity: Int = 0
    dynamic var doneOrder: Int = 0
    dynamic var stashQuantity: Int = 0
    dynamic var stashOrder: Int = 0
    
    override static func primaryKey() -> String? {
        return "uuid"
    }
    
    // Quantity of listitem in a specific status
    private func quantityForStatus(status: ListItemStatus) -> Int {
        switch status {
        case .Todo: return todoQuantity
        case .Done: return doneQuantity
        case .Stash: return stashQuantity
        }
    }

    func hasStatus(status: ListItemStatus) -> Bool {
        return quantityForStatus(status) > 0
    }
    
    func increment(quantity: ListItemStatusQuantity) {
        switch quantity.status {
        case .Todo: todoQuantity += quantity.quantity
        case .Done: doneQuantity += quantity.quantity
        case .Stash: stashQuantity += quantity.quantity
        }
    }

    static func createFilter(list: List) -> String {
        return "list.uuid == '\(list.uuid)'"
    }
    
    static func createFilter(list: List, product: Product) -> String {
        let brand = product.brand ?? ""
        return "\(createFilter(list)) && product.name == '\(product.name)' && product.brand == '\(brand)'"
    }
}
