//
//  RemoteListItemWithData.swift
//  shoppin
//
//  Created by ischuetz on 14/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

final class RemoteListItemWithData: ResponseObjectSerializable, DebugPrintable {
    
    let product: RemoteProduct
    let section: RemoteSection
    let list: RemoteList
    let listItem: RemoteListItem
    
    @objc required init?(response: NSHTTPURLResponse, representation: AnyObject) {
        let product: AnyObject = representation.valueForKeyPath("product")!
        self.product = RemoteProduct(response: response, representation: product)!
        
        let section: AnyObject = representation.valueForKeyPath("section")!
        self.section = RemoteSection(response: response, representation: section)!
        
        let list: AnyObject = representation.valueForKeyPath("list")!
        self.list = RemoteList(response: response, representation: list)!
        
        let listItem: AnyObject = representation.valueForKeyPath("listItem")!
        self.listItem = RemoteListItem(response: response, representation: listItem)!
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) product: [\(self.product)], list: [\(self.list)], listItem: [\(self.listItem)}"
    }
}
