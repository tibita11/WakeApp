//
//  GoalCollectionViewCell.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/07/03.
//

import UIKit

protocol GoalCollectionViewCellDelegate: AnyObject {
    /// 一覧表示されている場合にタグ番目のDocumentIDを取得
    ///
    /// - Parameter num: EditButtonに登録されているタグ
    func getDocumentID(num: Int)
    
    /// Todo登録画面へ遷移
    ///
    /// - Parameter num: additionButtonに登録されているタグ
    func transtionToRegistrationView(num: Int)
}

class GoalCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var additionButton: UIButton! {
        didSet {
            additionButton.layer.borderColor = UIColor.black.cgColor
            additionButton.layer.borderWidth = 1
            additionButton.layer.cornerRadius = 5
        }
    }
    @IBOutlet weak var baseView: UIView!
    @IBOutlet weak var baseViewWidth: NSLayoutConstraint!
    @IBOutlet weak var baseViewHeight: NSLayoutConstraint!
    @IBOutlet weak var startDateLabel: UILabel!
    @IBOutlet weak var endDateLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var editButton: UIButton!
    
    weak var delegate: GoalCollectionViewCellDelegate!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func setBaseViewWidth(to width: CGFloat) {
        baseViewWidth.constant = width
    }
    
    func setBaseViewHeight(to height: CGFloat) {
        baseViewHeight.constant = height
    }

    @IBAction func tapEditButton(_ sender: Any) {
        delegate.getDocumentID(num: editButton.tag)
    }
    
    @IBAction func tapAdditionButton(_ sender: Any) {
        delegate.transtionToRegistrationView(num: additionButton.tag)
    }
    
}
