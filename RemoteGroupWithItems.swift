//
//  RemoteGroupWithItems.swift
//  shoppin
//
//  Created by ischuetz on 28/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation

final class RemoteGroupWithItems: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {
    
    let group: RemoteGroup
    let groupItems: RemoteGroupItemsWithDependenciesNoGroup
    
    @objc required init?(response: NSHTTPURLResponse, representation: AnyObject) {
        
        let group = representation.valueForKeyPath("group")!
        self.group = RemoteGroup(response: response, representation: group)!
        
        let items = representation.valueForKeyPath("items") as! [AnyObject]
        self.groupItems = RemoteGroupItemsWithDependenciesNoGroup(response: response, representation: items)!
    }
    
    static func collection(response response: NSHTTPURLResponse, representation: AnyObject) -> [RemoteGroupWithItems] {
        var items = [RemoteGroupWithItems]()
        for obj in representation as! [AnyObject] {
            if let item = RemoteGroupWithItems(response: response, representation: obj) {
                items.append(item)
            }
            
        }
        return items
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) group: \(group), groupItems: [\(groupItems)]}"
    }
}
