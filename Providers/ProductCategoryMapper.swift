//
//  ProductCategoryMapper.swift
//  shoppin
//
//  Created by ischuetz on 20/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

class ProductCategoryMapper {
    
    class func categoryWithRemote(_ remoteCategory: RemoteProductCategory) -> ProductCategory {
        return ProductCategory(
            uuid: remoteCategory.uuid,
            name: remoteCategory.name,
            color: remoteCategory.color,
            lastServerUpdate: remoteCategory.lastUpdate
        )
    }
    
    class func dbCategoryWithRemote(_ category: RemoteProductCategory) -> ProductCategory {
        let dbCategory = ProductCategory()
        dbCategory.uuid = category.uuid
        dbCategory.name = category.name
        dbCategory.color = category.color
        dbCategory.dirty = false
        dbCategory.lastServerUpdate = category.lastUpdate
        return dbCategory
    }
}
