//
//  ExpandFloatingButtonModel.swift
//  shoppin
//
//  Created by ischuetz on 06/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

class ExpandFloatingButtonModel {

    var bgColor: UIColor
    var pathColor: UIColor
    
    init(bgColor: UIColor = UIColor.flatGreen, pathColor: UIColor = UIColor.purple) {
        self.bgColor = bgColor
        self.pathColor = pathColor
    }
    
    lazy var collapsedPaths: [CGPath] = {
        let offset: CGFloat = 10
        let buttonWidth: CGFloat = 40
        let gap: CGFloat = 2
        
        let arrow1Path = CGMutablePath() // up right
        arrow1Path.move(to: CGPoint(x: buttonWidth / 2 + gap, y: offset))
        arrow1Path.addLine(to: CGPoint(x: buttonWidth / 2 + gap, y: buttonWidth / 2 - gap))
        arrow1Path.addLine(to: CGPoint(x: buttonWidth - offset, y: buttonWidth / 2 - gap))
        
        let arrow2Path = CGMutablePath() // bottom left
        arrow2Path.move(to: CGPoint(x: offset, y: buttonWidth / 2 + gap))
        arrow2Path.addLine(to: CGPoint(x: buttonWidth / 2 - gap, y: buttonWidth / 2 + gap))
        arrow2Path.addLine(to: CGPoint(x: buttonWidth / 2 - gap, y: buttonWidth - offset))
        
        let linePath = CGMutablePath()
        linePath.move(to: CGPoint(x: buttonWidth, y: 0))
        linePath.addLine(to: CGPoint(x: buttonWidth / 2 + gap, y: buttonWidth / 2 - gap))
        linePath.addLine(to: CGPoint(x: buttonWidth / 2 - gap, y: buttonWidth / 2 + gap))
        linePath.addLine(to: CGPoint(x: 0, y: buttonWidth))
        
        return [arrow1Path, arrow2Path, linePath]
    }()
    
    lazy var expandedPaths: [CGPath] = {
        let offset: CGFloat = 10
        let buttonWidth: CGFloat = 40
        
        let arrow1Path = CGMutablePath() // up right
        arrow1Path.move(to: CGPoint(x: buttonWidth / 2, y: offset))
        arrow1Path.addLine(to: CGPoint(x: buttonWidth - offset, y: offset))
        arrow1Path.addLine(to: CGPoint(x: buttonWidth - offset, y: buttonWidth / 2))
        
        let arrow2Path = CGMutablePath() // bottom left
        arrow2Path.move(to: CGPoint(x: offset, y: buttonWidth / 2))
        arrow2Path.addLine(to: CGPoint(x: offset, y: buttonWidth - offset))
        arrow2Path.addLine(to: CGPoint(x: buttonWidth / 2, y: buttonWidth - offset))
        
        let linePath = CGMutablePath()
        linePath.move(to: CGPoint(x: buttonWidth - offset, y: offset))
        linePath.addLine(to: CGPoint(x: offset, y: buttonWidth - offset))
        
        return [arrow1Path, arrow2Path, linePath]
    }()
    
    lazy var expandedAction: FLoatingButtonAttributedAction = {
        FLoatingButtonAttributedAction(action: .expand, xRight: 20, paths: self.expandedPaths, backgroundColor: self.bgColor, pathColor: self.pathColor)
    }()
    
    lazy var collapsedAction: FLoatingButtonAttributedAction = {
        FLoatingButtonAttributedAction(action: .expand, xRight: 20, paths: self.collapsedPaths, backgroundColor: self.bgColor, pathColor: self.pathColor)
    }()
}
