//
//  ProductProvider.swift
//  shoppin
//
//  Created by ischuetz on 19/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

// TODO move product-only method from list item provider here
protocol ProductProvider {

    func products(handler: ProviderResult<[Product]> -> Void)
}
