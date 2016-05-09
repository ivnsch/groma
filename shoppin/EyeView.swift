//
//  EyeView.swift
//  shoppin
//
//  Created by ischuetz on 03/05/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs

protocol EyeViewDelegate {
    func onEyeChange(open: Bool)
}

class EyeView: UIView {

    private var openLabel: UILabel?

    private let dotDiameter: CGFloat = 10

    private var open: Bool = true {
        didSet {
            openLabel?.hidden = !open
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()

        let x = (frame.width - dotDiameter) / 2
        let y = (frame.height - dotDiameter) / 2
        
        let path = UIBezierPath(ovalInRect: CGRectMake(x, y, 10, 10))
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.CGPath
        let color = UIColor(hexString: "7F7F7F").CGColor
        shapeLayer.fillColor = color
        shapeLayer.strokeColor = color
        shapeLayer.lineWidth = 1.0
        
        self.layer.addSublayer(shapeLayer)
        
        let label = UILabel(frame: CGRectMake(0, 0, frame.width, frame.height))
        label.font = UIFont.systemFontOfSize(18)
        label.textColor = UIColor(hexString: "7F7F7F")
        label.text = "A"
        label.textAlignment = .Center
        label.backgroundColor = UIColor.whiteColor()
        addSubview(label)
        self.openLabel = label
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(EyeView.onTap(_:)))
        addGestureRecognizer(tapRecognizer)
    }
    
    func onTap(sender: UITapGestureRecognizer) {
        open = !open
        delegate?.onEyeChange(open)
    }
    
    var delegate: EyeViewDelegate?
}