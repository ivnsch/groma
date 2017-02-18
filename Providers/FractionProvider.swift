//
//  FractionProvider.swift
//  Providers
//
//  Created by Ivan Schuetz on 18/02/2017.
//
//

import Foundation
import RealmSwift

public protocol FractionProvider {
    
    func fractions(_ handler: @escaping (ProviderResult<RealmSwift.List<DBFraction>>) -> Void)
    
    /// Returns true -> is a new item
    func add(fraction: DBFraction, _ handler: @escaping (ProviderResult<Bool>) -> Void)
    
    func remove(fraction: DBFraction, _ handler: @escaping (ProviderResult<Any>) -> Void)
}
