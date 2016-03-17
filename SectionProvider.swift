//
//  SectionProvider.swift
//  shoppin
//
//  Created by ischuetz on 05/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

protocol SectionProvider {

    func loadSection(name: String, list: List, handler: ProviderResult<Section?> -> ())
    
    func add(section: Section, remote: Bool, _ handler: ProviderResult<Any> -> ())

    func update(section: Section, remote: Bool, _ handler: ProviderResult<Any> -> ())
    
    func update(sections: [Section], remote: Bool, _ handler: ProviderResult<Any> -> ())

    func remove(section: Section, remote: Bool, _ handler: ProviderResult<Any> -> ())
    
    func remove(sectionUuid: String, remote: Bool, _ handler: ProviderResult<Any> -> ())
    
    // Gets suggestions both from section and category names
    func sectionSuggestionsContainingText(text: String, _ handler: ProviderResult<[String]> -> ())
    
    func sections(names: [String], list: List, handler: ProviderResult<[Section]> -> ())
    
    /**
    Utility method to refactor common code in ListItemsProviderImpl and ListItemGroupProviderImpl when adding new list or group items
    Tries to load using unique (name), if existent overrides fields with corresponding input, if not existent creates a new one
    TODO use results like everywhere else, maybe put in a different specific utility class this is rather provider-internal
    
    - parameter possibleNewSectionOrder: if the section is determined to be new, position of section in list. If the section already exists this is not used. If nil this will be at the end of the list (an additional database fetch will be made to count the sections).
    */
    func mergeOrCreateSection(sectionName: String, status: ListItemStatus, possibleNewOrder: ListItemStatusOrder?, list: List, _ handler: ProviderResult<Section> -> Void)
}