//
//  ProductCategory.swift
//  shoppin
//
//  Created by ischuetz on 20/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

class ProductCategory: Equatable, Identifiable, CustomDebugStringConvertible {
    let uuid: String
    let name: String
    let color: UIColor
    
    //////////////////////////////////////////////
    // sync properties - FIXME - while Realm allows to return Realm objects from async op. This shouldn't be in model objects.
    // the idea is that we can return the db objs from query and then do sync directly with these objs so no need to put sync attributes in model objs
    // we could map the db objects to other db objs in order to work around the Realm issue, but this adds even more overhead, we make a lot of mappings already
    let lastServerUpdate: NSDate?
    let removed: Bool
    //////////////////////////////////////////////
    
    init(uuid: String, name: String, color: UIColor, lastServerUpdate: NSDate? = nil, removed: Bool = false) {
        self.uuid = uuid
        self.name = name
        self.color = color
        
        self.lastServerUpdate = lastServerUpdate
        self.removed = removed
    }
    
    private var shortDescription: String {
        return "{\(self.dynamicType) name: \(name)}"
    }
    
    private var longDescription: String {
        return "{\(self.dynamicType) uuid: \(uuid), name: \(name), color: \(color), lastServerUpdate: \(lastServerUpdate), removed: \(removed)}"
    }
    
    var debugDescription: String {
        return shortDescription
    }
    
    var hashValue: Int {
        return self.uuid.hashValue
    }
    
    func copy(uuid uuid: String? = nil, name: String? = nil, color: UIColor? = nil, lastServerUpdate: NSDate? = nil, removed: Bool? = nil) -> ProductCategory {
        return ProductCategory(
            uuid: uuid ?? self.uuid,
            name: name ?? self.name,
            color: color ?? self.color,
            lastServerUpdate: lastServerUpdate ?? self.lastServerUpdate,
            removed: removed ?? self.removed
        )
    }
    
    func same(rhs: ProductCategory) -> Bool {
        return uuid == rhs.uuid
    }
}

func ==(lhs: ProductCategory, rhs: ProductCategory) -> Bool {
    return lhs.uuid == rhs.uuid
}