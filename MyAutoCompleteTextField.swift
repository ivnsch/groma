//
//  MyAutoCompleteTextField.swift
//  shoppin
//
//  Created by ischuetz on 25/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs

protocol MyAutoCompleteTextFieldDelegate {
    func onDeleteSuggestion(string: String, sender: MyAutoCompleteTextField)
}

class MyAutoCompleteTextField: MLPAutoCompleteTextField {

    var myDelegate: MyAutoCompleteTextFieldDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }
    
    private func sharedInit() {
        registerAutoCompleteCellClass(MyAutocompleteCell.self, forCellReuseIdentifier: "myAutoCompleteCell")
    }
    
    override func configureCell(cell: UITableViewCell!, atIndexPath indexPath: NSIndexPath!, withAutoCompleteString string: String!) {
        super.configureCell(cell, atIndexPath: indexPath, withAutoCompleteString: string)
        
        if var _ = cell as? MyAutocompleteCell {
            
            let button: HandlingButton = cell.contentView.viewWithTag(ViewTags.AutoCompleteCellButton) as? HandlingButton ?? {
                // Ended adding button programatically because for some reason the cell's contents from xib are not shown. It's loading the correct cell and everything but the content looks like the default cells. Removing the IB button for now.
                let button = HandlingButton(frame: CGRectMake(self.bounds.width - 50, -3, 50, cell.contentView.bounds.height)) // needs some negative y offset otherwise looks not aligned with the text label
                button.setTitle("x", forState: .Normal)
                button.titleLabel?.font = Fonts.smallLight
                button.setTitleColor(UIColor.grayColor(), forState: .Normal)
                button.tag = ViewTags.AutoCompleteCellButton
                cell.contentView.addSubview(button)
                return button
            }()
            
            button.tapHandler = {[weak self] in guard let weakSelf = self else {return}
                self?.myDelegate?.onDeleteSuggestion(string, sender: weakSelf)
            }
        } else {
            QL3("Cell is has not expected type: \(cell)")
        }
    }
}
