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
            let unserializedSections = representation.valueForKeyPath("sections"),
            let sections = RemoteSection.collection(unserializedSections),
            let unserializedItems = representation.valueForKeyPath("items"),
            let items = RemoteListItemReorder.collection(unserializedItems)
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.sections = sections
        self.items = items
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) sections: \(sections), items: \(items)}"
    }
}

