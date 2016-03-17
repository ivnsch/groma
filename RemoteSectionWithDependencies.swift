//
//  RemoteSectionWithDependencies.swift
//  shoppin
//
//  Created by ischuetz on 17/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

struct RemoteSectionWithDependencies: ResponseObjectSerializable, CustomDebugStringConvertible {
    
    let section: RemoteSection
    let list: RemoteListWithDependencies

    init?(representation: AnyObject) {
        guard
            let sectionObj = representation.valueForKeyPath("section") as? [AnyObject],
            let section = RemoteSection(representation: sectionObj),
            let listObj = representation.valueForKeyPath("list") as? [AnyObject],
            let list = RemoteListWithDependencies(representation: listObj)
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.section = section
        self.list = list
    }

    var debugDescription: String {
        return "{\(self.dynamicType) section: \(section), list: \(list)}"
    }
}
