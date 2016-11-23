//
//  SectionMapper.swift
//  shoppin
//
//  Created by ischuetz on 23.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import Foundation

class SectionMapper {
    
    class func sectionWithDB(_ dbSection: DBSection) -> Section {
        let list = ListMapper.listWithDB(dbSection.list)
        return Section(uuid: dbSection.uuid, name: dbSection.name, color: dbSection.color(), list: list, todoOrder: dbSection.todoOrder, doneOrder: dbSection.doneOrder, stashOrder: dbSection.stashOrder, lastServerUpdate: dbSection.lastServerUpdate)
    }
    
    class func SectionWithRemote(_ remoteSection: RemoteSection, list: List) -> Section {
        return Section(uuid: remoteSection.uuid, name: remoteSection.name, color: remoteSection.color, list: list, todoOrder: remoteSection.todoOrder, doneOrder: remoteSection.doneOrder, stashOrder: remoteSection.stashOrder, lastServerUpdate: remoteSection.lastUpdate)
    }
    
    class func dbWithSection(_ section: Section) -> DBSection {
        let dbSection = DBSection()
        dbSection.uuid = section.uuid
        dbSection.name = section.name
        dbSection.setColor(section.color)
        dbSection.list = ListMapper.dbWithList(section.list)
        dbSection.todoOrder = section.todoOrder
        dbSection.doneOrder = section.doneOrder
        dbSection.stashOrder = section.stashOrder
        if let lastServerUpdate = section.lastServerUpdate { // needs if let because Realm doesn't support optional NSDate yet
            dbSection.lastServerUpdate = lastServerUpdate
        }
        return dbSection
    }
    
    class func dbWithRemote(_ section: RemoteSection, list: List) -> DBSection {
        let dbSection = DBSection()
        dbSection.uuid = section.uuid
        dbSection.name = section.name
        dbSection.setColor(section.color)
        dbSection.list = ListMapper.dbWithList(list)
        dbSection.todoOrder = section.todoOrder
        dbSection.doneOrder = section.doneOrder
        dbSection.stashOrder = section.stashOrder
        dbSection.dirty = false
        dbSection.lastServerUpdate = section.lastUpdate
        return dbSection
    }
}
