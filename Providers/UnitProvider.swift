//
//  UnitProvider.swift
//  Providers
//
//  Created by Ivan Schuetz on 11/02/2017.
//
//

import UIKit
import RealmSwift

public protocol UnitProvider {

    func units(_ handler: @escaping (ProviderResult<Results<Unit>>) -> Void)
    
    func getOrCreate(name: String, _ handler: @escaping (ProviderResult<Unit>) -> Void)

    func initDefaultUnits(_ handler: @escaping (ProviderResult<[Unit]>) -> Void)
    
    func delete(name: String, _ handler: @escaping (ProviderResult<Any>) -> Void)
}
