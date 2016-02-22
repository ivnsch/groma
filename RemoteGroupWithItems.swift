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
            let groupObj = representation.valueForKeyPath("group"),
            let group = RemoteGroup(representation: groupObj),
            let itemsObj = representation.valueForKeyPath("items") as? [AnyObject],
            let groupItems = RemoteGroupItemsWithDependenciesNoGroup(representation: itemsObj)
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.group = group
        self.groupItems = groupItems
    }
    
    static func collection(representation: AnyObject) -> [RemoteGroupWithItems]? {
        var items = [RemoteGroupWithItems]()
        for obj in representation as! [AnyObject] {
            if let item = RemoteGroupWithItems(representation: obj) {
                items.append(item)
            } else {
                return nil
            }
            
        }
        return items
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) group: \(group), groupItems: [\(groupItems)]}"
    }
}
