//
//  UnitProviderImpl.swift
//  Providers
//
//  Created by Ivan Schuetz on 11/02/2017.
//
//

import UIKit
import RealmSwift
import QorumLogs

class UnitProviderImpl: UnitProvider {

    func units(buyable: Bool?, _ handler: @escaping (ProviderResult<Results<Unit>>) -> Void) {
        
        DBProv.unitProvider.units(buyable: buyable) {units in
            if let units = units {
                handler(ProviderResult(status: .success, sucessResult: units))
            } else {
                handler(ProviderResult(status: .databaseUnknown))
            }
        }
    }

    func unitsContainingText(_ text: String, _ handler: @escaping (ProviderResult<Results<Unit>>) -> Void) {
        if let units = DBProv.unitProvider.unitsContainingTextSync(text) {
            handler(ProviderResult(status: .success, sucessResult: units))
        } else {
            handler(ProviderResult(status: .databaseUnknown))
        }
    }
    
    func getOrCreate(name: String, _ handler: @escaping (ProviderResult<(unit: Unit, isNew: Bool)>) -> Void) {
        if let unit = DBProv.unitProvider.getOrCreateSync(name: name) {
            handler(ProviderResult(status: .success, sucessResult: unit))
        } else {
            handler(ProviderResult(status: .databaseUnknown))
        }
    }
    
    func initDefaultUnits(_ handler: @escaping (ProviderResult<[Unit]>) -> Void) {
        
        DBProv.unitProvider.initDefaultUnits{units in
            if let units = units {
                handler(ProviderResult(status: .success, sucessResult: units))
            } else {
                handler(ProviderResult(status: .databaseUnknown))
            }
        }
    }
    
    func delete(name: String, _ handler: @escaping (ProviderResult<Any>) -> Void) {
        if DBProv.unitProvider.deleteSync(name: name) {
            handler(ProviderResult(status: .success))
        } else {
            QL4("Couldn't delete units with name: \(name)")
            handler(ProviderResult(status: .databaseUnknown))
        }
    }
    
    func update(unit: Unit, name: String, buyable: Bool, _ handler: @escaping (ProviderResult<Any>) -> Void) {
        if DBProv.unitProvider.updateSync(unit: unit, name: name, buyable: buyable) {
            handler(ProviderResult(status: .success))
        } else {
            QL4("Couldn't update unit: \(unit) with name: \(name)")
            handler(ProviderResult(status: .databaseUnknown))
        }
    }
    
    func baseQuantities(_ handler: @escaping (ProviderResult<RealmSwift.List<BaseQuantity>>) -> Void) {
        if let bases = DBProv.unitProvider.baseQuantities() {
            handler(ProviderResult(status: .success, sucessResult: bases))
        } else {
            handler(ProviderResult(status: .databaseUnknown))
        }
    }
    
    func getOrCreate(baseQuantity: Float, _ handler: @escaping (ProviderResult<(base: BaseQuantity, isNew: Bool)>) -> Void) {
        if let base = DBProv.unitProvider.getOrCreateSync(baseQuantity: baseQuantity) {
            handler(ProviderResult(status: .success, sucessResult: base))
        } else {
            handler(ProviderResult(status: .databaseUnknown))
        }
    }
    
    func delete(baseQuantity: Float, _ handler: @escaping (ProviderResult<Any>) -> Void) {
        if DBProv.unitProvider.deleteSync(baseQuantity: baseQuantity) {
            handler(ProviderResult(status: .success))
        } else {
            QL4("Couldn't delete base quantities with stringVal: \(baseQuantity)")
            handler(ProviderResult(status: .databaseUnknown))
        }
    }
}
