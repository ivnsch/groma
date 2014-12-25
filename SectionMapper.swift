//
//  SectionMapper.swift
//  shoppin
//
//  Created by ischuetz on 23.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//


class SectionMapper {
    class func sectionWithCD(cdSection:CDSection) -> Section {
        return Section(name: cdSection.name)
    }
}
