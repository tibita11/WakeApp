//
//  ProfileEditingViewController.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/06/28.
//

import UIKit
import RxSwift
import RxCocoa
import Kingfisher

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
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var birthdayTextField: UITextField!
    
    private let viewModel = ProfileEditingViewModel()
    private let disposeBag = DisposeBag()
    
    
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        viewModel.getUserData()
    }
    
    
    // MARK: - Action
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    private func setUpViewModel() {
        viewModel.outputs.imageUrlDriver
            .drive(onNext: { [weak self] url in
                self?.imageView.kf.setImage(with: URL(string: url))
            })
            .disposed(by: disposeBag)
        
        viewModel.outputs.nameDriver
            .drive(nameTextField.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.outputs.birthdayTextDriver
            .drive(birthdayTextField.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.outputs.futureDriver
            .drive(futureTextView.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.outputs.errorAlertDriver
            .drive(onNext: { [weak self] error in
                guard let self else { return }
                present(createErrorAlert(title: error), animated: true)
            })
            .disposed(by: disposeBag)
    }


}
