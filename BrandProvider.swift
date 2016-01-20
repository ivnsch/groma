//
//  BrandProvider.swift
//  shoppin
//
//  Created by ischuetz on 19/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation

protocol BrandProvider {

    func brands(handler: ProviderResult<[String]> -> ())
    
    func brands(range: NSRange, _ handler: ProviderResult<[String]> -> Void)
    
    func updateBrand(oldName: String, newName: String, _ handler: ProviderResult<Any> -> Void)
    
    func removeBrand(name: String, _ handler: ProviderResult<Any> -> Void)
    
    func brandsContainingText(text: String, _ handler: ProviderResult<[String]> -> Void)
}
