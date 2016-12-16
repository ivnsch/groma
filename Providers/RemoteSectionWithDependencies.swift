//
//  RemoteSectionWithDependencies.swift
//  shoppin
//
//  Created by ischuetz on 17/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

struct RemoteSectionWithDependencies: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {
    
    let section: RemoteSection
    let list: RemoteListWithDependencies

    init?(representation: AnyObject) {
        guard
            let sectionObj = representation.value(forKeyPath: "section"),
            let section = RemoteSection(representation: sectionObj as AnyObject),
            let listObj = representation.value(forKeyPath: "list"),
            let list = RemoteListWithDependencies(representation: listObj as AnyObject)
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.section = section
        self.list = list
    }
    
    static func collection(_ representation: [AnyObject]) -> [RemoteSectionWithDependencies]? {
        var sections = [RemoteSectionWithDependencies]()
        for obj in representation {
            if let section = RemoteSectionWithDependencies(representation: obj) {
                sections.append(section)
            } else {
                return nil
            }
        }
        return sections
    }

    var debugDescription: String {
        return "{\(type(of: self)) section: \(section), list: \(list)}"
    }
}
