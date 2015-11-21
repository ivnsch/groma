//
//  ProductCategoryProvider.swift
//  shoppin
//
//  Created by ischuetz on 20/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

protocol ProductCategoryProvider {

    func categoryWithName(name: String, _ handler: ProviderResult<ProductCategory> -> Void)
}
