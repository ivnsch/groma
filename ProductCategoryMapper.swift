//
//  ProductCategoryMapper.swift
//  shoppin
//
//  Created by ischuetz on 20/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

class ProductCategoryMapper {
    
    class func categoryWithDB(_ dbCategory: DBProductCategory) -> ProductCategory {
        return ProductCategory(
            uuid: dbCategory.uuid,
            name: dbCategory.name,
            color: dbCategory.color(),
            lastServerUpdate: dbCategory.lastServerUpdate
        )
    }
    
    class func dbWithCategory(_ category: ProductCategory) -> DBProductCategory {
        let dbCategory = DBProductCategory()
        dbCategory.uuid = category.uuid
        dbCategory.name = category.name
        dbCategory.setColor(category.color)
        if let lastServerUpdate = category.lastServerUpdate {
            dbCategory.lastServerUpdate = lastServerUpdate
        }
        return dbCategory
    }
    
    class func categoryWithRemote(_ remoteCategory: RemoteProductCategory) -> ProductCategory {
        return ProductCategory(
            uuid: remoteCategory.uuid,
            name: remoteCategory.name,
            color: remoteCategory.color,
            lastServerUpdate: remoteCategory.lastUpdate
        )
    }
    
    class func dbCategoryWithRemote(_ category: RemoteProductCategory) -> DBProductCategory {
        let dbCategory = DBProductCategory()
        dbCategory.uuid = category.uuid
        dbCategory.name = category.name
        dbCategory.setColor(category.color)
        dbCategory.dirty = false
        dbCategory.lastServerUpdate = category.lastUpdate
        return dbCategory
    }
}
