//
//  SectionMapper.swift
//  shoppin
//
//  Created by ischuetz on 23.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import Foundation

class SectionMapper {
    class func sectionWithCD(cdSection: CDSection) -> Section {
        return Section(uuid: cdSection.uuid, name: cdSection.name)
    }
    
    class func SectionWithRemote(remoteSection: RemoteSection) -> Section {
        return Section(uuid: remoteSection.uuid, name: remoteSection.name)
    }
}
