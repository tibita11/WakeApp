//
//  StartingViewController.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/05/27.
//

import UIKit

class StartingViewController: UIViewController {

    @IBOutlet private weak var newRegistrationButton: UIButton! {
        didSet {
            newRegistrationButton.backgroundColor = Const.mainBlueColor
            newRegistrationButton.layer.cornerRadius = Const.LargeBlueButtonCorner
        }
    }
    @IBOutlet private weak var signInButton: UIButton! {
        didSet {
            signInButton.backgroundColor = Const.mainBlueColor
            signInButton.layer.cornerRadius = Const.LargeBlueButtonCorner
        }
    }
    /// 紹介ページをスライドで表示する
    @IBOutlet private weak var introductionPageViewContainer: UIView!
    
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUp()
    }
    
    
    // MARK: - Action
    
    private func setUp() {
        let mainPageVC = MainPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
        addChild(mainPageVC)
        mainPageVC.view.translatesAutoresizingMaskIntoConstraints = false
        introductionPageViewContainer.addSubview(mainPageVC.view)

        NSLayoutConstraint.activate([
            mainPageVC.view.topAnchor.constraint(equalTo: introductionPageViewContainer.topAnchor),
            mainPageVC.view.leadingAnchor.constraint(equalTo: introductionPageViewContainer.leadingAnchor),
            mainPageVC.view.trailingAnchor.constraint(equalTo: introductionPageViewContainer.trailingAnchor),
            mainPageVC.view.bottomAnchor.constraint(equalTo: introductionPageViewContainer.bottomAnchor)
        ])
        mainPageVC.didMove(toParent: self)
    }
    
    @IBAction func tapNewRegistrationButton(_ sender: Any) {
        let accoutRegistrationVC = AccountRegistrationViewController(status: .newAccount)
        self.navigationController?.pushViewController(accoutRegistrationVC, animated: true)
    }
    
    @IBAction func tapSignInButton(_ sender: Any) {
        let accoutRegistrationVC = AccountRegistrationViewController(status: .existingAccount)
        self.navigationController?.pushViewController(accoutRegistrationVC, animated: true)
    }
    
    
    
}
