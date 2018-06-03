//
//  ExpandFloatingButtonModel.swift
//  shoppin
//
//  Created by ischuetz on 06/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

// NOTE: paths assume button is a square. It's easy to adjust to a rectangle if necessary.
class ExpandFloatingButtonModel {

    var bgColor: UIColor
    var pathColor: UIColor

    fileprivate let offset: CGFloat = 2 // from edges of button to paths
    fileprivate let buttonWidth: CGFloat = 20 // == height
    fileprivate let gap: CGFloat = 2 // between the arrows
    
    init(bgColor: UIColor = UIColor.flatGreen, pathColor: UIColor = UIColor.purple) {
        self.bgColor = bgColor
        self.pathColor = pathColor
    }

    // arrows pointing inwards
    lazy var collapsedPaths: [CGPath] = {
        let arrow1Path = CGMutablePath() // up left
        arrow1Path.move(to: CGPoint(x: buttonWidth / 2 - gap, y: offset))
        arrow1Path.addLine(to: CGPoint(x: buttonWidth / 2 - gap, y: buttonWidth / 2 - gap))
        arrow1Path.addLine(to: CGPoint(x: offset, y: buttonWidth / 2 - gap))
        
        let arrow2Path = CGMutablePath() // bottom right
        arrow2Path.move(to: CGPoint(x: buttonWidth - offset, y: buttonWidth / 2 + gap))
        arrow2Path.addLine(to: CGPoint(x: buttonWidth / 2 + gap, y: buttonWidth / 2 + gap))
        arrow2Path.addLine(to: CGPoint(x: buttonWidth / 2 + gap, y: buttonWidth - offset))
        
        let arrow1Line = CGMutablePath()
        arrow1Line.move(to: CGPoint(x: offset, y: 0 + offset))
        arrow1Line.addLine(to: CGPoint(x: buttonWidth / 2 - gap, y: buttonWidth / 2 - gap))

        let arrow2Line = CGMutablePath()
        arrow2Line.move(to: CGPoint(x: buttonWidth - offset, y: buttonWidth - offset))
        arrow2Line.addLine(to: CGPoint(x: buttonWidth / 2 + gap, y: buttonWidth / 2 + gap))

        return [arrow1Path, arrow2Path, arrow1Line, arrow2Line]
    }()

    // arrows pointing outwards
    lazy var expandedPaths: [CGPath] = {
        let arrow1Path = CGMutablePath() // up left
        arrow1Path.move(to: CGPoint(x: buttonWidth / 2 - gap, y: offset))
        arrow1Path.addLine(to: CGPoint(x: offset, y: offset))
        arrow1Path.addLine(to: CGPoint(x: offset, y: buttonWidth / 2 - gap))

        let arrow2Path = CGMutablePath() // bottom right
        arrow2Path.move(to: CGPoint(x: buttonWidth - offset, y: buttonWidth / 2 + gap))
        arrow2Path.addLine(to: CGPoint(x: buttonWidth - offset, y: buttonWidth - offset))
        arrow2Path.addLine(to: CGPoint(x: buttonWidth / 2 + gap, y: buttonWidth - offset))

        let arrow1Line = CGMutablePath()
        arrow1Line.move(to: CGPoint(x: offset, y: 0 + offset))
        arrow1Line.addLine(to: CGPoint(x: buttonWidth / 2 - gap, y: buttonWidth / 2 - gap))

        let arrow2Line = CGMutablePath()
        arrow2Line.move(to: CGPoint(x: buttonWidth - offset, y: buttonWidth - offset))
        arrow2Line.addLine(to: CGPoint(x: buttonWidth / 2 + gap, y: buttonWidth / 2 + gap))

        return [arrow1Path, arrow2Path, arrow1Line, arrow2Line]
    }()
    
    lazy var expandedAction: FLoatingButtonAttributedAction = {
        FLoatingButtonAttributedAction(action: .expand, xRight: 20, paths: self.expandedPaths, backgroundColor: self.bgColor, pathColor: self.pathColor)
    }()
    
    lazy var collapsedAction: FLoatingButtonAttributedAction = {
        FLoatingButtonAttributedAction(action: .expand, xRight: 20, paths: self.collapsedPaths, backgroundColor: self.bgColor, pathColor: self.pathColor)
    }()
}
