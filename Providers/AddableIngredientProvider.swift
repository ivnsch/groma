//
//  AddableIngredientProvider.swift
//  Providers
//
//  Created by Ivan Schuetz on 21/01/2017.
//
//

import UIKit

public protocol AddableIngredientProvider {

    func addableIngredients(recipe: Recipe, handler: @escaping (ProviderResult<AddableIngredients>) -> Void)
}
