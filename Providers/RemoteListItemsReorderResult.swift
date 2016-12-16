//
//  RemoteListItemsReorderResult.swift
//  shoppin
//
//  Created by ischuetz on 27/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

public struct RemoteListItemsReorderResult: ResponseObjectSerializable, CustomDebugStringConvertible {
    public let sections: [RemoteSection]
    public let items: [RemoteListItemReorder]
    
    public init?(representation: AnyObject) {
        guard
            let unserializedSections = representation.value(forKeyPath: "sections") as? [AnyObject],
            let sections = RemoteSection.collection(unserializedSections),
            let unserializedItems = representation.value(forKeyPath: "items") as? [AnyObject],
            let items = RemoteListItemReorder.collection(unserializedItems)
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.sections = sections
        self.items = items
    }
    
    public var debugDescription: String {
        return "{\(type(of: self)) sections: \(sections), items: \(items)}"
    }
}

