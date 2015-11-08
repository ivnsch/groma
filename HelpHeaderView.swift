//
//  HelpHeaderView.swift
//  shoppin
//
//  Created by ischuetz on 08/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

protocol HelpHeaderViewDelegate {
    func onHeaderTap(header: HelpHeaderView, sectionIndex: Int, sectionModel: HelpItemSectionModel)
}

class HelpHeaderView: UIView {
    
    @IBOutlet weak var helpTitleLabel: UILabel!
    
    var sectionIndex: Int?

    var delegate: HelpHeaderViewDelegate!

    var sectionModel: HelpItemSectionModel? {
        didSet {
            if let sectionModel = sectionModel {
                if let boldRange = sectionModel.boldRange {
                    helpTitleLabel.attributedText = sectionModel.obj.title.makeAttributed(boldRange, normalFont: Fonts.regularLight, font: Fonts.regularBold)
                } else {
                    helpTitleLabel.text = sectionModel.obj.title
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
