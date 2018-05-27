//
//  EmptyViewController.swift
//  shoppin
//
//  Created by Ivan Schuetz on 28/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit


class EmptyViewController: UITableViewController {

    var labels: (label1: String, label2: String) = ("", "") {
        didSet {
            tableView.reloadData()
        }
    }
    
    fileprivate var pullToAdd: PullToAddHelper?

    weak var container: UIView?

    var onTapOrPull: (() -> Void)?
    
    var enabled: Bool = true {
        didSet {
            if enabled {
                container?.addSubview(view)
            } else {
                container?.removeSubviews()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        enablePullToAdd()

        tableView.backgroundColor = Theme.defaultTableViewBGColor

        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(onTap(_:)))
        view.addGestureRecognizer(tapRecognizer)
    }
    
    func addTo(container: UIView) {
        container.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.fillSuperview()
        self.container = container
    }

    func enablePullToAdd() {
        pullToAdd = PullToAddHelper(tableView: tableView, onPull: { [weak self] in
            self?.onTapOrPull?()
        })
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! EmptyViewCell
        cell.view.line1.text = labels.label1
        cell.view.line2.text = labels.label2
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return view.height
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        pullToAdd?.scrollViewDidScroll(scrollView: scrollView)
    }

    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        pullToAdd?.scrollViewDidEndDecelerating(scrollView)
    }
    
    @objc func onTap(_ sender: UITapGestureRecognizer) {
        onTapOrPull?()
    }
}
