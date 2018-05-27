//
//  PullToRefreshArrowHelper.swift
//  groma
//
//  Created by Ivan Schuetz on 26.05.18.
//  Copyright © 2018 ivanschuetz. All rights reserved.
//

import UIKit

class PullToRefreshArrowModel {

    private let offset: CGFloat = 10
    private let buttonWidth: CGFloat = 50
    private let buttonHeight: CGFloat = 50

    private let verticalLineHeight: CGFloat = 19
    private let arrowHeadHalfWidth: CGFloat = 6
    private let arrowHeadHeight: CGFloat = 6
    private let bottomLineHalfWidth: CGFloat = 30
    private let bottomLineOffset: CGFloat = 5

    private var bgColor: UIColor
    private var pathColor: UIColor

    init(bgColor: UIColor = UIColor.flatGreen, pathColor: UIColor = UIColor.purple) {
        self.bgColor = bgColor
        self.pathColor = pathColor
    }

    lazy var collapsedPaths: [CGPath] = {
        let verticalLineEnd = offset + verticalLineHeight

        let xCenter = buttonWidth / 2

        let verticalLinePath = CGMutablePath()
        verticalLinePath.move(to: CGPoint(x: xCenter, y: offset))
        verticalLinePath.addLine(to: CGPoint(x: xCenter, y: verticalLineEnd))

        let arrowHeadPath = CGMutablePath()
        arrowHeadPath.move(to: CGPoint(x: xCenter - arrowHeadHalfWidth, y: verticalLineEnd - arrowHeadHeight))
        arrowHeadPath.addLine(to: CGPoint(x: xCenter, y: verticalLineEnd))
        arrowHeadPath.addLine(to: CGPoint(x: xCenter + arrowHeadHalfWidth, y: verticalLineEnd - arrowHeadHeight))

//        let bottomLinePath = CGMutablePath()
//        bottomLinePath.move(to: CGPoint(x: xCenter - bottomLineHalfWidth, y: verticalLineEnd + bottomLineOffset))
//        bottomLinePath.addLine(to: CGPoint(x: xCenter + bottomLineHalfWidth, y: verticalLineEnd + bottomLineOffset))

        return [verticalLinePath, arrowHeadPath
//            , bottomLinePath
        ]
    }()

    lazy var expandedPaths: [CGPath] = {
        let verticalLineEnd = offset + verticalLineHeight

        let xCenter = buttonWidth / 2

        let verticalLinePath = CGMutablePath()
        verticalLinePath.move(to: CGPoint(x: xCenter, y: offset))
        verticalLinePath.addLine(to: CGPoint(x: xCenter, y: verticalLineEnd))

        let arrowHeadPath = CGMutablePath()
        arrowHeadPath.move(to: CGPoint(x: xCenter - verticalLineHeight / 2, y: offset + verticalLineHeight / 2))
        arrowHeadPath.addLine(to: CGPoint(x: xCenter + verticalLineHeight / 2, y: offset + verticalLineHeight / 2))

//        let bottomLinePath = CGMutablePath()
//        bottomLinePath.move(to: CGPoint(x: xCenter - 0, y: verticalLineEnd + bottomLineOffset - 5))
//        bottomLinePath.addLine(to: CGPoint(x: xCenter + 0, y: verticalLineEnd + bottomLineOffset - 5))

        return [verticalLinePath, arrowHeadPath
//            , bottomLinePath
        ]
    }()

    lazy var expandedAction: FLoatingButtonAttributedAction = {
        FLoatingButtonAttributedAction(action: .expand, xRight: 20, paths: self.expandedPaths, backgroundColor: self.bgColor, pathColor: self.pathColor)
    }()

    lazy var collapsedAction: FLoatingButtonAttributedAction = {
        FLoatingButtonAttributedAction(action: .expand, xRight: 20, paths: self.collapsedPaths, backgroundColor: self.bgColor, pathColor: self.pathColor)
    }()
}
