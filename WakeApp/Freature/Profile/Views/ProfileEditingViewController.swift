//
//  ProfileEditingViewController.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/06/28.
//

import UIKit

class ProfileEditingViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView! {
        didSet {
            imageView.layer.borderColor = UIColor.systemGray2.cgColor
            imageView.layer.borderWidth = 1.0
            imageView.layer.cornerRadius = imageView.bounds.width / 2
        }
    }
    @IBOutlet weak var imageChangeButton: UIButton! {
        didSet {
            imageChangeButton.layer.cornerRadius = 15
        }
    }
    @IBOutlet weak var registerButton: UIButton! {
        didSet {
            registerButton.layer.cornerRadius = Const.LargeBlueButtonCorner
        }
    }
    @IBOutlet weak var futureTextView: PlaceHolderTextView! {
        didSet {
            futureTextView.placeHolder = "例) たくさんの人を救える医者になりたい"
        }
    }
    
    
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    
    // MARK: - Action
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }


}
