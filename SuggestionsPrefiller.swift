//
//  SuggestionsPrefiller.swift
//  shoppin
//
//  Created by ischuetz on 24/09/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

class SuggestionsPrefiller {

    private let dbProvider = RealmProductProvider()
    /**
    * Generates the prefill Realm file.
    * When it's done, add the generated file to build phases > copy bundle resources, in target where it's needed.
    * The apps will prefill the database with it in the first launch.
    *
    * This is not meant to be called during normal execution.
    */
    func prefill(onFinished: VoidFunction? = nil) {

        func prefill(lang: String, onFinished: VoidFunction) {
            let (categories, products) = prefillProducts(lang)
            //        printStringsForTranslations(categories, products: products)
            dbProvider.save(categories, products: products) {[weak self] saved in

                self?.writeDBCopy(NSHomeDirectory() + "/Documents/prefill\(lang).realm")
                print("Finished prefilling lang: \(lang)")
                
                // After copy, clear the default db such that it's not included in the next languages
                self?.dbProvider.removeAllProductsAndCategories {success in
                    
                    if !success { // Note this doesn't interrupt the operation
                        print("Error: dbProvider.removeAllProductsAndCategories, not success clearing: \(lang)")
                    }
                    
                    onFinished()
                }
            }
        }
        
        let langs = LangManager().availableLangs

        func prefillRec(index: Int) {
            guard index < langs.count else {
                onFinished?()
                return
            }
            
            prefill(langs[index]) {
                prefillRec(index + 1)
            }
        }
        
        prefillRec(0)
    }
    
    private func writeDBCopy(toPath: String) {

        if let fromPath = Realm.Configuration.defaultConfiguration.path {
            do {
                try Realm().writeCopyToPath(toPath)
                print("Copied realm from path: \(fromPath), toPath: \(toPath)")

            } catch let error as NSError {
                print("Error copying realm: \(error)")
            } catch _ {
                print("Error copying realm")
            }
        } else {
            print("Error copying realm - no path")
        }
    }

    
    var uuid: String {
        return NSUUID().UUIDString
    }
    
    func tr(key: String, _ lang: String) -> String {
        let path = NSBundle.mainBundle().pathForResource(lang, ofType: "lproj")
        let bundle = NSBundle(path: path!)
        if let str = bundle?.localizedStringForKey(key, value: nil, table: nil) {
            return str
        } else {
            print("Warn: SuggestionsPrefiller.tr: Didn't find translation for key: \(key), lang: \(lang)")
            return ""
        }
    }
    
    
    // TODO!!! add brand to products! and unique key name + mark --- prices without mark will likely be annoying to users as they will have to edit the product (price) every time they decide to buy a different brand. Prefill would not have brands! User has to edit the prefilled products or add new ones with the brands.
    // we could add brand to name but this is going to cause space problems in the lists and looks bad
    
    private func prefillProducts(lang: String) -> (categories: [ProductCategory], products: [Product]) {
        let fruitsCat = ProductCategory(uuid: uuid, name: tr("pr_fruits", lang), color: UIColor.flatRedColor())
        let frozenFruitsCat = ProductCategory(uuid: uuid, name: tr("pr_fruits_frozen", lang), color: UIColor.flatBlueColor())
        let vegetablesCat = ProductCategory(uuid: uuid, name: tr("pr_vegetables", lang), color: UIColor.flatGreenColor())
        let herbsCat = ProductCategory(uuid: uuid, name: tr("pr_herbs", lang), color: UIColor.flatGreenColorDark())
        let meatCat = ProductCategory(uuid: uuid, name: tr("pr_meat", lang), color: UIColor.flatRedColorDark())
        let petsCat = ProductCategory(uuid: uuid, name: tr("pr_pets", lang), color: UIColor.flatGreenColorDark())
        let bakeryCat = ProductCategory(uuid: uuid, name: tr("pr_bakery", lang), color: UIColor.flatBrownColorDark())
        let riceCat = ProductCategory(uuid: uuid, name: tr("pr_rice", lang), color: UIColor.flatWhiteColor())
        let nutsCat = ProductCategory(uuid: uuid, name: tr("pr_nuts", lang), color: UIColor.flatBrownColorDark())
        let oilCat = ProductCategory(uuid: uuid, name: tr("pr_oil", lang), color: UIColor.flatYellowColor())
        let clothesCat = ProductCategory(uuid: uuid, name: tr("pr_oil", lang), color: UIColor.flatBlueColorDark())
        let cleaningCat = ProductCategory(uuid: uuid, name: tr("pr_cleaning", lang), color: UIColor.flatMagentaColor())
        
        let milkCat = ProductCategory(uuid: uuid, name: tr("pr_milk", lang), color: UIColor.flatYellowColor())
        
        let fishCat = ProductCategory(uuid: uuid, name: tr("pr_fish", lang), color: UIColor.flatBlueColorDark())
        let pastaCat = ProductCategory(uuid: uuid, name: tr("pr_pasta", lang), color: UIColor.flatWhiteColorDark())
        let drinksCat = ProductCategory(uuid: uuid, name: tr("pr_drinks", lang), color: UIColor.flatBlueColor().lightenByPercentage(0.5))
        let alcoholCat = ProductCategory(uuid: uuid, name: tr("pr_alcohol", lang), color: UIColor.flatBrownColorDark())
        let hygienicCat = ProductCategory(uuid: uuid, name: tr("pr_hygienic", lang), color: UIColor.flatGrayColor())
        let dipsCat = ProductCategory(uuid: uuid, name: tr("pr_dips", lang), color: UIColor.flatBrownColor())
        let spicesCat = ProductCategory(uuid: uuid, name: tr("pr_spices", lang), color: UIColor.flatBrownColor())
        let friedCat = ProductCategory(uuid: uuid, name: tr("pr_fried", lang), color: UIColor.flatBrownColor())
        let breadCat = ProductCategory(uuid: uuid, name: tr("pr_bread", lang), color: UIColor.flatYellowColorDark())
        let sweetsCat = ProductCategory(uuid: uuid, name: tr("pr_sweets", lang), color: UIColor.flatPinkColor())
        let teaAndCoffeeCat = ProductCategory(uuid: uuid, name: tr("pr_tea_coffee", lang), color: UIColor.flatBlackColor())
        let cheeseCat = ProductCategory(uuid: uuid, name: tr("pr_cheese", lang), color: UIColor.flatYellowColorDark())
        let beansCat = ProductCategory(uuid: uuid, name: tr("pr_beans", lang), color: UIColor.flatRedColorDark())
        let eggsCat = ProductCategory(uuid: uuid, name: tr("pr_eggs", lang), color: UIColor.flatRedColorDark())
        let spreadCat = ProductCategory(uuid: uuid, name: tr("pr_spread", lang), color: UIColor.flatRedColorDark())
        let cerealCat = ProductCategory(uuid: uuid, name: tr("pr_cereal", lang), color: UIColor.flatOrangeColor())
        let coldCutCat = ProductCategory(uuid: uuid, name: tr("pr_cold_cut", lang), color: UIColor.flatOrangeColorDark())
        let ovenCat = ProductCategory(uuid: uuid, name: tr("pr_oven", lang), color: UIColor.flatBlackColorDark())
        let stationeriesCat = ProductCategory(uuid: uuid, name: tr("pr_stationeries", lang), color: UIColor.flatWhiteColor())
  
        let products = [
            // fruits
            Product(uuid: uuid, name: tr("pr_peaches", lang), price: 0, category: fruitsCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_bananas", lang), price: 0, category: fruitsCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_apples", lang), price: 0, category: fruitsCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_nectarines", lang), price: 0, category: fruitsCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_cherries", lang), price: 0, category: fruitsCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_kiwis", lang), price: 0, category: fruitsCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_melons", lang), price: 0, category: fruitsCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_watermelons", lang), price: 0, category: fruitsCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_lemons", lang), price: 0, category: fruitsCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_grapes", lang), price: 0, category: fruitsCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_oranges", lang), price: 0, category: fruitsCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_mandarines", lang), price: 0, category: fruitsCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_strawberries", lang), price: 0, category: fruitsCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_blueberries", lang), price: 0, category: fruitsCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_cranberries", lang), price: 0, category: fruitsCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_grapefruits", lang), price: 0, category: fruitsCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_mangos", lang), price: 0, category: fruitsCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_limes", lang), price: 0, category: fruitsCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_limes", lang), price: 0, category: fruitsCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_pomegranate", lang), price: 0, category: fruitsCat, baseQuantity: 1, unit: .None),
            
            // frozen fruits
            Product(uuid: uuid, name: tr("pr_strawberries_frozen", lang), price: 0, category: frozenFruitsCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_blueberries_frozen", lang), price: 0, category: frozenFruitsCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_cranberries_frozen", lang), price: 0, category: frozenFruitsCat, baseQuantity: 1, unit: .None),
            
            // vegetables
            Product(uuid: uuid, name: tr("pr_onions", lang), price: 0, category: vegetablesCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_onions_red", lang), price: 0, category: vegetablesCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_potatoes", lang), price: 0, category: vegetablesCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_salad", lang), price: 0, category: vegetablesCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_tomatoes", lang), price: 0, category: vegetablesCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_paprika", lang), price: 0, category: vegetablesCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_olives", lang), price: 0, category: vegetablesCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_garlic", lang), price: 0, category: vegetablesCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_carrots", lang), price: 0, category: vegetablesCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_asparagus", lang), price: 0, category: vegetablesCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_dumplings", lang), price: 0, category: vegetablesCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_mashed_potatoes", lang), price: 0, category: vegetablesCat, baseQuantity: 1, unit: .None),
            
            // herbs (fresh/dry)
            Product(uuid: uuid, name: tr("pr_parsley", lang), price: 0, category: herbsCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_basil", lang), price: 0, category: herbsCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_mint", lang), price: 0, category: herbsCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_coriander", lang), price: 0, category: herbsCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_cardamom", lang), price: 0, category: herbsCat, baseQuantity: 1, unit: .None),
            
            // meat
            Product(uuid: uuid, name: tr("pr_chicken", lang), price: 0, category: meatCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_drum_sticks", lang), price: 0, category: meatCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_chicken_wings", lang), price: 0, category: meatCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_chops", lang), price: 0, category: meatCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_beef_steak", lang), price: 0, category: meatCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_beef", lang), price: 0, category: meatCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_duck", lang), price: 0, category: meatCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_turkey", lang), price: 0, category: meatCat, baseQuantity: 1, unit: .None),
            
            // pets
            Product(uuid: uuid, name: tr("pr_litter", lang), price: 0, category: petsCat, baseQuantity: 1, unit: .None),
            
            // spices
            Product(uuid: uuid, name: tr("pr_pepper", lang), price: 0, category: spicesCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_salt", lang), price: 0, category: spicesCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_sugar", lang), price: 0, category: spicesCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_cinnamon", lang), price: 0, category: spicesCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_chili", lang), price: 0, category: spicesCat, baseQuantity: 1, unit: .None),
            
            // bakery
            Product(uuid: uuid, name: tr("pr_flour", lang), price: 0, category: bakeryCat, baseQuantity: 1, unit: .None),
            
            // pasta
            Product(uuid: uuid, name: tr("pr_spaguetti", lang), price: 0, category: pastaCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_noodles", lang), price: 0, category: pastaCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_ravioli", lang), price: 0, category: pastaCat, baseQuantity: 1, unit: .None),
            
            // rice
            Product(uuid: uuid, name: tr("pr_rice", lang), price: 0, category: riceCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_rice_basmati", lang), price: 0, category: riceCat, baseQuantity: 1, unit: .None),
            
            // drinks
            Product(uuid: uuid, name: tr("pr_water", lang), price: 0, category: drinksCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_water_1", lang), price: 0, category: drinksCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_club_mate", lang), price: 0, category: drinksCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_cola_1", lang), price: 0, category: drinksCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_cola_1_5", lang), price: 0, category: drinksCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_cola_2", lang), price: 0, category: drinksCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_fanta_1", lang), price: 0, category: drinksCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_fanta_1_5", lang), price: 0, category: drinksCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_fanta_2", lang), price: 0, category: drinksCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_sprite_1", lang), price: 0, category: drinksCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_sprite_1_5", lang), price: 0, category: drinksCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_sprite_2", lang), price: 0, category: drinksCat, baseQuantity: 1, unit: .None),
            
            // alcohol
            Product(uuid: uuid, name: tr("pr_beer", lang), price: 0, category: alcoholCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_whisky", lang), price: 0, category: alcoholCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_vodka", lang), price: 0, category: alcoholCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_tequilla", lang), price: 0, category: alcoholCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_rum", lang), price: 0, category: alcoholCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_wine_red", lang), price: 0, category: alcoholCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_wine_white", lang), price: 0, category: alcoholCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_sherry", lang), price: 0, category: alcoholCat, baseQuantity: 1, unit: .None),
            
            // nuts
            Product(uuid: uuid, name: tr("pr_nuts", lang), price: 0, category: nutsCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_pine_nuts", lang), price: 0, category: nutsCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_hazel_nuts", lang), price: 0, category: nutsCat, baseQuantity: 1, unit: .None),
            
            // oil
            Product(uuid: uuid, name: tr("pr_oil", lang), price: 0, category: oilCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_oil_olives", lang), price: 0, category: oilCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_oil_sunflower", lang), price: 0, category: oilCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_oil_rapeseed", lang), price: 0, category: oilCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_oil_margarine", lang), price: 0, category: oilCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_oil_butter", lang), price: 0, category: oilCat, baseQuantity: 1, unit: .None),
            
            // hygienic
            Product(uuid: uuid, name: tr("pr_soap_body", lang), price: 0, category: hygienicCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_soap_hands", lang), price: 0, category: hygienicCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_shampoo", lang), price: 0, category: hygienicCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_toothpaste", lang), price: 0, category: hygienicCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_deodorant", lang), price: 0, category: hygienicCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_tooth_brush", lang), price: 0, category: hygienicCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_listerine", lang), price: 0, category: hygienicCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_dental_floss", lang), price: 0, category: hygienicCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_cotton", lang), price: 0, category: hygienicCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_cotton_buds", lang), price: 0, category: hygienicCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_diapers", lang), price: 0, category: hygienicCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_sanitary_towel", lang), price: 0, category: hygienicCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_tampons", lang), price: 0, category: hygienicCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_razors", lang), price: 0, category: oilCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_shaving_cream", lang), price: 0, category: oilCat, baseQuantity: 1, unit: .None),

            // clothes
            Product(uuid: uuid, name: tr("pr_socks", lang), price: 0, category: clothesCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_tshirts", lang), price: 0, category: clothesCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_underwear", lang), price: 0, category: clothesCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_pants", lang), price: 0, category: clothesCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_shoes", lang), price: 0, category: clothesCat, baseQuantity: 1, unit: .None),
            
            // cleaning
            Product(uuid: uuid, name: tr("pr_cleaning_agent", lang), price: 0, category: cleaningCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_cleaning_agent_toilet", lang), price: 0, category: cleaningCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_cleaning_agent_windows", lang), price: 0, category: cleaningCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_sponge", lang), price: 0, category: cleaningCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_sponge_wire", lang), price: 0, category: cleaningCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_mop", lang), price: 0, category: cleaningCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_brush", lang), price: 0, category: cleaningCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_waste_bags_5", lang), price: 0, category: cleaningCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_waste_bags_10", lang), price: 0, category: cleaningCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_waste_bags_30", lang), price: 0, category: cleaningCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_waste_bags_60", lang), price: 0, category: cleaningCat, baseQuantity: 1, unit: .None),
            
            // dips
            Product(uuid: uuid, name: tr("pr_salad_dressing", lang), price: 0, category: dipsCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_dip", lang), price: 0, category: dipsCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_pesto", lang), price: 0, category: dipsCat, baseQuantity: 1, unit: .None),
            
            // fish
            Product(uuid: uuid, name: tr("pr_salmon", lang), price: 0, category: fishCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_trout", lang), price: 0, category: fishCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_tuna", lang), price: 0, category: fishCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_herring", lang), price: 0, category: fishCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_anchovies", lang), price: 0, category: fishCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_fish_sticks", lang), price: 0, category: fishCat, baseQuantity: 1, unit: .None),
            
            // fried
            Product(uuid: uuid, name: tr("pr_fries", lang), price: 0, category: friedCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_fries_oven", lang), price: 0, category: friedCat, baseQuantity: 1, unit: .None),
            
            // bakery
            Product(uuid: uuid, name: tr("pr_cake", lang), price: 0, category: bakeryCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_pudding", lang), price: 0, category: bakeryCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_curd", lang), price: 0, category: bakeryCat, baseQuantity: 1, unit: .None),
            
            // cheese
            Product(uuid: uuid, name: tr("pr_cheese", lang), price: 0, category: cheeseCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_parmesan", lang), price: 0, category: cheeseCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_cheddar", lang), price: 0, category: cheeseCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_gouda", lang), price: 0, category: cheeseCat, baseQuantity: 1, unit: .None),
            
            // beans
            Product(uuid: uuid, name: tr("pr_beans_kidney", lang), price: 0, category: beansCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_beans_string", lang), price: 0, category: beansCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_corn", lang), price: 0, category: beansCat, baseQuantity: 1, unit: .None),
            
            // eggs
            Product(uuid: uuid, name: tr("pr_eggs", lang), price: 0, category: eggsCat, baseQuantity: 1, unit: .None),
            
            // spread
            Product(uuid: uuid, name: tr("pr_marmelade", lang), price: 0, category: spreadCat, baseQuantity: 1, unit: .None),
            
            // cereal
            Product(uuid: uuid, name: tr("pr_corn_flakes", lang), price: 0, category: cerealCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_muesli", lang), price: 0, category: cerealCat, baseQuantity: 1, unit: .None),
            
            // bread (bakery)
            Product(uuid: uuid, name: tr("pr_toast_bread", lang), price: 0, category: cleaningCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_bread", lang), price: 0, category: cleaningCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_baguette", lang), price: 0, category: cleaningCat, baseQuantity: 1, unit: .None),
            
            // cold cut
            Product(uuid: uuid, name: tr("pr_bacon", lang), price: 0, category: coldCutCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_ham", lang), price: 0, category: coldCutCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_salami", lang), price: 0, category: coldCutCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_mortadella", lang), price: 0, category: coldCutCat, baseQuantity: 1, unit: .None),
            
            // milk
            Product(uuid: uuid, name: tr("pr_milk", lang), price: 0, category: milkCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_cream", lang), price: 0, category: milkCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_sour_cream", lang), price: 0, category: milkCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_whipped_cream", lang), price: 0, category: milkCat, baseQuantity: 1, unit: .None),
            
            // oven
            Product(uuid: uuid, name: tr("pr_pizza", lang), price: 0, category: ovenCat, baseQuantity: 1, unit: .None),
            
            // stationeries
            Product(uuid: uuid, name: tr("pr_paper", lang), price: 0, category: stationeriesCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_pens", lang), price: 0, category: stationeriesCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_pencils", lang), price: 0, category: stationeriesCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_notebooks", lang), price: 0, category: stationeriesCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_sharpeners", lang), price: 0, category: stationeriesCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_erasers", lang), price: 0, category: stationeriesCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_stapler", lang), price: 0, category: stationeriesCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_cartridges", lang), price: 0, category: stationeriesCat, baseQuantity: 1, unit: .None),

            // tea & coffee
            Product(uuid: uuid, name: tr("pr_green_tea", lang), price: 0, category: teaAndCoffeeCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_black_tea", lang), price: 0, category: teaAndCoffeeCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_mint_tea", lang), price: 0, category: teaAndCoffeeCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_camellia_tea", lang), price: 0, category: teaAndCoffeeCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_coffee", lang), price: 0, category: teaAndCoffeeCat, baseQuantity: 1, unit: .None),
            
            // sweets
            Product(uuid: uuid, name: tr("pr_chewing_gum", lang), price: 0, category: sweetsCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_catamels", lang), price: 0, category: sweetsCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_chocolates", lang), price: 0, category: sweetsCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_ice_cream", lang), price: 0, category: sweetsCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_mints", lang), price: 0, category: sweetsCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: tr("pr_marshmallows", lang), price: 0, category: sweetsCat, baseQuantity: 1, unit: .None)
        ]

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
        
        return (categories, products)
    }
    
    func printStringsForTranslations(categories: [ProductCategory], products: [Product]) {
        print("#####################################")
        for category in categories {
            print("\(category.name) = \"\";")
        }
        for product in products {
            print("\(product.name) = \"\";")
        }
        print("#####################################")
    }
}
