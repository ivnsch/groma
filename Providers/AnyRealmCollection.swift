//
//  AnyRealmCollection.swift
//  Providers
//
//  Created by Ivan Schuetz on 21.12.17.
//

import RealmSwift

extension AnyRealmCollection {

    public func findFirst(_ function: (_ element: Element) -> Bool) -> Element? {
        for e in self {
            if function(e) {
                return e
            }
        }
        return nil
    }
}
