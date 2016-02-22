//
//  ProductCategoryMapper.swift
//  shoppin
//
//  Created by ischuetz on 20/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

class ProductCategoryMapper {
    
    class func categoryWithDB(dbCategory: DBProductCategory) -> ProductCategory {
        return ProductCategory(
            uuid: dbCategory.uuid,
            name: dbCategory.name,
            color: dbCategory.color() // TODO!!! sometimes crash here - bad access. no more message, checked with realm browser and data looks ok (but there's no way to check binary data of color is correct). Maybe store color as hex. Curious was also - added a debug print for uuid, name, colorData, all output was empty (why?). It crashed when printing colorData. Ahhh: Probably this happens when deleting products which currently doesn't delete the list items, and then accessing the list items again! It strange though because colorData has a default value.
        )
    }
    
    class func dbWithCategory(category: ProductCategory) -> DBProductCategory {
        let dbCategory = DBProductCategory()
        dbCategory.uuid = category.uuid
        dbCategory.name = category.name
        dbCategory.setColor(category.color)
        return dbCategory
    }
    
    class func categoryWithRemote(remoteCategory: RemoteProductCategory) -> ProductCategory {
        return ProductCategory(
            uuid: remoteCategory.uuid,
            name: remoteCategory.name,
            color: remoteCategory.color
        )
    }
    
    class func dbCategoryWithRemote(category: RemoteProductCategory) -> DBProductCategory {
        let dbCategory = DBProductCategory()
        dbCategory.uuid = category.uuid
        dbCategory.name = category.name
        dbCategory.setColor(category.color)
        dbCategory.dirty = false
        return dbCategory
    }
}