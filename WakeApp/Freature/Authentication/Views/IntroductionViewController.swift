//
//  PageViewController.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/05/28.
//

import UIKit

class IntroductionViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView! {
        didSet {
            imageView.image = self.initialImage
        }
    }
    @IBOutlet weak var titleLabel: UILabel! {
        didSet {
            titleLabel.text = self.initialTitle
        }
    }
    /// 初期化時に使用する
    private let initialImage: UIImage!
    /// 初期化時に使用する
    private let initialTitle: String!
    
    init(image: UIImage, title: String) {
        self.initialImage = image
        self.initialTitle = title
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }


}
