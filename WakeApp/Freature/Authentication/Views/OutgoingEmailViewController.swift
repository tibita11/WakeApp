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
    @IBOutlet weak var signInButton: UIButton! {
        didSet {
            signInButton.layer.cornerRadius = Const.LargeBlueButtonCorner
        }
    }
    
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // NavigationBar非表示
        navigationController?.isNavigationBarHidden = true
    }
    
    
    // MARK: - Action
    
    @IBAction func tapSignInButton(_ sender: Any) {
        let startingVC = StartingViewController()
        let accountRegistrationVC = AccountRegistrationViewController(status: .existingAccount)
        navigationController?.isNavigationBarHidden = false
        navigationController?.viewControllers = [startingVC, accountRegistrationVC]
    }
    
}
