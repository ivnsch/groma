//
//  UnitsContainer.swift
//  Providers
//
//  Created by Ivan Schuetz on 18.12.17.
//

import UIKit
import RealmSwift

class UnitsContainer: Object {
    var units = RealmSwift.List<Unit>()
}
