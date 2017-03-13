//
//  SectionMapper.swift
//  shoppin
//
//  Created by ischuetz on 23.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import Foundation

class SectionMapper {
    
//    class func sectionWithDB(_ dbSection: Section) -> Section {
//        return Section(uuid: dbSection.uuid, name: dbSection.name, color: dbSection.color(), list: dbSection.list, todoOrder: dbSection.todoOrder, doneOrder: dbSection.doneOrder, stashOrder: dbSection.stashOrder, lastServerUpdate: dbSection.lastServerUpdate)
//    }
    
    class func SectionWithRemote(_ remoteSection: RemoteSection, list: List) -> Section {
        fatalError("Outdated")
//        return Section(uuid: remoteSection.uuid, name: remoteSection.name, color: remoteSection.color, list: list, todoOrder: remoteSection.todoOrder, doneOrder: remoteSection.doneOrder, stashOrder: remoteSection.stashOrder, lastServerUpdate: remoteSection.lastUpdate)
    }
//    
//    class func dbWithSection(_ section: Section) -> Section {
//        let dbSection = Section()
//        dbSection.uuid = section.uuid
//        dbSection.name = section.name
//        dbSection.setColor(section.color)
//        dbSection.list = section.list
//        dbSection.todoOrder = section.todoOrder
//        dbSection.doneOrder = section.doneOrder
//        dbSection.stashOrder = section.stashOrder
//        if let lastServerUpdate = section.lastServerUpdate { // needs if let because Realm doesn't support optional NSDate yet
//            dbSection.lastServerUpdate = lastServerUpdate
//        }
//        return dbSection
//    }
    
    class func dbWithRemote(_ section: RemoteSection, list: List) -> Section {
        let dbSection = Section()
        dbSection.uuid = section.uuid
        dbSection.name = section.name
        dbSection.color = section.color
        dbSection.list = list
        dbSection.todoOrder = section.todoOrder
        dbSection.doneOrder = section.doneOrder
        dbSection.stashOrder = section.stashOrder
        dbSection.dirty = false
        dbSection.lastServerUpdate = section.lastUpdate
        return dbSection
    }
}
