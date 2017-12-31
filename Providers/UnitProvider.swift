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

    // Buyable true/false: filter by buyable, nil: don't filter by buyable
    func units(buyable: Bool?, _ handler: @escaping (ProviderResult<Results<Unit>>) -> Void)
    
    func unitsContainingText(_ text: String, _ handler: @escaping (ProviderResult<Results<Unit>>) -> Void)

    func findUnit(name: String, _ handler: @escaping (ProviderResult<Unit?>) -> Void)

    func getOrCreate(name: String, _ handler: @escaping (ProviderResult<(unit: Unit, isNew: Bool)>) -> Void)

    func initDefaultUnits(_ handler: @escaping (ProviderResult<[Unit]>) -> Void)
    
    func delete(name: String, _ handler: @escaping (ProviderResult<Any>) -> Void)
    
    // NOTE that updating the name can lead to semantic inconsistency with the enum-type (e.g. someone could rename "g" in "kg" but the enum type is still g. We don't care about this for now since the enum types are only used to prefill the database, i.e. are ignored after this. For later, TODO: allow user only to update units of type .custom
    func update(unit: Unit, name: String, buyable: Bool, _ handler: @escaping (ProviderResult<Any>) -> Void)

    
    // TODO separate base quantity provider
    
    func baseQuantities(_ handler: @escaping (ProviderResult<RealmSwift.List<BaseQuantity>>) -> Void)
    
    func getOrCreate(baseQuantity: Float, _ handler: @escaping (ProviderResult<(base: BaseQuantity, isNew: Bool)>) -> Void)

    func addUnit(unitId: UnitId, name: String, buyable: Bool, units: RealmSwift.List<Unit>?, _ handler: @escaping (ProviderResult<Unit>) -> Void)

    func restorePredefinedUnits(_ handler: @escaping (ProviderResult<Any>) -> Void)

    func delete(baseQuantity: Float, _ handler: @escaping (ProviderResult<Any>) -> Void)
}
