//
//  HelpHeaderView.swift
//  shoppin
//
//  Created by ischuetz on 08/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

protocol HelpHeaderViewDelegate: class {
    func onHeaderTap(header: HelpHeaderView, sectionIndex: Int, sectionModel: HelpItemSectionModel)
}

class HelpHeaderView: UIView {
    
    @IBOutlet weak var helpTitleLabel: UILabel!
    
    var sectionIndex: Int?

    weak var delegate: HelpHeaderViewDelegate!

    var sectionModel: HelpItemSectionModel? {
        didSet {
            if let sectionModel = sectionModel {
                
                let textColor = sectionModel.obj.type == .Troubleshooting ? UIColor.redColor() : UIColor.darkTextColor()
                
                if let boldRange = sectionModel.boldRange {
                    helpTitleLabel.attributedText = sectionModel.obj.title.makeAttributed(boldRange, normalFont: Fonts.regular, font: Fonts.regularBold, textColor: textColor)
                } else {
                    helpTitleLabel.text = sectionModel.obj.title
                    helpTitleLabel.textColor = textColor
                }
            }
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if let sectionIndex = sectionIndex, sectionModel = sectionModel {
            delegate?.onHeaderTap(self, sectionIndex: sectionIndex, sectionModel: sectionModel)
        } else {
            print("Error: HelpHeaderView.touchesEnded: no sectionIndex or sectionModel")
        }
    }
}
