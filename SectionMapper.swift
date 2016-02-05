//
//  SectionMapper.swift
//  shoppin
//
//  Created by ischuetz on 23.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import Foundation

class SectionMapper {
    
    class func sectionWithDB(dbSection: DBSection) -> Section {
        return Section(uuid: dbSection.uuid, name: dbSection.name, todoOrder: dbSection.todoOrder, doneOrder: dbSection.doneOrder, stashOrder: dbSection.stashOrder)
    }
    
    class func SectionWithRemote(remoteSection: RemoteSection) -> Section {
        return Section(uuid: remoteSection.uuid, name: remoteSection.name, todoOrder: remoteSection.todoOrder, doneOrder: remoteSection.doneOrder, stashOrder: remoteSection.stashOrder)
    }
    
    class func dbWithSection(section: Section) -> DBSection {
        let dbSection = DBSection()
        dbSection.uuid = section.uuid
        dbSection.name = section.name
        dbSection.todoOrder = section.todoOrder
        dbSection.doneOrder = section.doneOrder
        dbSection.stashOrder = section.stashOrder
        return dbSection
    }
    
    class func dbWithRemote(section: RemoteSection) -> DBSection {
        let dbSection = DBSection()
        dbSection.uuid = section.uuid
        dbSection.name = section.name
        dbSection.todoOrder = section.todoOrder
        dbSection.doneOrder = section.doneOrder
        dbSection.stashOrder = section.stashOrder
        return dbSection
    }
}
