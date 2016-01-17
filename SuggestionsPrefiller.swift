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

        let (categories, products) = prefillProducts()
        
        dbProvider.save(categories, products: products) {[weak self] saved in
            print("Finished prefilling")
            self?.writeDBCopy(NSHomeDirectory() + "/Documents/prefill.realm")
            onFinished?()
        }
    }
    
    private func writeDBCopy(toPath: String) {

        if let fromPath = Realm.Configuration.defaultConfiguration.path {
            print("Will write realm copy from path: \(fromPath), toPath: \(toPath)")
            do {
                try Realm().writeCopyToPath(toPath)
                
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
    
    // TODO!!! add brand to products! and unique key name + mark --- prices without mark will likely be annoying to users as they will have to edit the product (price) every time they decide to buy a different brand. Prefill would not have brands! User has to edit the prefilled products or add new ones with the brands.
    // we could add brand to name but this is going to cause space problems in the lists and looks bad
    
    private func prefillProducts() -> (categories: [ProductCategory], products: [Product]) {
        let fruitsCat = ProductCategory(uuid: uuid, name: "pf_93.fruits", color: UIColor.flatRedColor())
        let frozenFruitsCat = ProductCategory(uuid: uuid, name: "pf_93.fruits_frozen", color: UIColor.flatBlueColor())
        let vegetablesCat = ProductCategory(uuid: uuid, name: "pf_93.vegetables", color: UIColor.flatGreenColor())
        let herbsCat = ProductCategory(uuid: uuid, name: "pf_93.herbs", color: UIColor.flatGreenColorDark())
        let meatCat = ProductCategory(uuid: uuid, name: "pf_93.meat", color: UIColor.flatRedColorDark())
        let petsCat = ProductCategory(uuid: uuid, name: "pf_93.pets", color: UIColor.flatGreenColorDark())
        let bakeryCat = ProductCategory(uuid: uuid, name: "pf_93.bakery", color: UIColor.flatBrownColorDark())
        let riceCat = ProductCategory(uuid: uuid, name: "pf_93.rice", color: UIColor.flatWhiteColor())
        let nutsCat = ProductCategory(uuid: uuid, name: "pf_93.nuts", color: UIColor.flatBrownColorDark())
        let oilCat = ProductCategory(uuid: uuid, name: "pf_93.oil", color: UIColor.flatYellowColor())
        let clothesCat = ProductCategory(uuid: uuid, name: "pf_93.oil", color: UIColor.flatBlueColorDark())
        let cleaningCat = ProductCategory(uuid: uuid, name: "pf_93.cleaning", color: UIColor.flatMagentaColor())

        let milkCat = ProductCategory(uuid: uuid, name: "pf_93.milk", color: UIColor.flatYellowColor())

        let fishCat = ProductCategory(uuid: uuid, name: "pf_93.fish", color: UIColor.flatBlueColorDark())
        let pastaCat = ProductCategory(uuid: uuid, name: "pf_93.pasta", color: UIColor.flatWhiteColorDark())
        let drinksCat = ProductCategory(uuid: uuid, name: "pf_93.drinks", color: UIColor.flatBlueColor().lightenByPercentage(0.5))
        let hygienicCat = ProductCategory(uuid: uuid, name: "pf_93.hygienic", color: UIColor.flatGrayColor())
        let spicesCat = ProductCategory(uuid: uuid, name: "pf_93.spices", color: UIColor.flatBrownColor())
        let breadCat = ProductCategory(uuid: uuid, name: "pf_93.bread", color: UIColor.flatYellowColorDark())
        
        let products = [
            // fruits
            Product(uuid: uuid, name: "pf_93.peaches", price: 0, category: fruitsCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.bananas", price: 0, category: fruitsCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.apples", price: 0, category: fruitsCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.nectarines", price: 0, category: fruitsCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.cherries", price: 0, category: fruitsCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.kiwis", price: 0, category: fruitsCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.melons", price: 0, category: fruitsCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.watermelons", price: 0, category: fruitsCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.lemons", price: 0, category: fruitsCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.grapes", price: 0, category: fruitsCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.oranges", price: 0, category: fruitsCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.mandarines", price: 0, category: fruitsCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.strawberries", price: 0, category: fruitsCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.blueberries", price: 0, category: fruitsCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.cranberries", price: 0, category: fruitsCat, baseQuantity: 1, unit: .None),
            
            // frozen fruits
            Product(uuid: uuid, name: "pf_93.strawberries_frozen", price: 0, category: frozenFruitsCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.blueberries_frozen", price: 0, category: frozenFruitsCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.cranberries_frozen", price: 0, category: frozenFruitsCat, baseQuantity: 1, unit: .None),
            
            // vegetables
            Product(uuid: uuid, name: "pf_93.onions", price: 0, category: vegetablesCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.onions_red", price: 0, category: vegetablesCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.potatoes", price: 0, category: vegetablesCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.salad", price: 0, category: vegetablesCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.tomatoes", price: 0, category: vegetablesCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.paprika", price: 0, category: vegetablesCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.olives", price: 0, category: vegetablesCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.garlic", price: 0, category: vegetablesCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.carrots", price: 0, category: vegetablesCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.asparagus", price: 0, category: vegetablesCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.dumplings", price: 0, category: vegetablesCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.mashed_potatoes", price: 0, category: vegetablesCat, baseQuantity: 1, unit: .None),
            
            // herbs (fresh/dry)
            Product(uuid: uuid, name: "pf_93.parsley", price: 0, category: herbsCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.basil", price: 0, category: herbsCat, baseQuantity: 1, unit: .None),
            
            // meat
            Product(uuid: uuid, name: "pf_93.chicken", price: 0, category: meatCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.drum_sticks", price: 0, category: meatCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.chicken_wings", price: 0, category: meatCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.chops", price: 0, category: meatCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.beef_steak", price: 0, category: meatCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.beef", price: 0, category: meatCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.duck", price: 0, category: meatCat, baseQuantity: 1, unit: .None),
            
            // pets
            Product(uuid: uuid, name: "pf_93.litter", price: 0, category: petsCat, baseQuantity: 1, unit: .None),
            
            // spices
            Product(uuid: uuid, name: "pf_93.pepper", price: 0, category: spicesCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.salt", price: 0, category: spicesCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.sugar", price: 0, category: spicesCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.cinnamon", price: 0, category: spicesCat, baseQuantity: 1, unit: .None),
            
            // bakery
            Product(uuid: uuid, name: "pf_93.flour", price: 0, category: bakeryCat, baseQuantity: 1, unit: .None),
            
            // pasta
            Product(uuid: uuid, name: "pf_93.spaguetti", price: 0, category: pastaCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.noodles", price: 0, category: pastaCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.ravioli", price: 0, category: pastaCat, baseQuantity: 1, unit: .None),
            
            // rice
            Product(uuid: uuid, name: "pf_93.rice", price: 0, category: riceCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.rice_basmati", price: 0, category: riceCat, baseQuantity: 1, unit: .None),

            // drinks
            Product(uuid: uuid, name: "pf_93.water", price: 0, category: drinksCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.water_1", price: 0, category: drinksCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.club_mate", price: 0, category: drinksCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.club_mate", price: 0, category: drinksCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.cola_1", price: 0, category: drinksCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.cola_1_5", price: 0, category: drinksCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.cola_2", price: 0, category: drinksCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.fanta_1", price: 0, category: drinksCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.fanta_1_5", price: 0, category: drinksCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.fanta_2", price: 0, category: drinksCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.sprite_1", price: 0, category: drinksCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.sprite_1_5", price: 0, category: drinksCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.sprite_2", price: 0, category: drinksCat, baseQuantity: 1, unit: .None),
            
            // nuts
            Product(uuid: uuid, name: "pf_93.nuts", price: 0, category: nutsCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.pine_nuts", price: 0, category: nutsCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.hazel_nuts", price: 0, category: nutsCat, baseQuantity: 1, unit: .None),
            
            // oil
            Product(uuid: uuid, name: "pf_93.oil", price: 0, category: oilCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.oil_olives", price: 0, category: oilCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.oil_sunflower", price: 0, category: oilCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.oil_rape", price: 0, category: oilCat, baseQuantity: 1, unit: .None),
            
            // hygienic
            Product(uuid: uuid, name: "pf_93.soap_body", price: 0, category: hygienicCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.soap_hands", price: 0, category: hygienicCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.soap_body_liquid", price: 0, category: hygienicCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.soap_hands_liquid", price: 0, category: hygienicCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.shampoo", price: 0, category: hygienicCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.toothpaste", price: 0, category: hygienicCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.deodorant", price: 0, category: hygienicCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.tooth_brush", price: 0, category: hygienicCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.listerine", price: 0, category: hygienicCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.dental_floss", price: 0, category: hygienicCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.cotton", price: 0, category: hygienicCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.cotton_buds", price: 0, category: hygienicCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.diapers", price: 0, category: hygienicCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.sanitary_towel", price: 0, category: hygienicCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.tampons", price: 0, category: hygienicCat, baseQuantity: 1, unit: .None),
            
            // clothes
            Product(uuid: uuid, name: "pf_93.socks", price: 0, category: clothesCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.tshirts", price: 0, category: clothesCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.underwear", price: 0, category: clothesCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.pants", price: 0, category: clothesCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.shoes", price: 0, category: clothesCat, baseQuantity: 1, unit: .None),
            
            // cleaning
            Product(uuid: uuid, name: "pf_93.cleaning_agent", price: 0, category: drinksCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.cleaning_agent_toilet", price: 0, category: meatCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.cleaning_agent_windows", price: 0, category: meatCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.sponge", price: 0, category: pastaCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.sponge_wire", price: 0, category: milkCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.mop", price: 0, category: drinksCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.brush", price: 0, category: vegetablesCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.waste_bags_5", price: 0, category: vegetablesCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.waste_bags_10", price: 0, category: drinksCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.waste_bags_30", price: 0, category: vegetablesCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.waste_bags_60", price: 0, category: fruitsCat, baseQuantity: 1, unit: .None),
            
            Product(uuid: uuid, name: "pf_93.salad_dressing", price: 0, category: meatCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.dip", price: 0, category: meatCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.pesto", price: 0, category: meatCat, baseQuantity: 1, unit: .None),
            
            Product(uuid: uuid, name: "pf_93.salmon", price: 0, category: pastaCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.trout", price: 0, category: milkCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.tuna", price: 0, category: drinksCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.fish_sticks", price: 0, category: drinksCat, baseQuantity: 1, unit: .None),

            Product(uuid: uuid, name: "pf_93.fries", price: 0, category: drinksCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.fries_oven", price: 0, category: drinksCat, baseQuantity: 1, unit: .None),
            
            Product(uuid: uuid, name: "pf_93.cake", price: 0, category: vegetablesCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.pudding", price: 0, category: fishCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.curd", price: 0, category: fishCat, baseQuantity: 1, unit: .None),
            
            Product(uuid: uuid, name: "pf_93.cheese", price: 0, category: fruitsCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.parmesan", price: 0, category: fruitsCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.cheddar", price: 0, category: fruitsCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.gouda", price: 0, category: fruitsCat, baseQuantity: 1, unit: .None),

            Product(uuid: uuid, name: "pf_93.beans_kidney", price: 0, category: vegetablesCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.beans_string", price: 0, category: vegetablesCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.beans_string", price: 0, category: vegetablesCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.corn", price: 0, category: fruitsCat, baseQuantity: 1, unit: .None),
            
            Product(uuid: uuid, name: "pf_93.eggs", price: 0, category: cleaningCat, baseQuantity: 1, unit: .None),

            Product(uuid: uuid, name: "pf_93.marmelade", price: 0, category: cleaningCat, baseQuantity: 1, unit: .None),

            Product(uuid: uuid, name: "pf_93.corn_flakes", price: 0, category: cleaningCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.muesli", price: 0, category: cleaningCat, baseQuantity: 1, unit: .None),
            
            Product(uuid: uuid, name: "pf_93.toast_bread", price: 0, category: cleaningCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.bread", price: 0, category: cleaningCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.baguette", price: 0, category: cleaningCat, baseQuantity: 1, unit: .None),
            
            Product(uuid: uuid, name: "pf_93.bacon", price: 0, category: cleaningCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.ham", price: 0, category: hygienicCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.mortadella", price: 0, category: hygienicCat, baseQuantity: 1, unit: .None),

            Product(uuid: uuid, name: "pf_93.milk", price: 0, category: drinksCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.cream", price: 0, category: drinksCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.sour_cream", price: 0, category: drinksCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.whipped_cream", price: 0, category: drinksCat, baseQuantity: 1, unit: .None),
            
            Product(uuid: uuid, name: "pf_93.pizza", price: 0, category: drinksCat, baseQuantity: 1, unit: .None),
            
            Product(uuid: uuid, name: "pf_93.paper", price: 0, category: spicesCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.pens", price: 0, category: spicesCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.pencils", price: 0, category: hygienicCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.notebooks", price: 0, category: breadCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.sharpeners", price: 0, category: breadCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.erasers", price: 0, category: breadCat, baseQuantity: 1, unit: .None),
            Product(uuid: uuid, name: "pf_93.stapler", price: 0, category: breadCat, baseQuantity: 1, unit: .None)
        ]
        
        let categories = [fruitsCat, vegetablesCat, milkCat, meatCat, fishCat, pastaCat, drinksCat, cleaningCat, hygienicCat, spicesCat, breadCat]
        
        return (categories, products)
    }
}
