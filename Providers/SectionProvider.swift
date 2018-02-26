//
//  SectionProvider.swift
//  shoppin
//
//  Created by ischuetz on 05/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

public protocol SectionProvider {

//    func sections(list: List, handler: @escaping (ProviderResult<Results<Section>>) -> Void)

    func loadSection(_ name: String, list: List, handler: @escaping (ProviderResult<Section?>) -> ())

    func update(_ section: Section, input: SectionInput, _ handler: @escaping (ProviderResult<Section>) -> Void)
    
    func remove(_ section: Section, notificationTokens: [NotificationToken], _ handler: @escaping (ProviderResult<Any>) -> Void)
    
    func remove(_ sectionUnique: SectionUnique, notificationTokens: [NotificationToken], listUuid: String?, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> ())
    
    // Removes all the sections found with given name (across lists)
    func removeAllWithName(_ sectionName: String, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> Void)
    
    // Gets suggestions both from section and category names
    func sectionSuggestionsContainingText(_ text: String, _ handler: @escaping (ProviderResult<[String]>) -> ())
    
    func sections(_ names: [String], list: List, handler: @escaping (ProviderResult<[Section]>) -> ())
    
    func move(from: Int, to: Int, sections: RealmSwift.List<Section>, notificationToken: NotificationToken, _ handler: @escaping (ProviderResult<Any>) -> Void)
    
    /**
    Utility method to refactor common code in ListItemsProviderImpl and ProductGroupProviderImpl when adding new list or group items
    Tries to load using unique (name), if existent overrides fields with corresponding input, if not existent creates a new one
    TODO use results like everywhere else, maybe put in a different specific utility class this is rather provider-internal
    
    - parameter possibleNewSectionOrder: if the section is determined to be new, position of section in list. If the section already exists this is not used. If nil this will be at the end of the list (an additional database fetch will be made to count the sections).
    */
    func mergeOrCreateSection(_ sectionName: String, sectionColor: UIColor, status: ListItemStatus, possibleNewOrder: ListItemStatusOrder?, list: List, _ handler: @escaping (ProviderResult<Section>) -> Void)
}
