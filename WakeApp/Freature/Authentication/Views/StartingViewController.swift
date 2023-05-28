//
//  StartingViewController.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/05/27.
//

import UIKit

class StartingViewController: UIViewController {

    @IBOutlet weak var newRegistrationButton: UIButton! {
        didSet {
            newRegistrationButton.layer.cornerRadius = Const.LargeBlueButtonCorner
        }
    }
    @IBOutlet weak var roginButton: UIButton! {
        didSet {
            roginButton.layer.cornerRadius = Const.LargeBlueButtonCorner
        }
    }
    /// StartingPageViewControllerを載せるView
    @IBOutlet weak var baseView: UIView!
    
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUp()
    }
    
    
    // MARK: - Action
    
    private func setUp() {
        // 画面中央にPageViewControllerを配置する
        let mainPageVC = MainPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
        addChild(mainPageVC)
        mainPageVC.view.frame = baseView.bounds
        mainPageVC.setUpPageControl()
        baseView.addSubview(mainPageVC.view)
        mainPageVC.didMove(toParent: self)
    }
    
}
