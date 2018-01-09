//
//  RecipesContainer.swift
//  ProvidersTests
//
//  Created by Ivan Schuetz on 09.01.18.
//

import RealmSwift

class RecipesContainer: Object { // to be able to hold recipes in realm's list

    let recipes: RealmSwift.List<Recipe> = RealmSwift.List<Recipe>()
}
