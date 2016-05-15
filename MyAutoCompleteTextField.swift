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

    @IBInspectable var fontType: Int = -1
    
    var myDelegate: MyAutoCompleteTextFieldDelegate?

    private var borderLayer: CALayer?
    private var v: UIView?
    
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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        if let size = LabelMore.mapToFontSize(fontType) {
            self.font = UIFont.systemFontOfSize(size)
        }
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
    
    override func autoCompleteTermsDidSort(completions: [AnyObject]!) {
        super.autoCompleteTermsDidSort(completions)
        
        self.v?.removeFromSuperview()
        if !completions.isEmpty {
            let v = UIView(frame: autoCompleteTableView.bounds.copy(autoCompleteTableView.frame.origin.x, y: autoCompleteTableView.frame.maxY - 2, height: 10))
            v.backgroundColor = UIColor.whiteColor()

            
            let width: CGFloat = v.bounds.width
            let height: CGFloat = v.bounds.height
            let radius: CGFloat = 9
            let maskPath = CGPathCreateMutable()
            
            CGPathMoveToPoint (maskPath, nil, width, 0)
            CGPathAddLineToPoint (maskPath, nil, width, height - radius)
            CGPathAddArcToPoint (maskPath, nil, width, height, width - radius, height, radius)
            CGPathAddLineToPoint (maskPath, nil, radius, height)
            CGPathAddArcToPoint (maskPath, nil, 0, height, 0, height - radius, radius)
            CGPathAddLineToPoint (maskPath, nil, 0, 0)
            
            CGPathCloseSubpath (maskPath)
            
            let maskLayer = CAShapeLayer()
            maskLayer.frame = v.bounds
            maskLayer.path  = maskPath
            v.layer.mask = maskLayer
            
            
            let borderPath = CGPathCreateMutable()
            CGPathMoveToPoint (borderPath, nil, width, 0)
            CGPathAddLineToPoint (borderPath, nil, width, height - radius)
            CGPathAddArcToPoint (borderPath, nil, width, height, width - radius, height, radius)
            CGPathAddLineToPoint (borderPath, nil, radius, height)
            CGPathAddArcToPoint (borderPath, nil, 0, height, 0, height - radius, radius)
            CGPathAddLineToPoint (borderPath, nil, 0, 0)
//            CGPathCloseSubpath (borderPath)
            
            self.borderLayer?.removeFromSuperlayer()
    
            let borderLayer = CAShapeLayer()
            borderLayer.frame = v.bounds
            borderLayer.path  = borderPath
            borderLayer.lineWidth   = 1
            borderLayer.strokeColor = UIColor.grayColor().CGColor
            borderLayer.fillColor   = UIColor.clearColor().CGColor
            v.layer.addSublayer(borderLayer)
            self.borderLayer = borderLayer

            superview?.addSubview(v)
            superview?.bringSubviewToFront(v)
            
            self.v = v
        }
    }
    
    override func closeAutoCompleteTableView() {
        super.closeAutoCompleteTableView()
        v?.removeFromSuperview()
    }
}
