//
//  RemoteSyncResult.swift
//  shoppin
//
//  Created by ischuetz on 28/07/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation
import Alamofire

class RemoteSyncResult: ResponseObjectSerializable, CustomDebugStringConvertible {
    let productCategories: [[String: AnyObject]]
    let products: [[String: AnyObject]]
    let inventories: [[String: AnyObject]]
    let inventoriesItems: [[String: AnyObject]]
    let lists: [[String: AnyObject]]
    let sections: [[String: AnyObject]]
    let listsItems: [[String: AnyObject]]
    let groups: [[String: AnyObject]]
    let groupsItems: [[String: AnyObject]]
    let history: [[String: AnyObject]]
    
    @objc required init?(representation: AnyObject) {
        self.productCategories = representation.valueForKeyPath("productCategories") as! [[String: AnyObject]]
        self.products = representation.valueForKeyPath("products") as! [[String: AnyObject]]
        self.inventories = representation.valueForKeyPath("inventories") as! [[String: AnyObject]]
        self.inventoriesItems = representation.valueForKeyPath("inventoriesItems") as! [[String: AnyObject]]
        self.lists = representation.valueForKeyPath("lists") as! [[String: AnyObject]]
        self.sections = representation.valueForKeyPath("sections") as! [[String: AnyObject]]
        self.listsItems = representation.valueForKeyPath("listsItems") as! [[String: AnyObject]]
        self.groups = representation.valueForKeyPath("groups") as! [[String: AnyObject]]
        self.groupsItems = representation.valueForKeyPath("groupsItems") as! [[String: AnyObject]]
        self.history = representation.valueForKeyPath("history") as! [[String: AnyObject]]
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) productCategories: \(productCategories), products: \(products), inventories: \(inventories)}"
    }
}