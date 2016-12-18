//
//  RemoteListItemReorder.swift
//  shoppin
//
//  Created by ischuetz on 27/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

public struct RemoteListItemReorder: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {
    public let uuid: String
    public let order: Int
    public let sectionUuid: String
    
    public init?(representation: AnyObject) {
        guard
            let uuid = representation.value(forKeyPath: "uuid") as? String,
            let order = representation.value(forKeyPath: "order") as? Int,
            let sectionUuid = representation.value(forKeyPath: "sectionUuid") as? String
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.uuid = uuid
        self.order = order
        self.sectionUuid = sectionUuid
    }
    
    public static func collection(_ representation: [AnyObject]) -> [RemoteListItemReorder]? {
        var items = [RemoteListItemReorder]()
        for obj in representation {
            if let item = RemoteListItemReorder(representation: obj) {
                items.append(item)
            } else {
                return nil
            }
            
        }
        return items
    }
    
    public var debugDescription: String {
        return "{\(type(of: self)) uuid: \(uuid), order: \(order), sectionUuid: \(sectionUuid)}"
    }
    
}

public extension RemoteListItemReorder {

    func updateDict(_ status: ListItemStatus, dbSection: Section) -> [String: AnyObject] {
        return ["uuid": uuid as AnyObject, ListItem.orderFieldName(status): order as AnyObject, "sectionOpt": dbSection]
    }
}
