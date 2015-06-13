//
//  AutocompleteTextField.swift
//  shoppin
//
//  Created by ischuetz on 03/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Cocoa


protocol SuggestionsLoader {
    func loadSuggestions(callback: ([String]) -> ())
}

class AutocompleteTextField: NSTextField {
    
    private var currentSectionSearch: String?
    
    var suggestionsLoader: SuggestionsLoader?
    
    private var suggestionsStored: [String]?
    
    private var loadingSuggestions = false
    
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
        default:
            
            if !self.loadingSuggestions { // TODO better way than "locking"...
                self.loadingSuggestions = true
                
                self.suggestionsLoader?.loadSuggestions({[weak self] suggestions in
              
                    self!.sectionAutosuggestionsViewController.suggestions = suggestions
                    
                    // determine search string
                    let editor = NSApplication.sharedApplication().mainWindow?.fieldEditor(true, forObject: self)
                    let search: String = {
                        let textFieldStr = self!.stringValue
                        if let completionRange = editor?.selectedRange { // Note: we asume selectedRange is caused by autocompletion
                            return textFieldStr.substringWithRange(Range<String.Index>(start: textFieldStr.startIndex, end: advance(textFieldStr.startIndex, completionRange.location)))
                        } else {
                            return textFieldStr
                        }
                    }()
                    
                    self!.currentSectionSearch = search
                    
                    // filter with current text
                    let filteredSuggestions = search.isEmpty ? suggestions : suggestions.filter{$0.contains(search, caseInsensitive: true)}
                    self!.sectionAutosuggestionsViewController.filteredSuggestions = filteredSuggestions
                    
                    // autocomplete
                    if keyCode != 51 { // backspace - don't autocomplete
                        
                        if let first = filteredSuggestions.first {
                            let firstNSString: NSString = first
                            let range: NSRange = firstNSString.rangeOfString(search, options: .CaseInsensitiveSearch)
                            if range.location == 0 {
                                
                                let highlightRange = NSMakeRange(range.length, count(first) - range.length)
                                
                                self!.stringValue = first
                                let editor = NSApplication.sharedApplication().mainWindow?.fieldEditor(true, forObject: self)
                                editor!.selectedRange = highlightRange
                            }
                        }
                    }
                    
                    self!.loadingSuggestions = false
                })
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
