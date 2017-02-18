//
//  FractionProviderImpl.swift
//  Providers
//
//  Created by Ivan Schuetz on 18/02/2017.
//
//

import UIKit
import RealmSwift

class FractionProviderImpl: FractionProvider {

    func fractions(_ handler: @escaping (ProviderResult<RealmSwift.List<DBFraction>>) -> Void) {
        if let fractions = DBProv.fractionProvider.fractions() {
            handler(ProviderResult(status: .success, sucessResult: fractions))
        } else {
            handler(ProviderResult(status: .databaseUnknown))
        }
    }
    
    func add(fraction: DBFraction, _ handler: @escaping (ProviderResult<Bool>) -> Void) {
        let (success, isNew) = DBProv.fractionProvider.add(fraction: fraction)
        if success {
            handler(ProviderResult(status: .success, sucessResult: isNew))
        } else {
            handler(ProviderResult(status: .databaseUnknown))
        }
    }
    
    func remove(fraction: DBFraction, _ handler: @escaping (ProviderResult<Any>) -> Void) {
        let success = DBProv.fractionProvider.remove(fraction: fraction)
        handler(ProviderResult(status: success ? .success: .databaseUnknown))
    }
}
