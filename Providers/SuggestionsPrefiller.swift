//
//  SuggestionsPrefiller.swift
//  shoppin
//
//  Created by ischuetz on 24/09/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift
import QorumLogs
import ChameleonFramework

public class SuggestionsPrefiller {

    fileprivate let dbProvider = RealmProductProvider()

    public init() {}
    
    // Used to init database. This is meant to be called when the app starts.
    public func prefill(_ lang: String, onFinished: @escaping ((success: Bool, defaultUnits: [Unit])) -> Void) {
        prefill(lang) {(tuplesMaybe: (categories: [ProductCategory], products: [QuantifiableProduct], defaultUnits: [Unit])?) in
            if let tuples = tuplesMaybe {
                onFinished((success: true, defaultUnits: tuples.defaultUnits))
                
            } else {
                onFinished((success: false, defaultUnits: []))
            }
            
        }
    }

    public func prefill(_ lang: String, onFinished: @escaping ((categories: [ProductCategory], products: [QuantifiableProduct], defaultUnits: [Unit])?) -> Void) {
        Prov.unitProvider.initDefaultUnits {[weak self] result in guard let weakSelf = self else {return}
            
            if let defaultUnits = result.sucessResult {
                let (categories, products) = weakSelf.prefillProducts(lang, defaultUnits: defaultUnits)
                weakSelf.dbProvider.save(categories, dbProducts: products) {saved in
                    onFinished((categories, products, defaultUnits))
                }
                
            } else {
                QL4("Error initializing default units, can't prefill database!")
                onFinished(nil)
            }
            
        }
    }
//    /**
//    *
//    * NOTE: Not used anymore because prefill database is not usable without replacing the uuids at runtime and this turns to be a bit tricky and not good performance so now we do everything at runtime.
//    *
//    * Generates the prefill Realm file.
//    * When it's done, add the generated file to build phases > copy bundle resources, in target where it's needed.
//    * The apps will prefill the database with it in the first launch.
//    *
//    * This is not meant to be called during normal execution.
//    */
//    public func prefill(_ onFinished: VoidFunction? = nil) {
//
//        func prefill(_ lang: String, onFinished: @escaping VoidFunction) {
//            let (categories, products) = prefillProducts(lang)
//            //        printStringsForTranslations(categories, products: products)
//            dbProvider.save(categories, dbProducts: products) {[weak self] saved in
//
//                self?.writeDBCopy(NSHomeDirectory() + "/Documents/prefill\(lang).realm")
//                print("Finished prefilling lang: \(lang)")
//                
//                // After copy, clear the default db such that it's not included in the next languages
//                self?.dbProvider.removeAllProductsAndCategories {success in
//                    
//                    if !success { // Note this doesn't interrupt the operation
//                        print("Error: dbProvider.removeAllProductsAndCategories, not success clearing: \(lang)")
//                    }
//                    
//                    onFinished()
//                }
//            }
//        }
//        
//        let langs = LangManager().availableLangs
//
//        func prefillRec(_ index: Int) {
//            guard index < langs.count else {
//                onFinished?()
//                return
//            }
//            
//            prefill(langs[index]) {
//                prefillRec(index + 1)
//            }
//        }
//        
//        prefillRec(0)
//    }
//    
    fileprivate func writeDBCopy(_ toPath: String) {
//
//        if let fromPath = Realm.Configuration.defaultConfiguration.path {
//            do {
//                try Realm().writeCopyToPath(toPath)
//                print("Copied realm from path: \(fromPath), toPath: \(toPath)")
//
//            } catch let error as NSError {
//                print("Error copying realm: \(error)")
//            } catch _ {
//                print("Error copying realm")
//            }
//        } else {
//            print("Error copying realm - no path")
//        }
    }

    fileprivate var uuid: String {
        return UUID().uuidString
    }
    
    func prefillProducts(_ lang: String, defaultUnits: [Unit]) -> (categories: [ProductCategory], products: [QuantifiableProduct]) {

        let unitDict = defaultUnits.toDictionary {defaultUnit in
            (defaultUnit.id, defaultUnit)
        }
        
        /// TODO!!!!!!!!! think about restore prefill products (from settings) - at this point (after we allow user to delete units) it may be possible that there are no .g or .kg. We can either don't allow to delete the default units (at least some of them) or don't allow to delete only noneUnit - or when we are here, if the units don't exist, re-create them (the later sounds to be the most reasonable)
        guard let g = unitDict[.g] else {QL4("No g unit! can't prefill."); return ([], [])}
        guard let kg = unitDict[.kg] else {QL4("No kg unit! can't prefill."); return ([], [])}
        guard let l = unitDict[.liter] else {QL4("No l unit! can't prefill."); return ([], [])}
        guard let ml = unitDict[.milliliter] else {QL4("No ml unit! can't prefill."); return ([], [])}
        guard let noneUnit = unitDict[.none] else {QL4("No none unit! can't prefill."); return ([], [])}
        
        func noResult() -> (categories: [ProductCategory], products: [QuantifiableProduct]) {
            return (categories: [], products: [])
        }
        
        guard let path = Bundle.main.path(forResource: lang, ofType: "lproj") else {QL4("No path for lang: \(lang)"); return noResult()}
        guard let bundle = Bundle(path: path) else {QL4("No bundle for path: \(path)"); return noResult()}
        
        func tr(_ key: String, _ lang: String) -> String {
            return bundle.localizedString(forKey: key, value: nil, table: nil)
        }
        
        let fruitsCat = ProductCategory(uuid: uuid, name: tr("pr_fruits", lang), color: UIColor.flatRed.hexStr)
        let frozenFruitsCat = ProductCategory(uuid: uuid, name: tr("pr_fruits_frozen", lang), color: UIColor.flatBlue.hexStr)
        let vegetablesCat = ProductCategory(uuid: uuid, name: tr("pr_vegetables", lang), color: UIColor.flatGreen.hexStr)
        let herbsCat = ProductCategory(uuid: uuid, name: tr("pr_herbs", lang), color: UIColor.flatGreenDark.hexStr)
        let meatCat = ProductCategory(uuid: uuid, name: tr("pr_meat", lang), color: UIColor.flatRedDark.hexStr)
        let petsCat = ProductCategory(uuid: uuid, name: tr("pr_pets", lang), color: UIColor.flatPowderBlue.hexStr)
        let bakeryCat = ProductCategory(uuid: uuid, name: tr("pr_bakery", lang), color: UIColor.flatTeal.hexStr)
        let riceCat = ProductCategory(uuid: uuid, name: tr("pr_rice", lang), color: UIColor.flatGray.hexStr)
        let nutsCat = ProductCategory(uuid: uuid, name: tr("pr_nuts", lang), color: UIColor.flatBrown.hexStr)
        let oilCat = ProductCategory(uuid: uuid, name: tr("pr_oil", lang), color: UIColor.flatForestGreen.hexStr)
        let clothesCat = ProductCategory(uuid: uuid, name: tr("pr_clothes", lang), color: UIColor.flatBlueDark.hexStr)
        let cleaningCat = ProductCategory(uuid: uuid, name: tr("pr_cleaning", lang), color: UIColor.flatMagenta.hexStr)
        
        let milkCat = ProductCategory(uuid: uuid, name: tr("pr_milk", lang), color: UIColor.flatWhiteDark.hexStr)
        
        let fishCat = ProductCategory(uuid: uuid, name: tr("pr_fish", lang), color: UIColor.flatBlueDark.hexStr)
        let pastaCat = ProductCategory(uuid: uuid, name: tr("pr_pasta", lang), color: UIColor.flatSandDark.hexStr)
        let drinksCat = ProductCategory(uuid: uuid, name: tr("pr_drinks", lang), color: UIColor.flatBlue.lighten(byPercentage: 0.5)?.hexStr ?? "000000")
        let alcoholCat = ProductCategory(uuid: uuid, name: tr("pr_alcohol", lang), color: UIColor.flatPurpleDark.hexStr)
        let hygienicCat = ProductCategory(uuid: uuid, name: tr("pr_hygienic", lang), color: UIColor.flatMint.hexStr)
        let dipsCat = ProductCategory(uuid: uuid, name: tr("pr_dips", lang), color: UIColor.flatMintDark.hexStr)
        let spicesCat = ProductCategory(uuid: uuid, name: tr("pr_spices", lang), color: UIColor.flatBlack.hexStr)
        let friedCat = ProductCategory(uuid: uuid, name: tr("pr_fried", lang), color: UIColor.flatMaroon.hexStr)
        let breadCat = ProductCategory(uuid: uuid, name: tr("pr_bread", lang), color: UIColor.flatYellowDark.hexStr)
        let sweetsCat = ProductCategory(uuid: uuid, name: tr("pr_sweets", lang), color: UIColor.flatPink.hexStr)
        let teaAndCoffeeCat = ProductCategory(uuid: uuid, name: tr("pr_tea_coffee", lang), color: UIColor.flatBrown.hexStr)
        let cheeseCat = ProductCategory(uuid: uuid, name: tr("pr_cheese", lang), color: UIColor.flatYellow.hexStr)
        let beansCat = ProductCategory(uuid: uuid, name: tr("pr_beans", lang), color: UIColor.flatRedDark.hexStr)
        let eggsCat = ProductCategory(uuid: uuid, name: tr("pr_eggs", lang), color: UIColor.flatNavyBlue.hexStr)
        let spreadCat = ProductCategory(uuid: uuid, name: tr("pr_spread", lang), color: UIColor.flatPlum.hexStr)
        let cerealCat = ProductCategory(uuid: uuid, name: tr("pr_cereal", lang), color: UIColor.flatOrange.hexStr)
        let coldCutCat = ProductCategory(uuid: uuid, name: tr("pr_cold_cut", lang), color: UIColor.flatOrangeDark.hexStr)
        let ovenCat = ProductCategory(uuid: uuid, name: tr("pr_oven", lang), color: UIColor.flatWatermelonDark.hexStr)
        let stationeriesCat = ProductCategory(uuid: uuid, name: tr("pr_stationeries", lang), color: UIColor.flatNavyBlueDark.hexStr)

        
        let quantifiableProducts: [QuantifiableProduct] = [
            // fruits
            
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_peaches", lang), category: fruitsCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_bananas", lang), category: fruitsCat)),
            
            
            
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_apples", lang), category: fruitsCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_nectarines", lang), category: fruitsCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 500, unit: g, product: Product(uuid: uuid, name: tr("pr_cherries", lang), category: fruitsCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_kiwis", lang), category: fruitsCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_melons", lang), category: fruitsCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_watermelons", lang), category: fruitsCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_lemons", lang), category: fruitsCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 500, unit: g, product: Product(uuid: uuid, name: tr("pr_grapes", lang), category: fruitsCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_oranges", lang), category: fruitsCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_mandarines", lang), category: fruitsCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 500, unit: g, product: Product(uuid: uuid, name: tr("pr_strawberries", lang), category: fruitsCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 250, unit: g, product: Product(uuid: uuid, name: tr("pr_blueberries", lang), category: fruitsCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 250, unit: g, product: Product(uuid: uuid, name: tr("pr_cranberries", lang), category: fruitsCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_grapefruits", lang), category: fruitsCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_mangos", lang), category: fruitsCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_limes", lang), category: fruitsCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_pomegranate", lang), category: fruitsCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_pineapple", lang), category: fruitsCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 500, unit: g, product: Product(uuid: uuid, name: tr("pr_plums", lang), category: fruitsCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 500, unit: g, product: Product(uuid: uuid, name: tr("pr_tomatoes", lang), category: fruitsCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 250, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_olives", lang), category: fruitsCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 400, unit: g, product: Product(uuid: uuid, name: tr("pr_tomatoes_peeled", lang), category: fruitsCat)),
            
            // frozen fruits
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_strawberries_frozen", lang), category: frozenFruitsCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_blueberries_frozen", lang), category: frozenFruitsCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_cranberries_frozen", lang), category: frozenFruitsCat)),
            
            // vegetables
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: kg, product: Product(uuid: uuid, name: tr("pr_onions", lang), category: vegetablesCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: kg, product: Product(uuid: uuid, name: tr("pr_onions_red", lang), category: vegetablesCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: kg, product: Product(uuid: uuid, name: tr("pr_potatoes", lang), category: vegetablesCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_salad", lang), category: vegetablesCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_paprika", lang), category: vegetablesCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_garlic", lang), category: vegetablesCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: kg, product: Product(uuid: uuid, name: tr("pr_carrots", lang), category: vegetablesCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 500, unit: g, product: Product(uuid: uuid, name: tr("pr_asparagus", lang), category: vegetablesCat)),
            //            Product(uuid: uuid, name: tr("pr_dumplings", lang), category: vegetablesCat)),
            //            Product(uuid: uuid, name: tr("pr_mashed_potatoes", lang), category: vegetablesCat)),
            
            // herbs (fresh/dry)
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_parsley", lang), category: herbsCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_basil", lang), category: herbsCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_mint", lang), category: herbsCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_coriander", lang), category: herbsCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_cardamom", lang), category: herbsCat)),
            
            // meat
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 500, unit: g, product: Product(uuid: uuid, name: tr("pr_chicken", lang), category: meatCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 500, unit: g, product: Product(uuid: uuid, name: tr("pr_drum_sticks", lang), category: meatCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 500, unit: g, product: Product(uuid: uuid, name: tr("pr_chicken_wings", lang), category: meatCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 500, unit: g, product: Product(uuid: uuid, name: tr("pr_chops", lang), category: meatCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_beef_steak", lang), category: meatCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_beef", lang), category: meatCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: g, product: Product(uuid: uuid, name: tr("pr_duck", lang), category: meatCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_turkey", lang), category: meatCat)),
            
            // pets
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 2.5, unit: kg, product: Product(uuid: uuid, name: tr("pr_litter", lang), category: petsCat)),
            
            // spices
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_pepper", lang), category: spicesCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_pepper_red", lang), category: spicesCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 500, unit: g, product: Product(uuid: uuid, name: tr("pr_salt", lang), category: spicesCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: kg, product: Product(uuid: uuid, name: tr("pr_sugar", lang), category: spicesCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 250, unit: g, product: Product(uuid: uuid, name: tr("pr_cinnamon", lang), category: spicesCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 100, unit: g, product: Product(uuid: uuid, name: tr("pr_chili", lang), category: spicesCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 200, unit: ml, product: Product(uuid: uuid, name: tr("pr_chicken_broth", lang), category: spicesCat)),

            // bakery
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: kg, product: Product(uuid: uuid, name: tr("pr_flour", lang), category: bakeryCat)),
            
            // pasta
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 500, unit: g, product: Product(uuid: uuid, name: tr("pr_spaguetti", lang), category: pastaCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 500, unit: g, product: Product(uuid: uuid, name: tr("pr_noodles", lang), category: pastaCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 500, unit: g, product: Product(uuid: uuid, name: tr("pr_ravioli", lang), category: pastaCat)),
            
            // rice
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: kg, product: Product(uuid: uuid, name: tr("pr_rice", lang), category: riceCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: kg, product: Product(uuid: uuid, name: tr("pr_rice_basmati", lang), category: riceCat)),
            
            // drinks
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_water", lang), category: drinksCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: l, product: Product(uuid: uuid, name: tr("pr_water_1", lang), category: drinksCat)),// TODO!!!!!!! liter unit
            //            Product(uuid: uuid, name: tr("pr_club_mate", lang), category: drinksCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: l, product: Product(uuid: uuid, name: tr("pr_cola", lang), category: drinksCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1.5, unit: l, product: Product(uuid: uuid, name: tr("pr_cola", lang), category: drinksCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 2, unit: l, product: Product(uuid: uuid, name: tr("pr_cola", lang), category: drinksCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: l, product: Product(uuid: uuid, name: tr("pr_fanta", lang), category: drinksCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1.5, unit: l, product: Product(uuid: uuid, name: tr("pr_fanta", lang), category: drinksCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 2, unit: l, product: Product(uuid: uuid, name: tr("pr_fanta", lang), category: drinksCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: l, product: Product(uuid: uuid, name: tr("pr_sprite", lang), category: drinksCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1.5, unit: l, product: Product(uuid: uuid, name: tr("pr_sprite", lang), category: drinksCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 2, unit: l, product: Product(uuid: uuid, name: tr("pr_sprite", lang), category: drinksCat)),
            
            // alcohol
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 0.5, unit: l, product: Product(uuid: uuid, name: tr("pr_beer", lang), category: alcoholCat)), // TODO!!!!!!! liter unit
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_whisky", lang), category: alcoholCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_vodka", lang), category: alcoholCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_tequilla", lang), category: alcoholCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_rum", lang), category: alcoholCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_wine_red", lang), category: alcoholCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_wine_white", lang), category: alcoholCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_sherry", lang), category: alcoholCat)),
            
            // nuts
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 150, unit: g, product: Product(uuid: uuid, name: tr("pr_nuts", lang), category: nutsCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 150, unit: g, product: Product(uuid: uuid, name: tr("pr_pine_nuts", lang), category: nutsCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 200, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_hazel_nuts", lang), category: nutsCat)),
            
            // oil
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_oil", lang), category: oilCat)), // TODO!!!!!!! liter unit
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_oil_olives", lang), category: oilCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_oil_sunflower", lang), category: oilCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_oil_rapeseed", lang), category: oilCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_oil_margarine", lang), category: oilCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_oil_butter", lang), category: oilCat)),
            
            // hygienic
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_soap_body", lang), category: hygienicCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_soap_hands", lang), category: hygienicCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_shampoo", lang), category: hygienicCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_toothpaste", lang), category: hygienicCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_deodorant", lang), category: hygienicCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_tooth_brush", lang), category: hygienicCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_listerine", lang), category: hygienicCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_dental_floss", lang), category: hygienicCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_cotton", lang), category: hygienicCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_cotton_buds", lang), category: hygienicCat)),
            //            Product(uuid: uuid, name: tr("pr_diapers", lang), category: hygienicCat)),
            //            Product(uuid: uuid, name: tr("pr_sanitary_towel", lang), category: hygienicCat)),
            //            Product(uuid: uuid, name: tr("pr_tampons", lang), category: hygienicCat)),
            //            Product(uuid: uuid, name: tr("pr_razors", lang), category: hygienicCat)),
            //            Product(uuid: uuid, name: tr("pr_shaving_cream", lang), category: hygienicCat)),
            
            // clothes
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_socks", lang), category: clothesCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_tshirts", lang), category: clothesCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_underwear", lang), category: clothesCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_pants", lang), category: clothesCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_shoes", lang), category: clothesCat)),
            
            // cleaning
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_cleaning_agent", lang), category: cleaningCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_cleaning_agent_toilet", lang), category: cleaningCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_cleaning_agent_windows", lang), category: cleaningCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_sponge", lang), category: cleaningCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_sponge_wire", lang), category: cleaningCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_mop", lang), category: cleaningCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_brush", lang), category: cleaningCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_waste_bags_5", lang), category: cleaningCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_waste_bags_10", lang), category: cleaningCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_waste_bags_30", lang), category: cleaningCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_waste_bags_60", lang), category: cleaningCat)),
            
            // dips
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_salad_dressing", lang), category: dipsCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_dip", lang), category: dipsCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_pesto", lang), category: dipsCat)),
            
            // fish
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 500, unit: g, product: Product(uuid: uuid, name: tr("pr_salmon", lang), category: fishCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 500, unit: g, product: Product(uuid: uuid, name: tr("pr_trout", lang), category: fishCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 185, unit: g, product: Product(uuid: uuid, name: tr("pr_tuna", lang), category: fishCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 200, unit: g, product: Product(uuid: uuid, name: tr("pr_herring", lang), category: fishCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 90, unit: g, product: Product(uuid: uuid, name: tr("pr_anchovies", lang), category: fishCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 450, unit: g, product: Product(uuid: uuid, name: tr("pr_fish_sticks", lang), category: fishCat)),
            
            // fried
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 750, unit: g, product: Product(uuid: uuid, name: tr("pr_fries", lang), category: friedCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 750, unit: g, product: Product(uuid: uuid, name: tr("pr_fries_oven", lang), category: friedCat)),
            
            // bakery
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_cake", lang), category: bakeryCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_pudding", lang), category: bakeryCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_curd", lang), category: bakeryCat)),
            
            // cheese
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_cheese", lang), category: cheeseCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_parmesan", lang), category: cheeseCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_cheddar", lang), category: cheeseCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_gouda", lang), category: cheeseCat)),
            
            // beans
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 250, unit: g, product: Product(uuid: uuid, name: tr("pr_beans_kidney", lang), category: beansCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 220, unit: g, product: Product(uuid: uuid, name: tr("pr_beans_string", lang), category: beansCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_corn", lang), category: beansCat)),
            
            // eggs
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_eggs", lang), category: eggsCat)),
            
            // spread
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_marmelade", lang), category: spreadCat)),
            
            // cereal
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_corn_flakes", lang), category: cerealCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_muesli", lang), category: cerealCat)),
            
            // bread (bakery)
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_toast_bread", lang), category: breadCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_bread", lang), category: breadCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_baguette", lang), category: breadCat)),
            
            // cold cut
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_bacon", lang), category: coldCutCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_ham", lang), category: coldCutCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_salami", lang), category: coldCutCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_mortadella", lang), category: coldCutCat)),
            
            // milk
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_milk", lang), category: milkCat)), // TODO!!!!!!! liter unit
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_cream", lang), category: milkCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_sour_cream", lang), category: milkCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_whipped_cream", lang), category: milkCat)),
            
            // oven
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_pizza", lang), category: ovenCat)),
            
            // tea & coffee
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_green_tea", lang), category: teaAndCoffeeCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_black_tea", lang), category: teaAndCoffeeCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_mint_tea", lang), category: teaAndCoffeeCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_camellia_tea", lang), category: teaAndCoffeeCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_coffee", lang), category: teaAndCoffeeCat)),
            
            // sweets
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_chewing_gum", lang), category: sweetsCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_catamels", lang), category: sweetsCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_chocolates", lang), category: sweetsCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_ice_cream", lang), category: sweetsCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_mints", lang), category: sweetsCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_marshmallows", lang), category: sweetsCat)),
            
            // stationeries
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_paper", lang), category: stationeriesCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_pens", lang), category: stationeriesCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_pencils", lang), category: stationeriesCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_notebooks", lang), category: stationeriesCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_sharpeners", lang), category: stationeriesCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_erasers", lang), category: stationeriesCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_stapler", lang), category: stationeriesCat)),
            QuantifiableProduct(uuid: uuid, baseQuantityFloat: 1, unit: noneUnit, product: Product(uuid: uuid, name: tr("pr_cartridges", lang), category: stationeriesCat))
        ]
        
//        let products: [Product] = [
//            // fruits
//            Product(uuid: uuid, name: tr("pr_peaches", lang), category: fruitsCat),
//            Product(uuid: uuid, name: tr("pr_bananas", lang), category: fruitsCat),
//            Product(uuid: uuid, name: tr("pr_apples", lang), category: fruitsCat),
//            Product(uuid: uuid, name: tr("pr_nectarines", lang), category: fruitsCat),
//            Product(uuid: uuid, name: tr("pr_cherries", lang), category: fruitsCat),
//            Product(uuid: uuid, name: tr("pr_kiwis", lang), category: fruitsCat),
//            Product(uuid: uuid, name: tr("pr_melons", lang), category: fruitsCat),
//            Product(uuid: uuid, name: tr("pr_watermelons", lang), category: fruitsCat),
//            Product(uuid: uuid, name: tr("pr_lemons", lang), category: fruitsCat),
//            Product(uuid: uuid, name: tr("pr_grapes", lang), category: fruitsCat),
//            Product(uuid: uuid, name: tr("pr_oranges", lang), category: fruitsCat),
//            Product(uuid: uuid, name: tr("pr_mandarines", lang), category: fruitsCat),
//            Product(uuid: uuid, name: tr("pr_strawberries", lang), category: fruitsCat),
//            Product(uuid: uuid, name: tr("pr_blueberries", lang), category: fruitsCat),
//            Product(uuid: uuid, name: tr("pr_cranberries", lang), category: fruitsCat),
//            Product(uuid: uuid, name: tr("pr_grapefruits", lang), category: fruitsCat),
//            Product(uuid: uuid, name: tr("pr_mangos", lang), category: fruitsCat),
//            Product(uuid: uuid, name: tr("pr_limes", lang), category: fruitsCat),
//            Product(uuid: uuid, name: tr("pr_pomegranate", lang), category: fruitsCat),
//            Product(uuid: uuid, name: tr("pr_pineapple", lang), category: fruitsCat),
//            Product(uuid: uuid, name: tr("pr_plums", lang), category: fruitsCat),
//            Product(uuid: uuid, name: tr("pr_tomatoes", lang), category: fruitsCat),
//            Product(uuid: uuid, name: tr("pr_olives", lang), category: fruitsCat),
//
//            // frozen fruits
//            Product(uuid: uuid, name: tr("pr_strawberries_frozen", lang), category: frozenFruitsCat),
//            Product(uuid: uuid, name: tr("pr_blueberries_frozen", lang), category: frozenFruitsCat),
//            Product(uuid: uuid, name: tr("pr_cranberries_frozen", lang), category: frozenFruitsCat),
//            
//            // vegetables
//            Product(uuid: uuid, name: tr("pr_onions", lang), category: vegetablesCat),
//            Product(uuid: uuid, name: tr("pr_onions_red", lang), category: vegetablesCat),
//            Product(uuid: uuid, name: tr("pr_potatoes", lang), category: vegetablesCat),
//            Product(uuid: uuid, name: tr("pr_salad", lang), category: vegetablesCat),
//            Product(uuid: uuid, name: tr("pr_paprika", lang), category: vegetablesCat),
//            Product(uuid: uuid, name: tr("pr_garlic", lang), category: vegetablesCat),
//            Product(uuid: uuid, name: tr("pr_carrots", lang), category: vegetablesCat),
//            Product(uuid: uuid, name: tr("pr_asparagus", lang), category: vegetablesCat),
////            Product(uuid: uuid, name: tr("pr_dumplings", lang), category: vegetablesCat),
////            Product(uuid: uuid, name: tr("pr_mashed_potatoes", lang), category: vegetablesCat),
//            
//            // herbs (fresh/dry)
//            Product(uuid: uuid, name: tr("pr_parsley", lang), category: herbsCat),
//            Product(uuid: uuid, name: tr("pr_basil", lang), category: herbsCat),
//            Product(uuid: uuid, name: tr("pr_mint", lang), category: herbsCat),
//            Product(uuid: uuid, name: tr("pr_coriander", lang), category: herbsCat),
//            Product(uuid: uuid, name: tr("pr_cardamom", lang), category: herbsCat),
//            
//            // meat
//            Product(uuid: uuid, name: tr("pr_chicken", lang), category: meatCat),
//            Product(uuid: uuid, name: tr("pr_drum_sticks", lang), category: meatCat),
//            Product(uuid: uuid, name: tr("pr_chicken_wings", lang), category: meatCat),
//            Product(uuid: uuid, name: tr("pr_chops", lang), category: meatCat),
//            Product(uuid: uuid, name: tr("pr_beef_steak", lang), category: meatCat),
//            Product(uuid: uuid, name: tr("pr_beef", lang), category: meatCat),
//            Product(uuid: uuid, name: tr("pr_duck", lang), category: meatCat),
//            Product(uuid: uuid, name: tr("pr_turkey", lang), category: meatCat),
//            
//            // pets
//            Product(uuid: uuid, name: tr("pr_litter", lang), category: petsCat),
//            
//            // spices
//            Product(uuid: uuid, name: tr("pr_pepper", lang), category: spicesCat),
//            Product(uuid: uuid, name: tr("pr_salt", lang), category: spicesCat),
//            Product(uuid: uuid, name: tr("pr_sugar", lang), category: spicesCat),
//            Product(uuid: uuid, name: tr("pr_cinnamon", lang), category: spicesCat),
//            Product(uuid: uuid, name: tr("pr_chili", lang), category: spicesCat),
//            
//            // bakery
//            Product(uuid: uuid, name: tr("pr_flour", lang), category: bakeryCat),
//            
//            // pasta
//            Product(uuid: uuid, name: tr("pr_spaguetti", lang), category: pastaCat),
//            Product(uuid: uuid, name: tr("pr_noodles", lang), category: pastaCat),
//            Product(uuid: uuid, name: tr("pr_ravioli", lang), category: pastaCat),
//            
//            // rice
//            Product(uuid: uuid, name: tr("pr_rice", lang), category: riceCat),
//            Product(uuid: uuid, name: tr("pr_rice_basmati", lang), category: riceCat),
//            
//            // drinks
//            Product(uuid: uuid, name: tr("pr_water", lang), category: drinksCat),
//            Product(uuid: uuid, name: tr("pr_water_1", lang), category: drinksCat),
////            Product(uuid: uuid, name: tr("pr_club_mate", lang), category: drinksCat),
//            Product(uuid: uuid, name: tr("pr_cola_1", lang), category: drinksCat),
//            Product(uuid: uuid, name: tr("pr_cola_1_5", lang), category: drinksCat),
//            Product(uuid: uuid, name: tr("pr_cola_2", lang), category: drinksCat),
//            Product(uuid: uuid, name: tr("pr_fanta_1", lang), category: drinksCat),
//            Product(uuid: uuid, name: tr("pr_fanta_1_5", lang), category: drinksCat),
//            Product(uuid: uuid, name: tr("pr_fanta_2", lang), category: drinksCat),
//            Product(uuid: uuid, name: tr("pr_sprite_1", lang), category: drinksCat),
//            Product(uuid: uuid, name: tr("pr_sprite_1_5", lang), category: drinksCat),
//            Product(uuid: uuid, name: tr("pr_sprite_2", lang), category: drinksCat),
//            
//            // alcohol
//            Product(uuid: uuid, name: tr("pr_beer", lang), category: alcoholCat),
//            Product(uuid: uuid, name: tr("pr_whisky", lang), category: alcoholCat),
//            Product(uuid: uuid, name: tr("pr_vodka", lang), category: alcoholCat),
//            Product(uuid: uuid, name: tr("pr_tequilla", lang), category: alcoholCat),
//            Product(uuid: uuid, name: tr("pr_rum", lang), category: alcoholCat),
//            Product(uuid: uuid, name: tr("pr_wine_red", lang), category: alcoholCat),
//            Product(uuid: uuid, name: tr("pr_wine_white", lang), category: alcoholCat),
//            Product(uuid: uuid, name: tr("pr_sherry", lang), category: alcoholCat),
//            
//            // nuts
//            Product(uuid: uuid, name: tr("pr_nuts", lang), category: nutsCat),
//            Product(uuid: uuid, name: tr("pr_pine_nuts", lang), category: nutsCat),
//            Product(uuid: uuid, name: tr("pr_hazel_nuts", lang), category: nutsCat),
//            
//            // oil
//            Product(uuid: uuid, name: tr("pr_oil", lang), category: oilCat),
//            Product(uuid: uuid, name: tr("pr_oil_olives", lang), category: oilCat),
//            Product(uuid: uuid, name: tr("pr_oil_sunflower", lang), category: oilCat),
//            Product(uuid: uuid, name: tr("pr_oil_rapeseed", lang), category: oilCat),
//            Product(uuid: uuid, name: tr("pr_oil_margarine", lang), category: oilCat),
//            Product(uuid: uuid, name: tr("pr_oil_butter", lang), category: oilCat),
//            
//            // hygienic
//            Product(uuid: uuid, name: tr("pr_soap_body", lang), category: hygienicCat),
//            Product(uuid: uuid, name: tr("pr_soap_hands", lang), category: hygienicCat),
//            Product(uuid: uuid, name: tr("pr_shampoo", lang), category: hygienicCat),
//            Product(uuid: uuid, name: tr("pr_toothpaste", lang), category: hygienicCat),
//            Product(uuid: uuid, name: tr("pr_deodorant", lang), category: hygienicCat),
//            Product(uuid: uuid, name: tr("pr_tooth_brush", lang), category: hygienicCat),
//            Product(uuid: uuid, name: tr("pr_listerine", lang), category: hygienicCat),
//            Product(uuid: uuid, name: tr("pr_dental_floss", lang), category: hygienicCat),
//            Product(uuid: uuid, name: tr("pr_cotton", lang), category: hygienicCat),
//            Product(uuid: uuid, name: tr("pr_cotton_buds", lang), category: hygienicCat),
////            Product(uuid: uuid, name: tr("pr_diapers", lang), category: hygienicCat),
////            Product(uuid: uuid, name: tr("pr_sanitary_towel", lang), category: hygienicCat),
////            Product(uuid: uuid, name: tr("pr_tampons", lang), category: hygienicCat),
////            Product(uuid: uuid, name: tr("pr_razors", lang), category: hygienicCat),
////            Product(uuid: uuid, name: tr("pr_shaving_cream", lang), category: hygienicCat),
//
//            // clothes
//            Product(uuid: uuid, name: tr("pr_socks", lang), category: clothesCat),
//            Product(uuid: uuid, name: tr("pr_tshirts", lang), category: clothesCat),
//            Product(uuid: uuid, name: tr("pr_underwear", lang), category: clothesCat),
//            Product(uuid: uuid, name: tr("pr_pants", lang), category: clothesCat),
//            Product(uuid: uuid, name: tr("pr_shoes", lang), category: clothesCat),
//            
//            // cleaning
//            Product(uuid: uuid, name: tr("pr_cleaning_agent", lang), category: cleaningCat),
//            Product(uuid: uuid, name: tr("pr_cleaning_agent_toilet", lang), category: cleaningCat),
//            Product(uuid: uuid, name: tr("pr_cleaning_agent_windows", lang), category: cleaningCat),
//            Product(uuid: uuid, name: tr("pr_sponge", lang), category: cleaningCat),
//            Product(uuid: uuid, name: tr("pr_sponge_wire", lang), category: cleaningCat),
//            Product(uuid: uuid, name: tr("pr_mop", lang), category: cleaningCat),
//            Product(uuid: uuid, name: tr("pr_brush", lang), category: cleaningCat),
//            Product(uuid: uuid, name: tr("pr_waste_bags_5", lang), category: cleaningCat),
//            Product(uuid: uuid, name: tr("pr_waste_bags_10", lang), category: cleaningCat),
//            Product(uuid: uuid, name: tr("pr_waste_bags_30", lang), category: cleaningCat),
//            Product(uuid: uuid, name: tr("pr_waste_bags_60", lang), category: cleaningCat),
//            
//            // dips
//            Product(uuid: uuid, name: tr("pr_salad_dressing", lang), category: dipsCat),
//            Product(uuid: uuid, name: tr("pr_dip", lang), category: dipsCat),
//            Product(uuid: uuid, name: tr("pr_pesto", lang), category: dipsCat),
//            
//            // fish
//            Product(uuid: uuid, name: tr("pr_salmon", lang), category: fishCat),
//            Product(uuid: uuid, name: tr("pr_trout", lang), category: fishCat),
//            Product(uuid: uuid, name: tr("pr_tuna", lang), category: fishCat),
//            Product(uuid: uuid, name: tr("pr_herring", lang), category: fishCat),
//            Product(uuid: uuid, name: tr("pr_anchovies", lang), category: fishCat),
//            Product(uuid: uuid, name: tr("pr_fish_sticks", lang), category: fishCat),
//            
//            // fried
//            Product(uuid: uuid, name: tr("pr_fries", lang), category: friedCat),
//            Product(uuid: uuid, name: tr("pr_fries_oven", lang), category: friedCat),
//            
//            // bakery
//            Product(uuid: uuid, name: tr("pr_cake", lang), category: bakeryCat),
//            Product(uuid: uuid, name: tr("pr_pudding", lang), category: bakeryCat),
//            Product(uuid: uuid, name: tr("pr_curd", lang), category: bakeryCat),
//            
//            // cheese
//            Product(uuid: uuid, name: tr("pr_cheese", lang), category: cheeseCat),
//            Product(uuid: uuid, name: tr("pr_parmesan", lang), category: cheeseCat),
//            Product(uuid: uuid, name: tr("pr_cheddar", lang), category: cheeseCat),
//            Product(uuid: uuid, name: tr("pr_gouda", lang), category: cheeseCat),
//            
//            // beans
//            Product(uuid: uuid, name: tr("pr_beans_kidney", lang), category: beansCat),
//            Product(uuid: uuid, name: tr("pr_beans_string", lang), category: beansCat),
//            Product(uuid: uuid, name: tr("pr_corn", lang), category: beansCat),
//            
//            // eggs
//            Product(uuid: uuid, name: tr("pr_eggs", lang), category: eggsCat),
//            
//            // spread
//            Product(uuid: uuid, name: tr("pr_marmelade", lang), category: spreadCat),
//            
//            // cereal
//            Product(uuid: uuid, name: tr("pr_corn_flakes", lang), category: cerealCat),
//            Product(uuid: uuid, name: tr("pr_muesli", lang), category: cerealCat),
//            
//            // bread (bakery)
//            Product(uuid: uuid, name: tr("pr_toast_bread", lang), category: breadCat),
//            Product(uuid: uuid, name: tr("pr_bread", lang), category: breadCat),
//            Product(uuid: uuid, name: tr("pr_baguette", lang), category: breadCat),
//            
//            // cold cut
//            Product(uuid: uuid, name: tr("pr_bacon", lang), category: coldCutCat),
//            Product(uuid: uuid, name: tr("pr_ham", lang), category: coldCutCat),
//            Product(uuid: uuid, name: tr("pr_salami", lang), category: coldCutCat),
//            Product(uuid: uuid, name: tr("pr_mortadella", lang), category: coldCutCat),
//            
//            // milk
//            Product(uuid: uuid, name: tr("pr_milk", lang), category: milkCat),
//            Product(uuid: uuid, name: tr("pr_cream", lang), category: milkCat),
//            Product(uuid: uuid, name: tr("pr_sour_cream", lang), category: milkCat),
//            Product(uuid: uuid, name: tr("pr_whipped_cream", lang), category: milkCat),
//            
//            // oven
//            Product(uuid: uuid, name: tr("pr_pizza", lang), category: ovenCat),
//
//            // tea & coffee
//            Product(uuid: uuid, name: tr("pr_green_tea", lang), category: teaAndCoffeeCat),
//            Product(uuid: uuid, name: tr("pr_black_tea", lang), category: teaAndCoffeeCat),
//            Product(uuid: uuid, name: tr("pr_mint_tea", lang), category: teaAndCoffeeCat),
//            Product(uuid: uuid, name: tr("pr_camellia_tea", lang), category: teaAndCoffeeCat),
//            Product(uuid: uuid, name: tr("pr_coffee", lang), category: teaAndCoffeeCat),
//            
//            // sweets
//            Product(uuid: uuid, name: tr("pr_chewing_gum", lang), category: sweetsCat),
//            Product(uuid: uuid, name: tr("pr_catamels", lang), category: sweetsCat),
//            Product(uuid: uuid, name: tr("pr_chocolates", lang), category: sweetsCat),
//            Product(uuid: uuid, name: tr("pr_ice_cream", lang), category: sweetsCat),
//            Product(uuid: uuid, name: tr("pr_mints", lang), category: sweetsCat),
//            Product(uuid: uuid, name: tr("pr_marshmallows", lang), category: sweetsCat),
//            
//            // stationeries
//            Product(uuid: uuid, name: tr("pr_paper", lang), category: stationeriesCat),
//            Product(uuid: uuid, name: tr("pr_pens", lang), category: stationeriesCat),
//            Product(uuid: uuid, name: tr("pr_pencils", lang), category: stationeriesCat),
//            Product(uuid: uuid, name: tr("pr_notebooks", lang), category: stationeriesCat),
//            Product(uuid: uuid, name: tr("pr_sharpeners", lang), category: stationeriesCat),
//            Product(uuid: uuid, name: tr("pr_erasers", lang), category: stationeriesCat),
//            Product(uuid: uuid, name: tr("pr_stapler", lang), category: stationeriesCat),
//            Product(uuid: uuid, name: tr("pr_cartridges", lang), category: stationeriesCat)
//        ]

        // TODO!!!! better extract the categories from products because listing them again here is error prone, if we forget one the app may crash during prefill! (as there will be products that reference not saved categories). Performance is not important here as this is used only to generate the prefill db not in the app.
        let categories = [
            fruitsCat,
            frozenFruitsCat,
            vegetablesCat,
            herbsCat,
            meatCat,
            petsCat,
            bakeryCat,
            riceCat,
            nutsCat,
            oilCat,
            clothesCat,
            cleaningCat,
            milkCat,
            fishCat,
            pastaCat,
            drinksCat,
            alcoholCat,
            hygienicCat,
            dipsCat,
            spicesCat,
            friedCat,
            breadCat,
            sweetsCat,
            teaAndCoffeeCat,
            cheeseCat,
            beansCat,
            eggsCat,
            spreadCat,
            cerealCat,
            coldCutCat,
            ovenCat,
            stationeriesCat
        ]
        
        return (categories, quantifiableProducts)
    }
    
    func printStringsForTranslations(_ categories: [ProductCategory], products: [Product]) {
        print("#####################################")
        for category in categories {
            print("\(category.name) = \"\";")
        }
        for product in products {
            print("\(product.item.name) = \"\";")
        }
        print("#####################################")
    }
}
