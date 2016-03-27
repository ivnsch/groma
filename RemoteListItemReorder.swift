//
//  RemoteListItemReorder.swift
//  shoppin
//
//  Created by ischuetz on 27/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

struct RemoteListItemReorder: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {
    let uuid: String
    let order: Int
    let sectionUuid: String
    
    init?(representation: AnyObject) {
        guard
            let uuid = representation.valueForKeyPath("uuid") as? String,
            let order = representation.valueForKeyPath("order") as? Int,
            let sectionUuid = representation.valueForKeyPath("sectionUuid") as? String
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.uuid = uuid
        self.order = order
        self.sectionUuid = sectionUuid
    }
    
    static func collection(representation: AnyObject) -> [RemoteListItemReorder]? {
        var items = [RemoteListItemReorder]()
        for obj in representation as! [AnyObject] {
            if let item = RemoteListItemReorder(representation: obj) {
                items.append(item)
            } else {
                return nil
            }
            
        }
        return items
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) uuid: \(uuid), order: \(order), sectionUuid: \(sectionUuid)}"
    }
    
}

extension RemoteListItemReorder {

    func updateDict(dbSection: DBSection) -> [String: AnyObject] {
        return ["uuid": uuid, "order": order, "section": dbSection]
    }
}