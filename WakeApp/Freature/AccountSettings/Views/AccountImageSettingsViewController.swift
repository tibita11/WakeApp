//
//  AccountImageSettingsViewController.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/06/05.
//

import UIKit

class AccountImageSettingsViewController: UIViewController {

    @IBOutlet weak var imageChangeButton: UIButton! {
        didSet {
            imageChangeButton.layer.borderColor = UIColor.systemGray2.cgColor
            imageChangeButton.layer.borderWidth = 1.0
            imageChangeButton.layer.cornerRadius = imageChangeButton.bounds.width / 2
        }
    }
    @IBOutlet var defaultImages: [UIButton]! {
        didSet {
            for number in 0..<defaultImages.count {
                defaultImages[number].layer.cornerRadius = defaultImages[number].bounds.width / 2
            }
        }
    }
    @IBOutlet weak var createButton: UIButton! {
        didSet {
            createButton.layer.cornerRadius = Const.LargeBlueButtonCorner
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }

}
