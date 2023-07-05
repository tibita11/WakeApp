//
//  GoalCollectionViewCell.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/07/03.
//

import UIKit

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

}
