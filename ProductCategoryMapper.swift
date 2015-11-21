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
            color: dbCategory.color()
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
        return dbCategory
    }
}