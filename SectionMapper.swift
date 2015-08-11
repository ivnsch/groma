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
        return Section(uuid: dbSection.uuid, name: dbSection.name)
    }
    
    class func SectionWithRemote(remoteSection: RemoteSection) -> Section {
        return Section(uuid: remoteSection.uuid, name: remoteSection.name)
    }
    
    class func dbWithSection(section: Section) -> DBSection {
        let dbSection = DBSection()
        dbSection.uuid = section.uuid
        dbSection.name = section.name
        return dbSection
    }
    
    class func dbWithRemote(section: RemoteSection) -> DBSection {
        let dbSection = DBSection()
        dbSection.uuid = section.uuid
        dbSection.name = section.name
        return dbSection
    }
}
