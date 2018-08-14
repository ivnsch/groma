//
//  TestUtils.swift
//  ProvidersTests
//
//  Created by Ivan Schuetz on 08.01.18.
//

import UIKit
import Providers

let nonExistentString: String = "nonexistent"
let specialCharsTestString: String = "_s2>,.^ && | .* <'2@# ü^~👻 \t A\\_-    "

func uuid() -> String {
    return UUID().uuidString
}

extension Array where Element: WithUuid {

    func sortedByUuid() -> [Element] {
        return sorted(by: { (item1, item2) -> Bool in
            item1.uuid > item2.uuid
        })
    }
}

extension Array where Element == BaseQuantity {

    func sortedByVal() -> [Element] {
        return sorted(by: { (item1, item2) -> Bool in
            item1.val > item2.val
        })
    }
}

extension Array where Element == DBTextSpan {

    func sortedByStart() -> [Element] {
        return sorted(by: { (item1, item2) -> Bool in
            item1.start > item2.start
        })
    }
}
