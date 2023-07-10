//
//  TodoRegistrationViewController.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/07/10.
//

import UIKit

class TodoRegistrationViewController: UIViewController {

    @IBOutlet weak var registerButton: UIButton! {
        didSet {
            registerButton.layer.cornerRadius = Const.LargeBlueButtonCorner
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
}
