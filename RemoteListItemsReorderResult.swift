//
//  RemoteListItemsReorderResult.swift
//  shoppin
//
//  Created by ischuetz on 27/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

struct RemoteListItemsReorderResult: ResponseObjectSerializable, CustomDebugStringConvertible {
    let sections: [RemoteSection]
    let items: [RemoteListItemReorder]
    
    init?(representation: AnyObject) {
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
    
    var debugDescription: String {
        return "{\(type(of: self)) sections: \(sections), items: \(items)}"
    }
}

