//
//  OutgoingEmailViewController.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/06/01.
//

import UIKit

class OutgoingEmailViewController: UIViewController {

    @IBOutlet weak var baseView: UIView! {
        didSet {
            baseView.layer.cornerRadius = 15
            baseView.layer.shadowColor = UIColor.black.cgColor
            baseView.layer.shadowOpacity = 0.3
            baseView.layer.shadowRadius = 3.0
            baseView.layer.shadowOffset = CGSize(width: 0.0, height: 3.0)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // NavigationBar非表示
        navigationController?.isNavigationBarHidden = true
    }
    
}
