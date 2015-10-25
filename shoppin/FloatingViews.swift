//
//  FloatingViews.swift
//  shoppin
//
//  Created by ischuetz on 24/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

enum FLoatingButtonAction {
    case Add, Toggle, Back, Submit
}

struct FLoatingButtonAttributedAction {
    let action: FLoatingButtonAction
    let alpha: CGFloat
    let rotation: CGFloat
    
    init(action: FLoatingButtonAction, alpha: CGFloat = 1, rotation: CGFloat = 0) {
        self.action = action
        self.alpha = alpha
        self.rotation = rotation
    }
}


class FloatingViewModel {
    let action: FLoatingButtonAction
    let imgName: String
    let alpha: CGFloat
    let rotation: CGFloat
    let onTap: VoidFunction

    init(action: FLoatingButtonAction, imgName: String, alpha: CGFloat, rotation: CGFloat, onTap: VoidFunction) {
        self.action = action
        self.imgName = imgName
        self.alpha = alpha
        self.rotation = rotation
        self.onTap = onTap
    }
}


protocol BottonPanelViewDelegate {
    func onSubmitAction(action: FLoatingButtonAction)
}

class FloatingViews: UIView {
    
    let buttonWidth: CGFloat = 40
    
    var models: [FloatingViewModel] = [] {
        didSet {
            initButtons()
//            transition(oldValue, newModels: models) // TODO
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
//        xibSetup()
        
        autoresizingMask = [UIViewAutoresizing.FlexibleWidth, UIViewAutoresizing.FlexibleHeight]
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
//        xibSetup()
        
        autoresizingMask = [UIViewAutoresizing.FlexibleWidth, UIViewAutoresizing.FlexibleHeight]
    }
    
//    // TODO find a way to not have extra view here (add subview) since this is used in tableview cells.
//    private func xibSetup() {
//        let view = NSBundle.loadView("FloatingViews", owner: self)!
//        view.frame = bounds
//        // Make the view stretch with containing view
//        view.autoresizingMask = [UIViewAutoresizing.FlexibleWidth, UIViewAutoresizing.FlexibleHeight]
//        self.addSubview(view)
//    }
    
    
    var delegate: BottonPanelViewDelegate?
    
    func setActions(actions: [FLoatingButtonAction]) {
        let attributedActions = actions.map{FLoatingButtonAttributedAction(action: $0)}
        setActions(attributedActions)
    }

    func setActions(actions: [FLoatingButtonAttributedAction]) {
        
        func toModel(attributedAction: FLoatingButtonAttributedAction) -> FloatingViewModel {
            let imgName: String = {
                switch attributedAction.action {
                case .Add: return "flt_plus"
                case .Toggle: return "flt_plus"
                case .Back: return "flt_back"
                case .Submit: return "flt_done"
                }
            }()
            return FloatingViewModel(action: attributedAction.action, imgName: imgName, alpha: attributedAction.alpha, rotation: attributedAction.rotation, onTap: {[weak self] in
                self?.submitAction(attributedAction.action)
            })
        }
        
        let models = actions.map{toModel($0)}
        self.models = models
    }
    
    private func submitAction(action: FLoatingButtonAction) {
        delegate?.onSubmitAction(action)
    }
    
    
    private func initButtons() {
        clearButtons()
        loadButtons()
    }
    
    private func clearButtons() {
        removeSubviews()
    }
    
    private func loadButtons() {

        let halfButtonWidth = buttonWidth / 2
        let distanceX = (frame.width - halfButtonWidth) / CGFloat(models.count)

        for i in 0..<models.count {
            let model = models[i]
            let button = UIButton()
            button.backgroundColor = UIColor.whiteColor()
            button.layer.cornerRadius = buttonWidth / CGFloat(2)
            button.setImage(UIImage(named: model.imgName), forState: .Normal)
            button.addTarget(self, action: "onButtonTap:", forControlEvents: .TouchUpInside)
            button.tag = i
            button.alpha = model.alpha
            button.transform = CGAffineTransformMakeRotation(model.rotation)
            
            let centerXFromRight = (halfButtonWidth + (CGFloat(i) * distanceX))
            
            addSubview(button)

            positionView(button, xFromRight: centerXFromRight, top: (frame.height - buttonWidth) / 2)
        }
    }
    
    private func positionView(view: UIView, xFromRight: CGFloat, top: CGFloat) {
        
        let views = [view]
        for v in views {
            v.translatesAutoresizingMaskIntoConstraints = false
        }
        
        let namedViews = views.enumerate().map{index, view in
            ("v\(index)", view)
        }
        
        let viewsDict = namedViews.reduce(Dictionary<String, UIView>()) {(var u, tuple) in
            u[tuple.0] = tuple.1
            return u
        }
        
        let hConstraintStr = "H:[v0]-\(xFromRight)-|"
        //            let hConstraintStr = namedViews[1..<namedViews.count].reduce("H:|[v0]") {str, tuple in
        //                "\(str)-(\(labelsSpace))-[\(tuple.0)]"
        //            }
        
        let vConstraits = namedViews.flatMap {NSLayoutConstraint.constraintsWithVisualFormat("V:|-(\(top))-[\($0.0)]", options: NSLayoutFormatOptions(), metrics: nil, views: viewsDict)}
        
        addConstraints(NSLayoutConstraint.constraintsWithVisualFormat(hConstraintStr, options: NSLayoutFormatOptions(), metrics: nil, views: viewsDict) + vConstraits)
    }
    

    // ???
//    private func updateButton(button: UIButton, target: CGPoint, alpha: CGFloat, animated: Bool) {
//        button.center = target
//        button.alpha = alpha
//    }
    
    private func transition(oldModels: [FloatingViewModel], newModels: [FloatingViewModel]) {
        // for now:
        // contract: make all views "on the left" move to center of view on the most right and fade out
        // expand: make all views "on the left" start from center most right to their respective positions
    }
    
    func onButtonTap(button: UIButton) {
        models[button.tag].onTap()
    }
}