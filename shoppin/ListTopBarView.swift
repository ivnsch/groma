//
//  ListTopBarView.swift
//  shoppin
//
//  Created by ischuetz on 17/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

protocol ListTopBarViewDelegate {
    func onTopBarButtonTap(buttonId: ListTopBarViewButtonId)
    func onTopBarTitleTap()
    func onTopBarBackButtonTap()
    
    // parameter: center => center, !center => left
    func onCenterTitleAnimComplete(center: Bool)
}

enum ListTopBarViewButtonId: Int {
    case Add = 0, Submit = 1, ToggleOpen = 2, Edit = 3
    
    var name: String {
        switch self {
        case .Add:
            return "add"
        case .Submit:
            return "submit"
        case .ToggleOpen:
            return "toggle"
        case .Edit:
            return "edit"
        }
    }
}

struct TopBarButtonModel {
    let buttonId: ListTopBarViewButtonId
    let initTransform: CGAffineTransform?
    let endTransform: CGAffineTransform?
    
    init(buttonId: ListTopBarViewButtonId, initTransform: CGAffineTransform? = nil, endTransform: CGAffineTransform? = nil) {
        self.buttonId = buttonId
        self.initTransform = initTransform
        self.endTransform = endTransform
    }
}

class ListTopBarView: UIView {

    private var backButton: UIButton?
    private var leftButtons: [UIButton] = []
    private var rightButtons: [UIButton] = []
    private var titleLabel: UILabel = UILabel()
    
    var titleLabelColor = UIColor.blackColor() {
        didSet {
            titleLabel.textColor = titleLabelColor
        }
    }
    
    var delegate: ListTopBarViewDelegate?
    
    var fgColor: UIColor = UIColor.blackColor() {
        didSet {
            backButton?.setTitleColor(fgColor, forState: .Normal)
            for button in leftButtons {
                button.imageView?.tintColor = fgColor
            }
            for button in rightButtons {
                button.imageView?.tintColor = fgColor
            }
            titleLabel.textColor = fgColor
        }
    }
    
    private var titleLabelLeftConstraint: NSLayoutConstraint?
    private var titleLabelCentered = false
    private let titleLabelLeftConstant: Float = 14
    
    override func awakeFromNib() {
        super.awakeFromNib()
        translatesAutoresizingMaskIntoConstraints = false
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = Fonts.regular
        addSubview(titleLabel)
        titleLabelLeftConstraint = titleLabel.alignLeft(self, constant: titleLabelLeftConstant)

        // FIXME for some reason this makes the label move the y center during the animation - it should stay constant. alignTop (quickfix) stays constant
//      titleLabel.centerYInParent()
        titleLabel.alignTop(self, constant: 20)
        
        layoutIfNeeded()
        
        addTitleButton()
    }
    
    var title: String = "" {
        didSet {
            titleLabel.text = title
            titleLabel.sizeToFit()
        }
    }
    
    // parameter: center => center, !center => left
    func animateTitleLabelLeft(center: Bool) {
        titleLabelLeftConstraint?.constant = center ? self.center.x - titleLabel.frame.width / 2 : CGFloat(titleLabelLeftConstant)
        UIView.animateWithDuration(0.3, animations: {[weak self] in
            self?.layoutIfNeeded()
            }) {[weak self] finished in
                self?.delegate?.onCenterTitleAnimComplete(center)
        }
    }
    
    private func addTitleButton() {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        addSubview(button)
        button.fillSuperview()
        button.addTarget(self, action: "onTitleTap:", forControlEvents: .TouchUpInside)
    }
    
    func setBackVisible(visible: Bool) {
        if visible {
            if backButton == nil { // don't add again if called multiple times with visible == true
                let button = UIButton()
                button.translatesAutoresizingMaskIntoConstraints = false
                button.imageView?.tintColor = fgColor
                button.setImage(UIImage(named: "tb_back"), forState: .Normal)
                backButton = button
                addSubview(button)
                
                let viewDictionary = ["back": button]
                
                let hConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|-(14)-[back]", options: [], metrics: nil, views: viewDictionary)
                let vConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|-(14)-[back]-(14)-|", options: [], metrics: nil, views: viewDictionary)
                
                addConstraints(hConstraints)
                addConstraints(vConstraints)
                
                button.addTarget(self, action: "onBackTap:", forControlEvents: .TouchUpInside)
            }

        } else {
            backButton?.removeFromSuperview()
            backButton = nil
        }
        
        layoutIfNeeded()
    }

    private func setButtonModels(models: [TopBarButtonModel], left: Bool) {
        
        if left {
            for button in leftButtons {
                button.removeFromSuperview()
            }
            leftButtons = []
            
        } else {
            for button in rightButtons {
                button.removeFromSuperview()
            }
            rightButtons = []
        }
        
        if !models.isEmpty {

            var modelsWithButtons: [(model: TopBarButtonModel, button: UIButton)] = []
            
            func createButton(model: TopBarButtonModel, imgName: String) -> UIButton {
                let button = UIButton()
                button.translatesAutoresizingMaskIntoConstraints = false
                button.tag = model.buttonId.rawValue
                button.imageView?.tintColor = fgColor
                button.setImage(UIImage(named: imgName), forState: .Normal)
                if left {
                    leftButtons.append(button)
                } else {
                    rightButtons.append(button)
                }
                modelsWithButtons.append((model: model, button: button))
                //            viewsOrderedDictionary[model.buttonId.name] = button
                button.addTarget(self, action: "onActionButtonTap:", forControlEvents: .TouchUpInside)
                return button
            }
            
            
            for model in models {
                switch model.buttonId {
                case .Edit:
                    createButton(model, imgName: "tb_edit")
                case .Add:
                    createButton(model, imgName: "tb_add")
                case .Submit:
                    createButton(model, imgName: "tb_done")
                case .ToggleOpen:
                    createButton(model, imgName: "tb_add")
                }
            }
            
            var viewsOrderedDictionary = OrderedDictionary<String, UIView>()
            
            // add subviews and apply possible transform - and fill view dictionary with constraints in same iteration
            for modelWithButton in modelsWithButtons {
                addSubview(modelWithButton.button)
                if let initTransform = modelWithButton.model.initTransform {
                    modelWithButton.button.transform = initTransform
                }
                if let endTransform = modelWithButton.model.endTransform {
                    UIView.animateWithDuration(0.3) {
                        modelWithButton.button.transform = endTransform
                    }
                }

                // TODO when button is at the same position as in a previous state it will re-grow which looks weird so we need a check if there's a button with same id at same index then don't do animation
//                // if there are no specific transforms, apply default (grow animation)
//                if modelWithButton.model.initTransform == nil && modelWithButton.model.endTransform == nil {
//                    modelWithButton.button.transform = CGAffineTransformMakeScale(0.001, 0.001) // 0.001 because 0 sometimes causes bugs with transform (iOS problem)
//                    UIView.animateWithDuration(0.3) {
//                        modelWithButton.button.transform = CGAffineTransformMakeScale(1, 1)
//                    }
//                }
                
                viewsOrderedDictionary[modelWithButton.model.buttonId.name] = modelWithButton.button
            }
            
            let viewsDictionary = viewsOrderedDictionary.toDictionary()
            
            let hSpace = 10
            var hConstraintStr: String = left ? "H:|-(\(hSpace))-" : "H:"
            for (index, entry) in viewsOrderedDictionary.enumerate() {
                var str = "\(hConstraintStr)[\(entry.0)]"
                if index < viewsOrderedDictionary.count - 1 {
                    str += "-\(hSpace)-"
                }
                hConstraintStr = str
            }
            hConstraintStr = left ? hConstraintStr : "\(hConstraintStr)-\(hSpace)-|"
            let hConstraints = NSLayoutConstraint.constraintsWithVisualFormat(hConstraintStr, options: [], metrics: nil, views: viewsDictionary)
            addConstraints(hConstraints)
            
            for vConstraintStr in viewsOrderedDictionary.keys {
                let vConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|-(14)-[\(vConstraintStr)]-(14)-|", options: [], metrics: nil, views: viewsDictionary)
                addConstraints(vConstraints)
            }
        }

        
        layoutIfNeeded()
    }
    
    // parameter left: true => left, false => right
    private func setButtonIds(buttonIds: [ListTopBarViewButtonId], left: Bool) {
        let models = buttonIds.map {TopBarButtonModel(buttonId: $0)}
        setButtonModels(models, left: left)
    }
    
    func setLeftButtonModels(models: [TopBarButtonModel]) {
        setButtonModels(models, left: true)
    }

    func setRightButtonModels(models: [TopBarButtonModel]) {
        setButtonModels(models, left: false)
    }
    
    func setLeftButtonIds(buttonIds: [ListTopBarViewButtonId]) {
        setButtonIds(buttonIds, left: true)
    }
    
    func setRightButtonIds(buttonIds: [ListTopBarViewButtonId]) {
        setButtonIds(buttonIds, left: false)
    }
    
    func onTitleTap(sender: UIButton) {
        delegate?.onTopBarTitleTap()
    }
    
    func onActionButtonTap(sender: UIButton) {
        if let buttonId = ListTopBarViewButtonId(rawValue: sender.tag) {
            delegate?.onTopBarButtonTap(buttonId)
        } else {
            print("Error: ListTopBarView.onActionButtonTap: no ListTopBarViewButtonId for tag: \(sender.tag)")
        }
    }
    
    func onBackTap(sender: UIButton) {
        delegate?.onTopBarBackButtonTap()
    }
}