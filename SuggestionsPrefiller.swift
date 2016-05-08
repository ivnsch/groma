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

    // Used to init database. This is meant to be called when the app starts.
    func prefill(lang: String, onFinished: Bool -> Void) {
        let (categories, products) = prefillProducts(lang)
        dbProvider.save(categories, dbProducts: products) {saved in
            onFinished(saved)
        }
    }

    /**
    *
    * NOTE: Not used anymore because prefill database is not usable without replacing the uuids at runtime and this turns to be a bit tricky and not good performance so now we do everything at runtime.
    *
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
            dbProvider.save(categories, dbProducts: products) {[weak self] saved in

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
    
    private func prefillProducts(lang: String) -> (categories: [DBProductCategory], products: [DBProduct]) {
        let fruitsCat = DBProductCategory(uuid: uuid, name: tr("pr_fruits", lang), bgColorHex: UIColor.flatRedColor().hexStr)
        let frozenFruitsCat = DBProductCategory(uuid: uuid, name: tr("pr_fruits_frozen", lang), bgColorHex: UIColor.flatBlueColor().hexStr)
        let vegetablesCat = DBProductCategory(uuid: uuid, name: tr("pr_vegetables", lang), bgColorHex: UIColor.flatGreenColor().hexStr)
        let herbsCat = DBProductCategory(uuid: uuid, name: tr("pr_herbs", lang), bgColorHex: UIColor.flatGreenColorDark().hexStr)
        let meatCat = DBProductCategory(uuid: uuid, name: tr("pr_meat", lang), bgColorHex: UIColor.flatRedColorDark().hexStr)
        let petsCat = DBProductCategory(uuid: uuid, name: tr("pr_pets", lang), bgColorHex: UIColor.flatGreenColorDark().hexStr)
        let bakeryCat = DBProductCategory(uuid: uuid, name: tr("pr_bakery", lang), bgColorHex: UIColor.flatBrownColorDark().hexStr)
        let riceCat = DBProductCategory(uuid: uuid, name: tr("pr_rice", lang), bgColorHex: UIColor.flatWhiteColor().hexStr)
        let nutsCat = DBProductCategory(uuid: uuid, name: tr("pr_nuts", lang), bgColorHex: UIColor.flatBrownColorDark().hexStr)
        let oilCat = DBProductCategory(uuid: uuid, name: tr("pr_oil", lang), bgColorHex: UIColor.flatYellowColor().hexStr)
        let clothesCat = DBProductCategory(uuid: uuid, name: tr("pr_clothes", lang), bgColorHex: UIColor.flatBlueColorDark().hexStr)
        let cleaningCat = DBProductCategory(uuid: uuid, name: tr("pr_cleaning", lang), bgColorHex: UIColor.flatMagentaColor().hexStr)
        
        let milkCat = DBProductCategory(uuid: uuid, name: tr("pr_milk", lang), bgColorHex: UIColor.flatYellowColor().hexStr)
        
        let fishCat = DBProductCategory(uuid: uuid, name: tr("pr_fish", lang), bgColorHex: UIColor.flatBlueColorDark().hexStr)
        let pastaCat = DBProductCategory(uuid: uuid, name: tr("pr_pasta", lang), bgColorHex: UIColor.flatWhiteColorDark().hexStr)
        let drinksCat = DBProductCategory(uuid: uuid, name: tr("pr_drinks", lang), bgColorHex: UIColor.flatBlueColor().lightenByPercentage(0.5).hexStr)
        let alcoholCat = DBProductCategory(uuid: uuid, name: tr("pr_alcohol", lang), bgColorHex: UIColor.flatBrownColorDark().hexStr)
        let hygienicCat = DBProductCategory(uuid: uuid, name: tr("pr_hygienic", lang), bgColorHex: UIColor.flatGrayColor().hexStr)
        let dipsCat = DBProductCategory(uuid: uuid, name: tr("pr_dips", lang), bgColorHex: UIColor.flatBrownColor().hexStr)
        let spicesCat = DBProductCategory(uuid: uuid, name: tr("pr_spices", lang), bgColorHex: UIColor.flatBrownColor().hexStr)
        let friedCat = DBProductCategory(uuid: uuid, name: tr("pr_fried", lang), bgColorHex: UIColor.flatBrownColor().hexStr)
        let breadCat = DBProductCategory(uuid: uuid, name: tr("pr_bread", lang), bgColorHex: UIColor.flatYellowColorDark().hexStr)
        let sweetsCat = DBProductCategory(uuid: uuid, name: tr("pr_sweets", lang), bgColorHex: UIColor.flatPinkColor().hexStr)
        let teaAndCoffeeCat = DBProductCategory(uuid: uuid, name: tr("pr_tea_coffee", lang), bgColorHex: UIColor.flatBlackColor().hexStr)
        let cheeseCat = DBProductCategory(uuid: uuid, name: tr("pr_cheese", lang), bgColorHex: UIColor.flatYellowColorDark().hexStr)
        let beansCat = DBProductCategory(uuid: uuid, name: tr("pr_beans", lang), bgColorHex: UIColor.flatRedColorDark().hexStr)
        let eggsCat = DBProductCategory(uuid: uuid, name: tr("pr_eggs", lang), bgColorHex: UIColor.flatRedColorDark().hexStr)
        let spreadCat = DBProductCategory(uuid: uuid, name: tr("pr_spread", lang), bgColorHex: UIColor.flatRedColorDark().hexStr)
        let cerealCat = DBProductCategory(uuid: uuid, name: tr("pr_cereal", lang), bgColorHex: UIColor.flatOrangeColor().hexStr)
        let coldCutCat = DBProductCategory(uuid: uuid, name: tr("pr_cold_cut", lang), bgColorHex: UIColor.flatOrangeColorDark().hexStr)
        let ovenCat = DBProductCategory(uuid: uuid, name: tr("pr_oven", lang), bgColorHex: UIColor.flatBlackColorDark().hexStr)
        let stationeriesCat = DBProductCategory(uuid: uuid, name: tr("pr_stationeries", lang), bgColorHex: UIColor.flatWhiteColor().hexStr)
  
        let products: [DBProduct] = [
            // fruits
            DBProduct(uuid: uuid, name: tr("pr_peaches", lang), category: fruitsCat),
            DBProduct(uuid: uuid, name: tr("pr_bananas", lang), category: fruitsCat),
            DBProduct(uuid: uuid, name: tr("pr_apples", lang), category: fruitsCat),
            DBProduct(uuid: uuid, name: tr("pr_nectarines", lang), category: fruitsCat),
            DBProduct(uuid: uuid, name: tr("pr_cherries", lang), category: fruitsCat),
            DBProduct(uuid: uuid, name: tr("pr_kiwis", lang), category: fruitsCat),
            DBProduct(uuid: uuid, name: tr("pr_melons", lang), category: fruitsCat),
            DBProduct(uuid: uuid, name: tr("pr_watermelons", lang), category: fruitsCat),
            DBProduct(uuid: uuid, name: tr("pr_lemons", lang), category: fruitsCat),
            DBProduct(uuid: uuid, name: tr("pr_grapes", lang), category: fruitsCat),
            DBProduct(uuid: uuid, name: tr("pr_oranges", lang), category: fruitsCat),
            DBProduct(uuid: uuid, name: tr("pr_mandarines", lang), category: fruitsCat),
            DBProduct(uuid: uuid, name: tr("pr_strawberries", lang), category: fruitsCat),
            DBProduct(uuid: uuid, name: tr("pr_blueberries", lang), category: fruitsCat),
            DBProduct(uuid: uuid, name: tr("pr_cranberries", lang), category: fruitsCat),
            DBProduct(uuid: uuid, name: tr("pr_grapefruits", lang), category: fruitsCat),
            DBProduct(uuid: uuid, name: tr("pr_mangos", lang), category: fruitsCat),
            DBProduct(uuid: uuid, name: tr("pr_limes", lang), category: fruitsCat),
            DBProduct(uuid: uuid, name: tr("pr_pomegranate", lang), category: fruitsCat),
            
            // frozen fruits
            DBProduct(uuid: uuid, name: tr("pr_strawberries_frozen", lang), category: frozenFruitsCat),
            DBProduct(uuid: uuid, name: tr("pr_blueberries_frozen", lang), category: frozenFruitsCat),
            DBProduct(uuid: uuid, name: tr("pr_cranberries_frozen", lang), category: frozenFruitsCat),
            
            // vegetables
            DBProduct(uuid: uuid, name: tr("pr_onions", lang), category: vegetablesCat),
            DBProduct(uuid: uuid, name: tr("pr_onions_red", lang), category: vegetablesCat),
            DBProduct(uuid: uuid, name: tr("pr_potatoes", lang), category: vegetablesCat),
            DBProduct(uuid: uuid, name: tr("pr_salad", lang), category: vegetablesCat),
            DBProduct(uuid: uuid, name: tr("pr_tomatoes", lang), category: vegetablesCat),
            DBProduct(uuid: uuid, name: tr("pr_paprika", lang), category: vegetablesCat),
            DBProduct(uuid: uuid, name: tr("pr_olives", lang), category: vegetablesCat),
            DBProduct(uuid: uuid, name: tr("pr_garlic", lang), category: vegetablesCat),
            DBProduct(uuid: uuid, name: tr("pr_carrots", lang), category: vegetablesCat),
            DBProduct(uuid: uuid, name: tr("pr_asparagus", lang), category: vegetablesCat),
            DBProduct(uuid: uuid, name: tr("pr_dumplings", lang), category: vegetablesCat),
            DBProduct(uuid: uuid, name: tr("pr_mashed_potatoes", lang), category: vegetablesCat),
            
            // herbs (fresh/dry)
            DBProduct(uuid: uuid, name: tr("pr_parsley", lang), category: herbsCat),
            DBProduct(uuid: uuid, name: tr("pr_basil", lang), category: herbsCat),
            DBProduct(uuid: uuid, name: tr("pr_mint", lang), category: herbsCat),
            DBProduct(uuid: uuid, name: tr("pr_coriander", lang), category: herbsCat),
            DBProduct(uuid: uuid, name: tr("pr_cardamom", lang), category: herbsCat),
            
            // meat
            DBProduct(uuid: uuid, name: tr("pr_chicken", lang), category: meatCat),
            DBProduct(uuid: uuid, name: tr("pr_drum_sticks", lang), category: meatCat),
            DBProduct(uuid: uuid, name: tr("pr_chicken_wings", lang), category: meatCat),
            DBProduct(uuid: uuid, name: tr("pr_chops", lang), category: meatCat),
            DBProduct(uuid: uuid, name: tr("pr_beef_steak", lang), category: meatCat),
            DBProduct(uuid: uuid, name: tr("pr_beef", lang), category: meatCat),
            DBProduct(uuid: uuid, name: tr("pr_duck", lang), category: meatCat),
            DBProduct(uuid: uuid, name: tr("pr_turkey", lang), category: meatCat),
            
            // pets
            DBProduct(uuid: uuid, name: tr("pr_litter", lang), category: petsCat),
            
            // spices
            DBProduct(uuid: uuid, name: tr("pr_pepper", lang), category: spicesCat),
            DBProduct(uuid: uuid, name: tr("pr_salt", lang), category: spicesCat),
            DBProduct(uuid: uuid, name: tr("pr_sugar", lang), category: spicesCat),
            DBProduct(uuid: uuid, name: tr("pr_cinnamon", lang), category: spicesCat),
            DBProduct(uuid: uuid, name: tr("pr_chili", lang), category: spicesCat),
            
            // bakery
            DBProduct(uuid: uuid, name: tr("pr_flour", lang), category: bakeryCat),
            
            // pasta
            DBProduct(uuid: uuid, name: tr("pr_spaguetti", lang), category: pastaCat),
            DBProduct(uuid: uuid, name: tr("pr_noodles", lang), category: pastaCat),
            DBProduct(uuid: uuid, name: tr("pr_ravioli", lang), category: pastaCat),
            
            // rice
            DBProduct(uuid: uuid, name: tr("pr_rice", lang), category: riceCat),
            DBProduct(uuid: uuid, name: tr("pr_rice_basmati", lang), category: riceCat),
            
            // drinks
            DBProduct(uuid: uuid, name: tr("pr_water", lang), category: drinksCat),
            DBProduct(uuid: uuid, name: tr("pr_water_1", lang), category: drinksCat),
            DBProduct(uuid: uuid, name: tr("pr_club_mate", lang), category: drinksCat),
            DBProduct(uuid: uuid, name: tr("pr_cola_1", lang), category: drinksCat),
            DBProduct(uuid: uuid, name: tr("pr_cola_1_5", lang), category: drinksCat),
            DBProduct(uuid: uuid, name: tr("pr_cola_2", lang), category: drinksCat),
            DBProduct(uuid: uuid, name: tr("pr_fanta_1", lang), category: drinksCat),
            DBProduct(uuid: uuid, name: tr("pr_fanta_1_5", lang), category: drinksCat),
            DBProduct(uuid: uuid, name: tr("pr_fanta_2", lang), category: drinksCat),
            DBProduct(uuid: uuid, name: tr("pr_sprite_1", lang), category: drinksCat),
            DBProduct(uuid: uuid, name: tr("pr_sprite_1_5", lang), category: drinksCat),
            DBProduct(uuid: uuid, name: tr("pr_sprite_2", lang), category: drinksCat),
            
            // alcohol
            DBProduct(uuid: uuid, name: tr("pr_beer", lang), category: alcoholCat),
            DBProduct(uuid: uuid, name: tr("pr_whisky", lang), category: alcoholCat),
            DBProduct(uuid: uuid, name: tr("pr_vodka", lang), category: alcoholCat),
            DBProduct(uuid: uuid, name: tr("pr_tequilla", lang), category: alcoholCat),
            DBProduct(uuid: uuid, name: tr("pr_rum", lang), category: alcoholCat),
            DBProduct(uuid: uuid, name: tr("pr_wine_red", lang), category: alcoholCat),
            DBProduct(uuid: uuid, name: tr("pr_wine_white", lang), category: alcoholCat),
            DBProduct(uuid: uuid, name: tr("pr_sherry", lang), category: alcoholCat),
            
            // nuts
            DBProduct(uuid: uuid, name: tr("pr_nuts", lang), category: nutsCat),
            DBProduct(uuid: uuid, name: tr("pr_pine_nuts", lang), category: nutsCat),
            DBProduct(uuid: uuid, name: tr("pr_hazel_nuts", lang), category: nutsCat),
            
            // oil
            DBProduct(uuid: uuid, name: tr("pr_oil", lang), category: oilCat),
            DBProduct(uuid: uuid, name: tr("pr_oil_olives", lang), category: oilCat),
            DBProduct(uuid: uuid, name: tr("pr_oil_sunflower", lang), category: oilCat),
            DBProduct(uuid: uuid, name: tr("pr_oil_rapeseed", lang), category: oilCat),
            DBProduct(uuid: uuid, name: tr("pr_oil_margarine", lang), category: oilCat),
            DBProduct(uuid: uuid, name: tr("pr_oil_butter", lang), category: oilCat),
            
            // hygienic
            DBProduct(uuid: uuid, name: tr("pr_soap_body", lang), category: hygienicCat),
            DBProduct(uuid: uuid, name: tr("pr_soap_hands", lang), category: hygienicCat),
            DBProduct(uuid: uuid, name: tr("pr_shampoo", lang), category: hygienicCat),
            DBProduct(uuid: uuid, name: tr("pr_toothpaste", lang), category: hygienicCat),
            DBProduct(uuid: uuid, name: tr("pr_deodorant", lang), category: hygienicCat),
            DBProduct(uuid: uuid, name: tr("pr_tooth_brush", lang), category: hygienicCat),
            DBProduct(uuid: uuid, name: tr("pr_listerine", lang), category: hygienicCat),
            DBProduct(uuid: uuid, name: tr("pr_dental_floss", lang), category: hygienicCat),
            DBProduct(uuid: uuid, name: tr("pr_cotton", lang), category: hygienicCat),
            DBProduct(uuid: uuid, name: tr("pr_cotton_buds", lang), category: hygienicCat),
//            DBProduct(uuid: uuid, name: tr("pr_diapers", lang), category: hygienicCat),
//            DBProduct(uuid: uuid, name: tr("pr_sanitary_towel", lang), category: hygienicCat),
//            DBProduct(uuid: uuid, name: tr("pr_tampons", lang), category: hygienicCat),
//            DBProduct(uuid: uuid, name: tr("pr_razors", lang), category: hygienicCat),
//            DBProduct(uuid: uuid, name: tr("pr_shaving_cream", lang), category: hygienicCat),

            // clothes
            DBProduct(uuid: uuid, name: tr("pr_socks", lang), category: clothesCat),
            DBProduct(uuid: uuid, name: tr("pr_tshirts", lang), category: clothesCat),
            DBProduct(uuid: uuid, name: tr("pr_underwear", lang), category: clothesCat),
            DBProduct(uuid: uuid, name: tr("pr_pants", lang), category: clothesCat),
            DBProduct(uuid: uuid, name: tr("pr_shoes", lang), category: clothesCat),
            
            // cleaning
            DBProduct(uuid: uuid, name: tr("pr_cleaning_agent", lang), category: cleaningCat),
            DBProduct(uuid: uuid, name: tr("pr_cleaning_agent_toilet", lang), category: cleaningCat),
            DBProduct(uuid: uuid, name: tr("pr_cleaning_agent_windows", lang), category: cleaningCat),
            DBProduct(uuid: uuid, name: tr("pr_sponge", lang), category: cleaningCat),
            DBProduct(uuid: uuid, name: tr("pr_sponge_wire", lang), category: cleaningCat),
            DBProduct(uuid: uuid, name: tr("pr_mop", lang), category: cleaningCat),
            DBProduct(uuid: uuid, name: tr("pr_brush", lang), category: cleaningCat),
            DBProduct(uuid: uuid, name: tr("pr_waste_bags_5", lang), category: cleaningCat),
            DBProduct(uuid: uuid, name: tr("pr_waste_bags_10", lang), category: cleaningCat),
            DBProduct(uuid: uuid, name: tr("pr_waste_bags_30", lang), category: cleaningCat),
            DBProduct(uuid: uuid, name: tr("pr_waste_bags_60", lang), category: cleaningCat),
            
            // dips
            DBProduct(uuid: uuid, name: tr("pr_salad_dressing", lang), category: dipsCat),
            DBProduct(uuid: uuid, name: tr("pr_dip", lang), category: dipsCat),
            DBProduct(uuid: uuid, name: tr("pr_pesto", lang), category: dipsCat),
            
            // fish
            DBProduct(uuid: uuid, name: tr("pr_salmon", lang), category: fishCat),
            DBProduct(uuid: uuid, name: tr("pr_trout", lang), category: fishCat),
            DBProduct(uuid: uuid, name: tr("pr_tuna", lang), category: fishCat),
            DBProduct(uuid: uuid, name: tr("pr_herring", lang), category: fishCat),
            DBProduct(uuid: uuid, name: tr("pr_anchovies", lang), category: fishCat),
            DBProduct(uuid: uuid, name: tr("pr_fish_sticks", lang), category: fishCat),
            
            // fried
            DBProduct(uuid: uuid, name: tr("pr_fries", lang), category: friedCat),
            DBProduct(uuid: uuid, name: tr("pr_fries_oven", lang), category: friedCat),
            
            // bakery
            DBProduct(uuid: uuid, name: tr("pr_cake", lang), category: bakeryCat),
            DBProduct(uuid: uuid, name: tr("pr_pudding", lang), category: bakeryCat),
            DBProduct(uuid: uuid, name: tr("pr_curd", lang), category: bakeryCat),
            
            // cheese
            DBProduct(uuid: uuid, name: tr("pr_cheese", lang), category: cheeseCat),
            DBProduct(uuid: uuid, name: tr("pr_parmesan", lang), category: cheeseCat),
            DBProduct(uuid: uuid, name: tr("pr_cheddar", lang), category: cheeseCat),
            DBProduct(uuid: uuid, name: tr("pr_gouda", lang), category: cheeseCat),
            
            // beans
            DBProduct(uuid: uuid, name: tr("pr_beans_kidney", lang), category: beansCat),
            DBProduct(uuid: uuid, name: tr("pr_beans_string", lang), category: beansCat),
            DBProduct(uuid: uuid, name: tr("pr_corn", lang), category: beansCat),
            
            // eggs
            DBProduct(uuid: uuid, name: tr("pr_eggs", lang), category: eggsCat),
            
            // spread
            DBProduct(uuid: uuid, name: tr("pr_marmelade", lang), category: spreadCat),
            
            // cereal
            DBProduct(uuid: uuid, name: tr("pr_corn_flakes", lang), category: cerealCat),
            DBProduct(uuid: uuid, name: tr("pr_muesli", lang), category: cerealCat),
            
            // bread (bakery)
            DBProduct(uuid: uuid, name: tr("pr_toast_bread", lang), category: cleaningCat),
            DBProduct(uuid: uuid, name: tr("pr_bread", lang), category: cleaningCat),
            DBProduct(uuid: uuid, name: tr("pr_baguette", lang), category: cleaningCat),
            
            // cold cut
            DBProduct(uuid: uuid, name: tr("pr_bacon", lang), category: coldCutCat),
            DBProduct(uuid: uuid, name: tr("pr_ham", lang), category: coldCutCat),
            DBProduct(uuid: uuid, name: tr("pr_salami", lang), category: coldCutCat),
            DBProduct(uuid: uuid, name: tr("pr_mortadella", lang), category: coldCutCat),
            
            // milk
            DBProduct(uuid: uuid, name: tr("pr_milk", lang), category: milkCat),
            DBProduct(uuid: uuid, name: tr("pr_cream", lang), category: milkCat),
            DBProduct(uuid: uuid, name: tr("pr_sour_cream", lang), category: milkCat),
            DBProduct(uuid: uuid, name: tr("pr_whipped_cream", lang), category: milkCat),
            
            // oven
            DBProduct(uuid: uuid, name: tr("pr_pizza", lang), category: ovenCat),
            
            // stationeries
            DBProduct(uuid: uuid, name: tr("pr_paper", lang), category: stationeriesCat),
            DBProduct(uuid: uuid, name: tr("pr_pens", lang), category: stationeriesCat),
            DBProduct(uuid: uuid, name: tr("pr_pencils", lang), category: stationeriesCat),
            DBProduct(uuid: uuid, name: tr("pr_notebooks", lang), category: stationeriesCat),
            DBProduct(uuid: uuid, name: tr("pr_sharpeners", lang), category: stationeriesCat),
            DBProduct(uuid: uuid, name: tr("pr_erasers", lang), category: stationeriesCat),
            DBProduct(uuid: uuid, name: tr("pr_stapler", lang), category: stationeriesCat),
            DBProduct(uuid: uuid, name: tr("pr_cartridges", lang), category: stationeriesCat),

            // tea & coffee
            DBProduct(uuid: uuid, name: tr("pr_green_tea", lang), category: teaAndCoffeeCat),
            DBProduct(uuid: uuid, name: tr("pr_black_tea", lang), category: teaAndCoffeeCat),
            DBProduct(uuid: uuid, name: tr("pr_mint_tea", lang), category: teaAndCoffeeCat),
            DBProduct(uuid: uuid, name: tr("pr_camellia_tea", lang), category: teaAndCoffeeCat),
            DBProduct(uuid: uuid, name: tr("pr_coffee", lang), category: teaAndCoffeeCat),
            
            // sweets
            DBProduct(uuid: uuid, name: tr("pr_chewing_gum", lang), category: sweetsCat),
            DBProduct(uuid: uuid, name: tr("pr_catamels", lang), category: sweetsCat),
            DBProduct(uuid: uuid, name: tr("pr_chocolates", lang), category: sweetsCat),
            DBProduct(uuid: uuid, name: tr("pr_ice_cream", lang), category: sweetsCat),
            DBProduct(uuid: uuid, name: tr("pr_mints", lang), category: sweetsCat),
            DBProduct(uuid: uuid, name: tr("pr_marshmallows", lang), category: sweetsCat)
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
