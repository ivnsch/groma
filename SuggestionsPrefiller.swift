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

    private let dbProvider = RealmListItemProvider()

    /**
    * Generates the prefill Realm file.
    * When it's done, add the generated file to build phases > copy bundle resources, in target where it's needed.
    * The apps will prefill the database with it in the first launch.
    *
    * This is not meant to be called during normal execution.
    */
    func prefill(onFinished: VoidFunction? = nil) {

        // note that this doesn't necessarily have to be sequential, but Realm is beta currently, for now like this
        prefillSectionSuggestions {[weak self] in
            self?.prefillProductSuggestions {
                print("Finished prefilling")
                self?.writeDBCopy(NSHomeDirectory() + "/Documents/prefill.realm")
                onFinished?()
            }
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
    
    private func prefillSectionSuggestions(onFinished: VoidFunction? = nil) {
        dbProvider.saveSectionSuggestions(sectionSuggestions) {saved in
            if saved {
                onFinished?()
            } else {
                print("Error saving section suggestions")
            }
        }
    }
    
    private func prefillProductSuggestions(onFinished: VoidFunction? = nil) {
        dbProvider.saveProductSuggestions(productSuggestions) {saved in
            if saved {
                onFinished?()
            } else {
                print("Error saving product suggestions")
            }
        }
    }
}


private let productSuggestions = [
    Suggestion(name: "Apples"),
    Suggestion(name: "Peaches"),
    Suggestion(name: "Pork meat"),
    Suggestion(name: "Cat sand"),
    Suggestion(name: "Black Tea"),
    Suggestion(name: "Rice"),
    Suggestion(name: "Coca cola"),
    Suggestion(name: "Salt"),
    Suggestion(name: "Suger"),
    Suggestion(name: "Eggs"),
    Suggestion(name: "Bacon"),
    Suggestion(name: "Milk"),
    Suggestion(name: "Watermelon"),
    Suggestion(name: "Ice"),
    Suggestion(name: "Bread")
]

private let sectionSuggestions = [
    Suggestion(name: "Fruits"),
    Suggestion(name: "Vegetables"),
    Suggestion(name: "Meat"),
    Suggestion(name: "Drinks"),
    Suggestion(name: "Cleaning")
]