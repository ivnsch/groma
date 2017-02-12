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

    func units(_ handler: @escaping (ProviderResult<Results<Unit>>) -> Void) {
        
        DBProv.unitProvider.units{units in
            if let units = units {
                handler(ProviderResult(status: .success, sucessResult: units))
            } else {
                handler(ProviderResult(status: .databaseUnknown))
            }
        }
    }

    func getOrCreate(name: String, _ handler: @escaping (ProviderResult<Unit>) -> Void) {
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
}
