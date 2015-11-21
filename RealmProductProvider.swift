//
//  RealmProductProvider.swift
//  shoppin
//
//  Created by ischuetz on 21/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

class RealmProductProvider: RealmProvider {

    // TODO move product methods from RealmListItemProvider here
    
    
    func categoryWithName(name: String, handler: ProductCategory? -> ()) {
        let mapper = {ProductCategoryMapper.categoryWithDB($0)}
        self.loadFirst(mapper, filter: "name = '\(name)'", handler: handler)
    }
}
