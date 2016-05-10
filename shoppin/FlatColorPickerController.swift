//
//  FlatColorPickerController.swift
//  shoppin
//
//  Created by ischuetz on 10/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import ChameleonFramework

protocol FlatColorPickerControllerDelegate: class {
    func onColorPicked(color: UIColor)
    func onDismiss()
}

class FlatColorPickerController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    @IBOutlet weak var collectionView: UICollectionView!
    
    let flatColors: [UIColor] = [
        UIColor.flatRedColorDark(),
        UIColor.flatOrangeColorDark(),
        UIColor.flatYellowColorDark(),
        UIColor.flatSandColorDark(),
        UIColor.flatNavyBlueColorDark(),
        UIColor.flatBlackColorDark(),
        UIColor.flatMagentaColorDark(),
        UIColor.flatTealColorDark(),
        UIColor.flatSkyBlueColorDark(),
        UIColor.flatGreenColorDark(),
        UIColor.flatMintColorDark(),
        UIColor.flatWhiteColorDark(),
        UIColor.flatGrayColorDark(),
        UIColor.flatForestGreenColorDark(),
        UIColor.flatPurpleColorDark(),
        UIColor.flatBrownColorDark(),
        UIColor.flatPlumColorDark(),
        UIColor.flatWatermelonColorDark(),
        UIColor.flatPinkColorDark(),
        UIColor.flatMaroonColorDark(),
        UIColor.flatCoffeeColorDark(),
        UIColor.flatPowderBlueColorDark(),
        UIColor.flatBlueColorDark()
    ]
    
    weak var delegate: FlatColorPickerControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // FIXME dismiss by tapping on outer borders - doesn't work, this consumes the tap on the cells despite view it's behind
//        let tap = UITapGestureRecognizer(target: self, action: "onTapCollectionViewBG:")
//        view.addGestureRecognizer(tap)
    }
    
    func onTapCollectionViewBG(sender: UIView) {
        delegate?.onDismiss()
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return flatColors.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("cell", forIndexPath: indexPath)
        
        let color = flatColors[indexPath.row]
        let circleView = CircleView(frame: CGRectMake(10, 10, 40, 40))
        circleView.color = color
        circleView.backgroundColor = UIColor.clearColor()
        cell.contentView.backgroundColor = UIColor.whiteColor()
        cell.contentView.addSubview(circleView)
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let color = flatColors[indexPath.row]
        delegate?.onColorPicked(color)
    }
}


private class CircleView: UIView {
    
    var color = UIColor.clearColor()
    
    private override func drawRect(rect: CGRect) {
        let ctx = UIGraphicsGetCurrentContext()
        CGContextAddEllipseInRect(ctx, rect)
        CGContextSetFillColor(ctx, CGColorGetComponents(color.CGColor))
        CGContextFillPath(ctx)
    }
}