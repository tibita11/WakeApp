//
//  RecordAdditionViewController.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/07/19.
//

import UIKit

class RecordAdditionViewController: UIViewController {

    @IBOutlet weak var registerButton: UIButton! {
        didSet {
            registerButton.layer.cornerRadius = Const.LargeBlueButtonCorner
        }
    }
    @IBOutlet weak var textView: PlaceHolderTextView! {
        didSet {
            textView.placeHolder = "進捗や今の気持ちを書いてみましょう！"
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
}
