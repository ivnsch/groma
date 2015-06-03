//
//  AutocompleteTextField.swift
//  shoppin
//
//  Created by ischuetz on 03/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Cocoa

class AutocompleteTextField: NSTextField {
    
    private var currentSectionSearch: String?
    
    var suggestionsLoader: (() -> [String])?
    
    private var suggestionsStored: [String]?
    
    private var suggestions: [String] {
        return self.suggestionsStored ?? {
            if let suggestionsLoader = self.suggestionsLoader {
                let suggestions = suggestionsLoader()
                self.suggestionsStored = suggestions
                return suggestions

            } else {
                return []
            }
        }()
    }
    
    lazy var sectionAutosuggestionsViewController: AutosuggestionsTableViewController = {[weak self] in
        
        let viewController = AutosuggestionsTableViewController(suggestionConfirmed: {(suggestion: String) -> () in
            self!.sectionSuggestionSelected(suggestion)
        })!
        
        let resetToOriginalSearch: () -> () = {
            self!.window?.makeFirstResponder(self!)
            self!.stringValue = self!.currentSectionSearch ?? ""
        }
        
        viewController.upAtTopPressed = {
            resetToOriginalSearch()
        }
        
        viewController.exitPressed = {
            self!.sectionAutosuggestionsViewController.view.hidden = true
            resetToOriginalSearch()
        }
        
        viewController.suggestionSelected = {suggestion in
            self!.stringValue = suggestion
        }
        
        let sectionFrame = self!.frame
        let h: CGFloat = 100
        viewController.view.frame = CGRectMake(sectionFrame.origin.x, sectionFrame.origin.y - h, sectionFrame.size.width + 50, h)
        self!.window?.contentView.addSubview(viewController.view)
        return viewController
    }()
    
    override func keyUp(theEvent: NSEvent) {
        let keyCode = Int(theEvent.keyCode)
        switch keyCode {
        case 126:
            break
        case 125:
            self.sectionAutosuggestionsViewController.goDown()
            break
        case 53: // esc
            fallthrough
        case 36: // return
            self.sectionAutosuggestionsViewController.view.hidden = true
        case 51: // backspace - don't autocomplete
            break
        default:
            self.sectionAutosuggestionsViewController.suggestions = self.suggestions //TODO make this async or add a memory cache
            
            let editor = NSApplication.sharedApplication().mainWindow?.fieldEditor(true, forObject: self)
            let search: String = {
                let textFieldStr = self.stringValue
                if let completionRange = editor?.selectedRange { // Note: we asume selectedRange is caused by autocompletion
                    return textFieldStr.substringWithRange(Range<String.Index>(start: textFieldStr.startIndex, end: advance(textFieldStr.startIndex, completionRange.location)))
                } else {
                    return textFieldStr
                }
            }()
            
            self.currentSectionSearch = search

            let filteredSuggestions = search.isEmpty ? suggestions : suggestions.filter{$0.contains(search, caseInsensitive: true)}
            self.sectionAutosuggestionsViewController.filteredSuggestions = filteredSuggestions
            
            if let first = filteredSuggestions.first {
                let firstNSString: NSString = first
                let range: NSRange = firstNSString.rangeOfString(search, options: .CaseInsensitiveSearch)
                if range.location == 0 {
                    
                    let highlightRange = NSMakeRange(range.length, count(first) - range.length)
                    
                    self.stringValue = first
                    let editor = NSApplication.sharedApplication().mainWindow?.fieldEditor(true, forObject: self)
                    editor!.selectedRange = highlightRange
                }
            }
        }

        super.keyUp(theEvent)
    }
    
    private func sectionSuggestionSelected(suggestion: String) {
        self.stringValue = suggestion
        self.sectionAutosuggestionsViewController.view.hidden = true
        self.window?.makeFirstResponder(self)
    }
}
