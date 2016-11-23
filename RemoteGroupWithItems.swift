//
//  RemoteGroupWithItems.swift
//  shoppin
//
//  Created by ischuetz on 28/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

struct RemoteGroupWithItems: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {
    
    let group: RemoteGroup
    let groupItems: RemoteGroupItemsWithDependenciesNoGroup
    
    init?(representation: AnyObject) {
        guard
            let groupObj = representation.value(forKeyPath: "group"),
            let group = RemoteGroup(representation: groupObj as AnyObject),
            let itemsObj = representation.value(forKeyPath: "items") as? [AnyObject],
            let groupItems = RemoteGroupItemsWithDependenciesNoGroup(representation: itemsObj as AnyObject)
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.group = group
        self.groupItems = groupItems
    }
    
    static func collection(_ representation: [AnyObject]) -> [RemoteGroupWithItems]? {
        var items = [RemoteGroupWithItems]()
        for obj in representation {
            if let item = RemoteGroupWithItems(representation: obj) {
                items.append(item)
            } else {
                return nil
            }
            
        }
        return items
    }
    
    var debugDescription: String {
        return "{\(type(of: self)) group: \(group), groupItems: [\(groupItems)]}"
    }
}
