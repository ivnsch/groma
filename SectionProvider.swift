//
//  SectionProvider.swift
//  shoppin
//
//  Created by ischuetz on 05/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

protocol SectionProvider {

    // TODO! use list
    func loadSection(name: String, list: List, handler: ProviderResult<Section> -> ())
    
    func remove(section: Section, _ handler: ProviderResult<Any> -> ())
    
    func update(sections: [Section], _ handler: ProviderResult<Any> -> ())

    func sectionSuggestions(handler: ProviderResult<[Suggestion]> -> ())
    
    func sections(names: [String], handler: ProviderResult<[Section]> -> ())
    
    /**
    Utility method to refactor common code in ListItemsProviderImpl and ListItemGroupProviderImpl when adding new list or group items
    Tries to load using unique (name), if existent overrides fields with corresponding input, if not existent creates a new one
    TODO use results like everywhere else, maybe put in a different specific utility class this is rather provider-internal
    
    - parameter possibleNewSectionOrder: if the section is determined to be new, position of section in list. If the section already exists this is not used. If nil this will be at the end of the list (an additional database fetch will be made to count the sections).
    */
    func mergeOrCreateSection(sectionName: String, possibleNewOrder: Int?, list: List, _ handler: ProviderResult<Section> -> Void)
}