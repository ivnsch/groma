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
    
    // NOTE that updating the name can lead to semantic inconsistency with the enum-type (e.g. someone could rename "g" in "kg" but the enum type is still g. We don't care about this for now since the enum types are only used to prefill the database, i.e. are ignored after this. For later, TODO: allow user only to update units of type .custom
    func update(unit: Unit, name: String, _ handler: @escaping (ProviderResult<Any>) -> Void)

}
