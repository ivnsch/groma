//
//  RealmUnitProvider.swift
//  Providers
//
//  Created by Ivan Schuetz on 11/02/2017.
//
//

import UIKit
import RealmSwift


class RealmUnitProvider: RealmProvider {
    
    func units(buyable: Bool?, _ handler: @escaping (Results<Unit>?) -> Void) {
        handler(unitsSync(buyable: buyable))
    }
    
    func initDefaultUnits(_ handler: @escaping ([Unit]?) -> Void) {
        
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
            BaseQuantity(1),
            BaseQuantity(1.5),
            BaseQuantity(2),
            BaseQuantity(4),
            BaseQuantity(6),
            BaseQuantity(12),
            BaseQuantity(500),
            BaseQuantity(750)
        ]
        
//        let objs: [Object] = defaultUnits + defaultFractions

        let (savedSuccess, units) = savePredefinedUnitsSync(update: false)
        if savedSuccess { // needs to be in main thread, otherwise we get realm thread error when using the returned defaultUnits

            var fractionsSuccess = true
            for fraction in defaultFractions {
                let (success, _) = DBProv.fractionProvider.add(fraction: fraction) // We use here provider method to append to list, not only save object
                
                fractionsSuccess = fractionsSuccess && success
            }
            if !fractionsSuccess {
                logger.e("Couldn't prefill some or all fractions") // only log, prefilling fractions is not critical for the app to work
            }
            
            var basesSuccess = true
            for base in defaultBaseQuantities {
                let (success, _) = DBProv.unitProvider.add(base: base) // We use here provider method to append to list, not only save object
                
                basesSuccess = basesSuccess && success
            }
            if !basesSuccess {
                logger.e("Couldn't prefill some or all bases") // only log, prefilling bases is not critical for the app to work
            }
            
            
            handler(units)
            
        } else {
            handler(nil)
        }
    }

    fileprivate var predefinedUnits: [Unit] {
        return [
            Unit(uuid: UUID().uuidString, name: trans("unit_unit"), id: .none, buyable: true),

            Unit(uuid: UUID().uuidString, name: trans("unit_g"), id: .g, buyable: true),
            Unit(uuid: UUID().uuidString, name: trans("unit_kg"), id: .kg, buyable: true),
            Unit(uuid: UUID().uuidString, name: trans("unit_liter"), id: .liter, buyable: true),
            Unit(uuid: UUID().uuidString, name: trans("unit_milliliter"), id: .milliliter, buyable: true),

            Unit(uuid: UUID().uuidString, name: trans("unit_pack"), id: .pack, buyable: true),

            Unit(uuid: UUID().uuidString, name: trans("unit_cup"), id: .cup, buyable: false),
            Unit(uuid: UUID().uuidString, name: trans("unit_spoon"), id: .spoon, buyable: false),
            Unit(uuid: UUID().uuidString, name: trans("unit_teaspoon"), id: .teaspoon, buyable: false),

            Unit(uuid: UUID().uuidString, name: trans("unit_drop"), id: .drop, buyable: false),
            Unit(uuid: UUID().uuidString, name: trans("unit_shot"), id: .shot, buyable: false),
            Unit(uuid: UUID().uuidString, name: trans("unit_pinch"), id: .pinch, buyable: false),

            Unit(uuid: UUID().uuidString, name: trans("unit_clove"), id: .clove, buyable: false),

            Unit(uuid: UUID().uuidString, name: trans("unit_can"), id: .can, buyable: true),

            Unit(uuid: UUID().uuidString, name: trans("unit_pint"), id: .pint, buyable: false),
            Unit(uuid: UUID().uuidString, name: trans("unit_gin"), id: .gin, buyable: true),
            Unit(uuid: UUID().uuidString, name: trans("unit_floz"), id: .floz, buyable: false),
            Unit(uuid: UUID().uuidString, name: trans("unit_dash"), id: .dash, buyable: false),
            Unit(uuid: UUID().uuidString, name: trans("unit_wgf"), id: .wgf, buyable: false),
            Unit(uuid: UUID().uuidString, name: trans("unit_dram"), id: .dram, buyable: true),
            Unit(uuid: UUID().uuidString, name: trans("unit_lb"), id: .lb, buyable: true),
            Unit(uuid: UUID().uuidString, name: trans("unit_oz"), id: .oz, buyable: true),
        ]
    }

    func savePredefinedUnitsSync(update: Bool) -> (saved: Bool, units: [Unit]) {
        guard let unitsContainer: UnitsContainer = loadSync(predicate: nil)?.first else {
            logger.e("Invalid state: no container")
            return (false, [])
        }

        let predefinedUnits = self.predefinedUnits
        var storedUnits: [Unit] = []

        if update {
            for predefinedUnit in predefinedUnits {
                if let storedUnit = addIfNotExistsSync(unit: predefinedUnit, units: unitsContainer.units) {
                    storedUnits.append(storedUnit)
                }
            }
            return (true, storedUnits)
        } else {
            for predefinedUnit in predefinedUnits {
                if let unit = addUnitSync(unit: predefinedUnit, units: unitsContainer.units){
                    storedUnits.append(unit)
                }
            }

            return (saveObjsSync(predefinedUnits, update: true), // needs to be in main thread, otherwise we get realm thread error when using the returned defaultUnits
                predefinedUnits)
        }
    }

    func addUnit(unitId: UnitId, name: String, buyable: Bool, units: RealmSwift.List<Unit>, _ handler: (Unit?) -> Void) {
        handler(addUnitSync(unitId: unitId, name: name, buyable: buyable, units: units))
    }

    func addUnitSync(unitId: UnitId, name: String, buyable: Bool, units: RealmSwift.List<Unit>?) -> Unit? {
        let finalUnitsMaybe: RealmSwift.List<Unit>? = units ?? {
            let unitsContainer: UnitsContainer? = loadSync(predicate: nil)?.first
            return unitsContainer?.units
        } ()

        guard let finalUnits = finalUnitsMaybe else {
            logger.e("Couldn't retrieve units container!", .db)
            return nil
        }

        let unit = Unit(uuid: UUID().uuidString, name: name, id: unitId, buyable: false)
        return addUnitSync(unit: unit, units: finalUnits)
    }

    fileprivate func addUnitSync(unit: Unit, units: RealmSwift.List<Unit>) -> Unit? {
        return doInWriteTransactionSync {realm -> Unit in
            realm.add(unit, update: true) // it's necessary to do this additionally to append, see http://stackoverflow.com/a/40595430/930450
            units.append(unit)
            return unit
        }
    }

    func addIfNotExistsSync(unit: Unit, units: RealmSwift.List<Unit>) -> Unit? {
        if let storedUnit = findUnit(name: unit.name) {
            return storedUnit
        } else {
            return addUnitSync(unit: unit, units: units)
        }
    }

    func findUnit(name: String, handler: (Unit?) -> Void) {
        handler(findUnit(name: name))
    }

    // MARK: - Sync

    func findUnit(name: String) -> Unit? {
        return loadFirstSync(filter: Unit.createFilter(name: name))
    }

    func unitsSync(buyable: Bool?) -> Results<Unit>? {
        guard let units = unitsList() else { logger.e("Couldn't get list"); return nil }
        if let filter = (buyable.map{ Unit.createBuyable(buyable: $0) }) {
            return units.filter(filter)
        } else {
            return units.filter(Unit.createAlwaysTrueFilter())
        }
    }

    fileprivate func unitsList() -> RealmSwift.List<Unit>? {
        guard let unitsContainer: UnitsContainer = loadSync(predicate: nil)?.first else {
            logger.e("Invalid state: no container")
            return nil
        }

        return unitsContainer.units
    }

    func unitSync(name: String) -> Unit? {
        guard let units = unitsList() else { logger.e("Couldn't get list"); return nil }
        return units.filter(Unit.createFilter(name: name)).first
    }

    func unitSync(id: UnitId) -> Unit? {
        guard let units = unitsList() else { logger.e("Couldn't get list"); return nil }
        return units.filter(Unit.createFilter(id: id)).first
    }
    
    func getOrCreateSync(name: String, realmData: RealmData? = nil, doTransaction: Bool = true) -> (unit: Unit, isNew: Bool)? {
        if name.isEmpty {
            let noneUnit = unitSync(id: .none)
            if noneUnit == nil {
                logger.e("Invalid state: there's no .none unit! This should never happen. Creating it again.")
                // This hasn't happened so far but as general guideline, we avoid assumptions and try to recover (with online logging of course, so we can also fix the issue)
                let newNoneUnit = Unit(uuid: UUID().uuidString, name: trans("unit_none"), id: .none, buyable: true)
                if saveObjSync(newNoneUnit) {
                    return (newNoneUnit, true)
                } else {
                    logger.e("Didn't succeed creating new none unit")
                    return nil
                }
            }
            return noneUnit.map{($0, false)} ?? nil
        }
        
        if let existingUnit = unitSync(name: name) {
            return (existingUnit, false)
        } else {
            let newUnit = Unit(uuid: UUID().uuidString, name: name, id: .custom, buyable: true)
            func transactionContent(realm: Realm) -> (unit: Unit, isNew: Bool)? {
                realm.add(newUnit, update: true) // should be update: false but why not use true if it's safer
                return (newUnit, true)
            }
            if doTransaction {
                return doInWriteTransactionSync(withoutNotifying: realmData.map{[$0.token]} ?? [], realm: nil) {realm in
                    return transactionContent(realm: realm)
                }
            } else {
                do {
                    let realm = try RealmConfig.realm()
                    return transactionContent(realm: realm)
                } catch (let e) {
                    logger.e("Error creating default realm: \(e)")
                    return nil
                }
            }
        }
    }
    
    func unitsContainingTextSync(_ text: String) -> Results<Unit>? {
        let filterMaybe: String? = text.isEmpty ? nil : Unit.createFilterNameContains(text)
        return loadSync(filter: filterMaybe)
    }
    
    
    func deleteSync(name: String) -> Bool {

        // TODO# delete store products and list items too!
        return doInWriteTransactionSync(realmData: nil) {realm in
            
            let quantifiableProducts = realm.objects(QuantifiableProduct.self).filter(QuantifiableProduct.createFilter(unitName: name))
            let ingredients = realm.objects(Ingredient.self).filter(Ingredient.createFilter(unitName: name))
            let units = realm.objects(Unit.self).filter(Unit.createFilter(name: name))

            let quantifiableProductsIds: [String] = quantifiableProducts.map { $0.uuid }
            let storeProducts = realm.objects(StoreProduct.self).filter(StoreProduct.createFilter(quantifiableProductUuids: quantifiableProductsIds))

            let storeProductsIds: [String] = storeProducts.map { $0.uuid }
            let listItems = realm.objects(ListItem.self).filter(ListItem.createFilterWithStoreProducts(storeProductsIds))

            let historyItems = realm.objects(HistoryItem.self).filter(HistoryItem.createFilter(quantifiableProductUuids: quantifiableProductsIds))

            realm.delete(historyItems)
            realm.delete(listItems)
            realm.delete(storeProducts)
            realm.delete(quantifiableProducts)
            realm.delete(ingredients)
            realm.delete(units)

            return true
        } ?? false
    }
    
    func updateSync(unit: Unit, name: String, buyable: Bool) -> Bool {
        let unit: Unit = unit.copy()
        
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
            logger.e("Invalid state: no container")
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
                logger.e("Invalid state: no container")
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
                logger.e("Invalid state: no container")
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
