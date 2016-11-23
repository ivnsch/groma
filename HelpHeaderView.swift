//
//  HelpHeaderView.swift
//  shoppin
//
//  Created by ischuetz on 08/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

protocol HelpHeaderViewDelegate: class {
    func onHeaderTap(_ header: HelpHeaderView, sectionIndex: Int, sectionModel: HelpItemSectionModel)
}

class HelpHeaderView: UIView {
    
    @IBOutlet weak var helpTitleLabel: UILabel!
    
    var sectionIndex: Int?

    weak var delegate: HelpHeaderViewDelegate!

    var sectionModel: HelpItemSectionModel? {
        didSet {
            if let sectionModel = sectionModel {
                
                let textColor = sectionModel.obj.type == .troubleshooting ? UIColor.flatRed : UIColor.darkText
                
                if let boldRange = sectionModel.boldRange {
                    helpTitleLabel.attributedText = sectionModel.obj.title.makeAttributed(boldRange, normalFont: Fonts.regular, font: Fonts.regularBold, textColor: textColor)
                } else {
                    helpTitleLabel.text = sectionModel.obj.title
                    helpTitleLabel.textColor = textColor
                }
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let sectionIndex = sectionIndex, let sectionModel = sectionModel {
            delegate?.onHeaderTap(self, sectionIndex: sectionIndex, sectionModel: sectionModel)
        } else {
            print("Error: HelpHeaderView.touchesEnded: no sectionIndex or sectionModel")
        }
    }
}
