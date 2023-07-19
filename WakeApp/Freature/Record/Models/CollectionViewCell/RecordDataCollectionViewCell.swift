//
//  RecordDataCollectionViewCell.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/07/18.
//

import UIKit

class RecordDataCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var commentLabel: UILabel!
    @IBOutlet weak var lineView: UIView! {
        didSet {
            lineView.backgroundColor = Const.alphaMainBlueColor
        }
    }
    @IBOutlet weak var baseViewWidth: NSLayoutConstraint!
    @IBOutlet weak var commentView: UIView! {
        didSet {
            commentView.backgroundColor = Const.silverColor
            commentView.layer.cornerRadius = 10
            
            commentView.layer.shadowColor = UIColor.black.cgColor
            commentView.layer.shadowOpacity = 0.3
            commentView.layer.shadowRadius = 3.0
            commentView.layer.shadowOffset = CGSize(width: 0.0, height: 3.0)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()

    }

}
