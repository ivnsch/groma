//
//  BrandProvider.swift
//  shoppin
//
//  Created by ischuetz on 19/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation

public protocol BrandProvider {

    func brandsContainingText(_ text: String, _ handler: @escaping (ProviderResult<[String]>) -> ())
    
    func brands(_ range: NSRange, _ handler: @escaping (ProviderResult<[String]>) -> Void)
    
    func updateBrand(_ oldName: String, newName: String, _ handler: @escaping (ProviderResult<Any>) -> Void)
    
    func removeProductsWithBrand(_ name: String, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> Void)
    
    func brandsContainingText(_ text: String, range: NSRange, _ handler: @escaping (ProviderResult<[String]>) -> Void)
}
