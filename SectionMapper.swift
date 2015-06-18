//
//  SectionMapper.swift
//  shoppin
//
//  Created by ischuetz on 23.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//


class SectionMapper {
    class func sectionWithCD(cdSection: CDSection) -> Section {
        return Section(id: cdSection.id, name: cdSection.name)
    }
    
    class func SectionWithRemote(remoteSection: RemoteSection) -> Section {
        return Section(id: remoteSection.id, name: remoteSection.name)
    }
}
