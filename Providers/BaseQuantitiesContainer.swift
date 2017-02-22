//
//  BaseQuantitiesContainer.swift
//  Providers
//
//  Created by Ivan Schuetz on 22/02/2017.
//
//

import UIKit
import RealmSwift

class BaseQuantitiesContainer: Object {
    
    var bases = RealmSwift.List<BaseQuantity>()
}
