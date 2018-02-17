//
//  DBTextSpan.swift
//  Providers
//
//  Created by Ivan Schuetz on 26.12.17.
//

import RealmSwift

public class DBTextSpan: Object {
    @objc public dynamic var start: Int = 0
    @objc public dynamic var length: Int = 0
    @objc public dynamic var attribute: Int = 0

    @objc public dynamic var compoundKey: String = "0-0-0"

    public convenience init(start: Int, length: Int, attribute: Int) {
        self.init()

        self.start = start
        self.length = length
        self.attribute = attribute

        compoundKey = compoundKeyValue()
    }

    public override static func primaryKey() -> String? {
        return "compoundKey"
    }

    private func compoundKeyValue() -> String {
        return "\(start)-\(length)-\(attribute)"
    }
}
