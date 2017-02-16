//
//  RealmUnitProvider.swift
//  Providers
//
//  Created by Ivan Schuetz on 11/02/2017.
//
//

import UIKit
import RealmSwift
import QorumLogs

class RealmUnitProvider: RealmProvider {
    
    func units(_ handler: @escaping (Results<Unit>?) -> Void) {
        handler(unitsSync())
    }
    
    func initDefaultUnits(_ handler: @escaping ([Unit]?) -> Void) {
    
        // TODO!!!!!!!!!!!!!!!!!!!!!!!!!! translations
        
        // TODO different ordering for device's country - countries that don't/rarely use OZ and LB should have them at the end
        
        let defaultUnits = [
            Unit(uuid: UUID().uuidString, name: trans("unit_none"), id: .none),
            
            Unit(uuid: UUID().uuidString, name: trans("unit_g"), id: .g),
            Unit(uuid: UUID().uuidString, name: trans("unit_kg"), id: .kg),
            Unit(uuid: UUID().uuidString, name: trans("unit_liter"), id: .liter),
            Unit(uuid: UUID().uuidString, name: trans("unit_milliliter"), id: .milliliter),
            
            Unit(uuid: UUID().uuidString, name: trans("unit_ounce"), id: .ounce),
            Unit(uuid: UUID().uuidString, name: trans("unit_pound"), id: .pound),
            
            Unit(uuid: UUID().uuidString, name: trans("unit_pack"), id: .pack),
            
            Unit(uuid: UUID().uuidString, name: trans("unit_cup"), id: .cup),
            Unit(uuid: UUID().uuidString, name: trans("unit_spoon"), id: .spoon),
            Unit(uuid: UUID().uuidString, name: trans("unit_teaspoon"), id: .teaspoon),
            
            Unit(uuid: UUID().uuidString, name: trans("unit_drop"), id: .drop),
            Unit(uuid: UUID().uuidString, name: trans("unit_shot"), id: .shot),
            Unit(uuid: UUID().uuidString, name: trans("unit_pinch"), id: .pinch),

//            Unit(uuid: UUID().uuidString, name: trans("unit_bunch")), // TODO?
        ]

        if saveObjsSync(defaultUnits) { // needs to be in main thread, otherwise we get realm thread error when using the returned defaultUnits
            handler(defaultUnits)
        } else {
            handler(nil)
        }
    }
    
    // MARK: - Sync
    
    func unitsSync() -> Results<Unit>? {
        return loadSync(filter: nil)
    }
    
    func unitSync(name: String) -> Unit? {
        return loadSync(filter: Unit.createFilter(name: name))?.first
    }

    func unitSync(id: UnitId) -> Unit? {
        return loadSync(filter: Unit.createFilter(id: id))?.first
    }
    
    func getOrCreateSync(name: String) -> Unit? {
        if name.isEmpty {
            let noneUnit = unitSync(id: .none)
            if noneUnit == nil {
                QL4("Invalid state: there's no .none unit! This should never happen. Creating it again.")
                // This hasn't happened so far but as general guideline, we avoid assumptions and try to recover (with online logging of course, so we can also fix the issue)
                let newNoneUnit = Unit(uuid: UUID().uuidString, name: trans("unit_none"), id: .none)
                if saveObjSync(newNoneUnit) {
                    return newNoneUnit
                } else {
                    QL4("Didn't succeed creating new none unit")
                    return nil
                }
            }
            return noneUnit
        }
        
        if let existingUnit = unitSync(name: name) {
            return existingUnit
        } else {
            let newUnit = Unit(uuid: UUID().uuidString, name: name, id: .custom)
            let success = saveObjSync(newUnit)
            return success ? newUnit : nil
        }
    }
    
    func unitsContainingTextSync(_ text: String) -> Results<Unit>? {
        return loadSync(filter: Unit.createFilterNameContains(text))
    }
    
    
    func deleteSync(name: String) -> Bool {
        
        return doInWriteTransactionSync(realmData: nil) {realm in
            
            let quantifiableProducts = realm.objects(QuantifiableProduct.self).filter(QuantifiableProduct.createFilter(unitName: name))
            let ingredients = realm.objects(Ingredient.self).filter(Ingredient.createFilter(unitName: name))
            let units = realm.objects(Unit.self).filter(Unit.createFilter(name: name))
            
            realm.delete(quantifiableProducts)
            realm.delete(ingredients)
            realm.delete(units)

            return true
        } ?? false
    }
    
    func updateSync(unit: Unit, name: String) -> Bool {
        let unit = unit.copy()
        
        return doInWriteTransactionSync(realmData: nil) {realm in
            unit.name = name
            realm.add(unit, update: true)
            
            return true
        } ?? false
    }
}
