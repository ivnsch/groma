//
//  Sequence+Convenience.swift
//  Providers
//
//  Created by Ivan Schuetz on 26.09.17.
//

import Foundation

extension Sequence {

    func exists(_ predicate: (Self.Iterator.Element) -> Bool) -> Bool {
        return findFirst(predicate) != nil
    }

    func findFirst(_ predicate: (Self.Iterator.Element) -> Bool) -> Self.Iterator.Element? {
        for element in self {
            if predicate(element) {
                return element
            }
        }
        return nil
    }
}
