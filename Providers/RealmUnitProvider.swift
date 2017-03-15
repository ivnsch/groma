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
    
    func units(buyable: Bool?, _ handler: @escaping (Results<Unit>?) -> Void) {
        handler(unitsSync(buyable: buyable))
    }
    
    func initDefaultUnits(_ handler: @escaping ([Unit]?) -> Void) {
        
        // TODO different ordering for device's country - countries that don't/rarely use OZ and LB should have them at the end
        
        let defaultUnits: [Unit] = [
            Unit(uuid: UUID().uuidString, name: trans("unit_none"), id: .none, buyable: true),
            
            Unit(uuid: UUID().uuidString, name: trans("unit_g"), id: .g, buyable: true),
            Unit(uuid: UUID().uuidString, name: trans("unit_kg"), id: .kg, buyable: true),
            Unit(uuid: UUID().uuidString, name: trans("unit_liter"), id: .liter, buyable: true),
            Unit(uuid: UUID().uuidString, name: trans("unit_milliliter"), id: .milliliter, buyable: true),
            
            Unit(uuid: UUID().uuidString, name: trans("unit_ounce"), id: .ounce, buyable: true),
            Unit(uuid: UUID().uuidString, name: trans("unit_pound"), id: .pound, buyable: true),
            
            Unit(uuid: UUID().uuidString, name: trans("unit_pack"), id: .pack, buyable: true),
            
            Unit(uuid: UUID().uuidString, name: trans("unit_cup"), id: .cup, buyable: false),
            Unit(uuid: UUID().uuidString, name: trans("unit_spoon"), id: .spoon, buyable: false),
            Unit(uuid: UUID().uuidString, name: trans("unit_teaspoon"), id: .teaspoon, buyable: false),
            
            Unit(uuid: UUID().uuidString, name: trans("unit_drop"), id: .drop, buyable: false),
            Unit(uuid: UUID().uuidString, name: trans("unit_shot"), id: .shot, buyable: false),
            Unit(uuid: UUID().uuidString, name: trans("unit_pinch"), id: .pinch, buyable: false),
            
            Unit(uuid: UUID().uuidString, name: trans("unit_clove"), id: .clove, buyable: false),

            Unit(uuid: UUID().uuidString, name: trans("unit_can"), id: .can, buyable: true),
//            Unit(uuid: UUID().uuidString, name: trans("unit_bunch")), // TODO?
        ]
        
        // let's add the fractions here too because I'm too lazy to write a new method for this (should be moved to fractions provider in the future)
        let defaultFractions: [DBFraction] = [
            DBFraction(numerator: 1, denominator: 2),
            DBFraction(numerator: 1, denominator: 3),
            DBFraction(numerator: 1, denominator: 4),
            DBFraction(numerator: 1, denominator: 5),
            DBFraction(numerator: 1, denominator: 6),
            DBFraction(numerator: 1, denominator: 7),
            DBFraction(numerator: 1, denominator: 8),
            DBFraction(numerator: 2, denominator: 3),
            DBFraction(numerator: 3, denominator: 4),
        ]
        // and the base quantities too...
        let defaultBaseQuantities: [BaseQuantity] = [
            BaseQuantity(0),
            BaseQuantity(2),
            BaseQuantity(100),
            BaseQuantity(150),
            BaseQuantity(200),
            BaseQuantity(250),
            BaseQuantity(300),
            BaseQuantity(350),
            BaseQuantity(400),
            BaseQuantity(450),
            BaseQuantity(500),
            BaseQuantity(550),
            BaseQuantity(600),
            BaseQuantity(650),
            BaseQuantity(700),
            BaseQuantity(750),
            BaseQuantity(800),
            BaseQuantity(850),
            BaseQuantity(900),
            BaseQuantity(950),
        ]
        
//        let objs: [Object] = defaultUnits + defaultFractions
        
        if saveObjsSync(defaultUnits) { // needs to be in main thread, otherwise we get realm thread error when using the returned defaultUnits
            
            var fractionsSuccess = true
            for fraction in defaultFractions {
                let (success, _) = DBProv.fractionProvider.add(fraction: fraction) // We use here provider method to append to list, not only save object
                
                fractionsSuccess = fractionsSuccess && success
            }
            if !fractionsSuccess {
                QL4("Couldn't prefill some or all fractions") // only log, prefilling fractions is not critical for the app to work
            }
            
            var basesSuccess = true
            for base in defaultBaseQuantities {
                let (success, _) = DBProv.unitProvider.add(base: base) // We use here provider method to append to list, not only save object
                
                basesSuccess = basesSuccess && success
            }
            if !basesSuccess {
                QL4("Couldn't prefill some or all bases") // only log, prefilling bases is not critical for the app to work
            }
            
            
            handler(defaultUnits)
            
        } else {
            handler(nil)
        }
    }
    
    // MARK: - Sync
    
    func unitsSync(buyable: Bool?) -> Results<Unit>? {
        return loadSync(filter: buyable.map{Unit.createBuyable(buyable: $0)})
    }
    
    func unitSync(name: String) -> Unit? {
        return loadSync(filter: Unit.createFilter(name: name))?.first
    }

    func unitSync(id: UnitId) -> Unit? {
        return loadSync(filter: Unit.createFilter(id: id))?.first
    }
    
    func getOrCreateSync(name: String) -> (unit: Unit, isNew: Bool)? {
        if name.isEmpty {
            let noneUnit = unitSync(id: .none)
            if noneUnit == nil {
                QL4("Invalid state: there's no .none unit! This should never happen. Creating it again.")
                // This hasn't happened so far but as general guideline, we avoid assumptions and try to recover (with online logging of course, so we can also fix the issue)
                let newNoneUnit = Unit(uuid: UUID().uuidString, name: trans("unit_none"), id: .none, buyable: true)
                if saveObjSync(newNoneUnit) {
                    return (newNoneUnit, true)
                } else {
                    QL4("Didn't succeed creating new none unit")
                    return nil
                }
            }
            return noneUnit.map{($0, false)} ?? nil
        }
        
        if let existingUnit = unitSync(name: name) {
            return (existingUnit, false)
        } else {
            let newUnit = Unit(uuid: UUID().uuidString, name: name, id: .custom, buyable: true)
            let success = saveObjSync(newUnit)
            return success ? (newUnit, true) : nil
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
    
    func updateSync(unit: Unit, name: String, buyable: Bool) -> Bool {
        let unit = unit.copy()
        
        return doInWriteTransactionSync(realmData: nil) {realm in
            unit.name = name
            unit.buyable = buyable
            realm.add(unit, update: true)
            
            return true
        } ?? false
    }
    
    
    // MARK: - Base quantities TODO separate file
    
    func baseQuantities() -> RealmSwift.List<BaseQuantity>? {
        guard let basesContainer: BaseQuantitiesContainer = loadSync(predicate: nil)?.first else {
            QL4("Invalid state: no container")
            return nil
        }
        return basesContainer.bases
    }
    
    func findBaseQuantity(val: Float) -> BaseQuantity? {
        return withRealmSync {realm in
            return realm.objects(BaseQuantity.self).filter(BaseQuantity.createFilter(val: val)).first
        }
    }
    
    func add(base: BaseQuantity) -> (success: Bool, isNew: Bool) {
        
        if findBaseQuantity(val: base.val) != nil {
            return (true, false)
            
        } else {
            guard let basesContainer: BaseQuantitiesContainer = loadSync(predicate: nil)?.first else {
                QL4("Invalid state: no container")
                return (false, false)
            }
            
            let successMaybe = doInWriteTransactionSync {realm -> Bool in
                realm.add(base, update: true) // it's necessary to do this additionally to append, see http://stackoverflow.com/a/40595430/930450
                basesContainer.bases.append(base)
                return true
            }
            return successMaybe.map{($0, true)} ?? (false, true)
        }
    }

    func getOrCreateSync(baseQuantity: Float) -> (base: BaseQuantity, isNew: Bool)? {
        if let existingBase = findBaseQuantity(val: baseQuantity) {
            return (existingBase, false)
            
        } else {
            guard let basesContainer: BaseQuantitiesContainer = loadSync(predicate: nil)?.first else {
                QL4("Invalid state: no container")
                return nil
            }
            
            return doInWriteTransactionSync {realm in
                let newBaseQuantity = BaseQuantity(baseQuantity)
                realm.add(newBaseQuantity, update: true) // it's necessary to do this additionally to append, see http://stackoverflow.com/a/40595430/930450
                basesContainer.bases.append(newBaseQuantity)
                return (newBaseQuantity, true)
            }
        }
    }
    
    func deleteSync(baseQuantity: Float) -> Bool {
        
        return doInWriteTransactionSync(realmData: nil) {realm in
            
            let quantifiableProducts = realm.objects(QuantifiableProduct.self).filter(QuantifiableProduct.createFilter(base: baseQuantity))
            let units = realm.objects(BaseQuantity.self).filter(BaseQuantity.createFilter(val: baseQuantity))
            
            realm.delete(quantifiableProducts)
            realm.delete(units)
            
            return true
        } ?? false
    }
}
