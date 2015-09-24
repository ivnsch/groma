//
//  SectionSuggestionMapper.swift
//  shoppin
//
//  Created by ischuetz on 24/09/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

class SectionSuggestionMapper {
    
    class func dbWithSection(section: Section) -> DBSectionSuggestion {
        let dbSection = DBSectionSuggestion()
        dbSection.name = section.name
        return dbSection
    }
    
    class func suggestionWithDB(dbSuggestion: DBSectionSuggestion) -> Suggestion {
        return Suggestion(name: dbSuggestion.name)
    }
}