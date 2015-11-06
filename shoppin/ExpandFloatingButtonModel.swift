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
    
    init(bgColor: UIColor = UIColor.greenColor(), pathColor: UIColor = UIColor.purpleColor()) {
        self.bgColor = bgColor
        self.pathColor = pathColor
    }
    
    lazy var collapsedPaths: [CGPath] = {
        let offset: CGFloat = 10
        let buttonWidth: CGFloat = 40
        let gap: CGFloat = 2
        
        let arrow1Path = CGPathCreateMutable() // up right
        CGPathMoveToPoint(arrow1Path, nil, buttonWidth / 2 + gap, offset)
        CGPathAddLineToPoint(arrow1Path, nil, buttonWidth / 2 + gap, buttonWidth / 2 - gap)
        CGPathAddLineToPoint(arrow1Path, nil, buttonWidth - offset, buttonWidth / 2 - gap)
        
        let arrow2Path = CGPathCreateMutable() // bottom left
        CGPathMoveToPoint(arrow2Path, nil, offset, buttonWidth / 2 + gap)
        CGPathAddLineToPoint(arrow2Path, nil, buttonWidth / 2 - gap, buttonWidth / 2 + gap)
        CGPathAddLineToPoint(arrow2Path, nil, buttonWidth / 2 - gap, buttonWidth - offset)
        
        let linePath = CGPathCreateMutable()
        CGPathMoveToPoint(linePath, nil, buttonWidth, 0)
        CGPathAddLineToPoint(linePath, nil, buttonWidth / 2 + gap, buttonWidth / 2 - gap)
        CGPathMoveToPoint(linePath, nil, buttonWidth / 2 - gap, buttonWidth / 2 + gap)
        CGPathAddLineToPoint(linePath, nil, 0, buttonWidth)
        
        return [arrow1Path, arrow2Path, linePath]
    }()
    
    lazy var expandedPaths: [CGPath] = {
        let offset: CGFloat = 10
        let buttonWidth: CGFloat = 40
        
        let arrow1Path = CGPathCreateMutable() // up right
        CGPathMoveToPoint(arrow1Path, nil, buttonWidth / 2, offset)
        CGPathAddLineToPoint(arrow1Path, nil, buttonWidth - offset, offset)
        CGPathAddLineToPoint(arrow1Path, nil, buttonWidth - offset, buttonWidth / 2)
        
        let arrow2Path = CGPathCreateMutable() // bottom left
        CGPathMoveToPoint(arrow2Path, nil, offset, buttonWidth / 2)
        CGPathAddLineToPoint(arrow2Path, nil, offset, buttonWidth - offset)
        CGPathAddLineToPoint(arrow2Path, nil, buttonWidth / 2, buttonWidth - offset)
        
        let linePath = CGPathCreateMutable()
        CGPathMoveToPoint(linePath, nil, buttonWidth - offset, offset)
        CGPathAddLineToPoint(linePath, nil, offset, buttonWidth - offset)
        
        return [arrow1Path, arrow2Path, linePath]
    }()
    
    lazy var expandedAction: FLoatingButtonAttributedAction = {
        FLoatingButtonAttributedAction(action: .Expand, paths: self.expandedPaths, xRight: 20, backgroundColor: self.bgColor, pathColor: self.pathColor)
    }()
    
    lazy var collapsedAction: FLoatingButtonAttributedAction = {
        FLoatingButtonAttributedAction(action: .Expand, paths: self.collapsedPaths, xRight: 20, backgroundColor: self.bgColor, pathColor: self.pathColor)
    }()
}