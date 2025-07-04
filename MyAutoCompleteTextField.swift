//
//  MyAutoCompleteTextField.swift
//  shoppin
//
//  Created by ischuetz on 25/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit

import Providers

@objc protocol MyAutoCompleteTextFieldDelegate: class {
    func onDeleteSuggestion(_ string: String, sender: MyAutoCompleteTextField)
}

@IBDesignable
class MyAutoCompleteTextField: MLPAutoCompleteTextField {

    @IBInspectable var fontType: Int = -1
    
    @IBOutlet weak var myDelegate: MyAutoCompleteTextFieldDelegate?

    fileprivate var borderLayer: CALayer?
    fileprivate var v: UIView?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }
    
    fileprivate func sharedInit() {
        registerAutoCompleteCellClass(MyAutocompleteCell.self, forCellReuseIdentifier: "myAutoCompleteCell")
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        if let size = LabelMore.mapToFontSize(fontType) {
            self.font = UIFont.systemFont(ofSize: size)
        }
    }
    
    override func configureCell(_ cell: UITableViewCell!, at indexPath: IndexPath!, withAutoComplete string: String!) {
        super.configureCell(cell, at: indexPath, withAutoComplete: string)
        
        if var _ = cell as? MyAutocompleteCell {
            
            let button: HandlingImageView = cell.contentView.viewWithTag(ViewTags.AutoCompleteCellButton) as? HandlingImageView ?? {
                // Ended adding button programatically because for some reason the cell's contents from xib are not shown. It's loading the correct cell and everything but the content looks like the default cells. Removing the IB button for now.
                let button = HandlingImageView()
                button.frame = CGRect(x: self.bounds.width - 50, y: -3, width: 50, height: cell.contentView.bounds.height)
                button.image = UIImage(named: "cross")?
//                    .withAlignmentRectInsets(UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)) // seems not to work...
                    .imageScaled(to: CGSize(width: 8, height: 8))
                    .withRenderingMode(.alwaysTemplate)
                button.contentMode = .center
                button.tintColor = UIColor.lightGray
                button.tag = ViewTags.AutoCompleteCellButton
                cell.contentView.addSubview(button)
                return button
            }()

            button.isUserInteractionEnabled = true

            button.touchHandler = {[weak self] in guard let weakSelf = self else {return}
                self?.myDelegate?.onDeleteSuggestion(string, sender: weakSelf)
            }
        } else {
            logger.w("Cell is has not expected type: \(cell)")
        }
    }

    override func autoCompleteTermsDidSort(_ completions: [Any]!) {
        super.autoCompleteTermsDidSort(completions)
        
        self.v?.removeFromSuperview()
        if !completions.isEmpty {
            let v = UIView(frame: autoCompleteTableView.bounds.copy(autoCompleteTableView.frame.origin.x, y: autoCompleteTableView.frame.maxY - 2, height: 10))
            v.backgroundColor = UIColor.white

            
            let width: CGFloat = v.bounds.width
            let height: CGFloat = v.bounds.height
            let radius: CGFloat = 9
            let maskPath = CGMutablePath()
            
            maskPath.move(to: CGPoint(x: width, y: 0))
            maskPath.addLine(to: CGPoint(x: width, y: height - radius))
            maskPath.addArc(tangent1End: CGPoint(x: width, y: height), tangent2End: CGPoint(x: width - radius, y: height), radius: radius)
            maskPath.addLine(to: CGPoint(x: radius, y: height))
            maskPath.addArc(tangent1End: CGPoint(x: 0, y: height), tangent2End: CGPoint(x: 0, y: height - radius), radius: radius)
            maskPath.addLine(to: CGPoint(x: 0, y: 0))
//            CGPathMoveToPoint (maskPath, nil, width, 0)
//            CGPathAddLineToPoint (maskPath, nil, width, height - radius)
//            CGPathAddArcToPoint (maskPath, nil, width, height, width - radius, height, radius)
//            CGPathAddLineToPoint (maskPath, nil, radius, height)
//            CGPathAddArcToPoint (maskPath, nil, 0, height, 0, height - radius, radius)
//            CGPathAddLineToPoint (maskPath, nil, 0, 0)
            
            maskPath.closeSubpath ()
            
            let maskLayer = CAShapeLayer()
            maskLayer.frame = v.bounds
            maskLayer.path  = maskPath
            v.layer.mask = maskLayer
            
            
            let borderPath = CGMutablePath()
            borderPath.move(to: CGPoint(x: width, y: 0))
//            CGPathMoveToPoint (borderPath, nil, width, 0)
            borderPath.addLine(to: CGPoint(x: width, y: height - radius))
//            CGPathAddLineToPoint (borderPath, nil, width, height - radius)
            borderPath.addArc(tangent1End: CGPoint(x: width, y: height), tangent2End: CGPoint(x: width - radius, y: height), radius: radius)
//            CGPathAddArcToPoint (borderPath, nil, width, height, width - radius, height, radius)
            borderPath.addLine(to: CGPoint(x: radius, y: height))
//            CGPathAddLineToPoint (borderPath, nil, radius, height)
            borderPath.addArc(tangent1End: CGPoint(x: 0, y: height), tangent2End: CGPoint(x: 0, y: height - radius), radius: radius)
//            CGPathAddArcToPoint (borderPath, nil, 0, height, 0, height - radius, radius)
            borderPath.addLine(to: CGPoint(x: 0, y: 0))
//            CGPathAddLineToPoint (borderPath, nil, 0, 0)
//            CGPathCloseSubpath (borderPath)
            
            self.borderLayer?.removeFromSuperlayer()
    
            let borderLayer = CAShapeLayer()
            borderLayer.frame = v.bounds
            borderLayer.path  = borderPath
            borderLayer.lineWidth   = 1
            borderLayer.strokeColor = Theme.midGrey.cgColor
            borderLayer.fillColor   = UIColor.clear.cgColor
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
