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
    func getGoalData(row: Int)
    
    /// Todo登録画面へ遷移
    ///
    /// - Parameter num: additionButtonに登録されているタグ
    func transtionToRegistrationView(num: Int)
}

class GoalCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    /// 追加ボタンを非表示にする際に使用する
    @IBOutlet weak var additionStackView: UIStackView!
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
    /// グラデーションを設定するView
    @IBOutlet weak var gradientView: GradientView!
    private var gradientLayer: CAGradientLayer!
    
    weak var delegate: GoalCollectionViewCellDelegate!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setUpGradientView()
    }
    
    func setBaseViewWidth(to width: CGFloat) {
        baseViewWidth.constant = width
    }
    
    func setBaseViewHeight(to height: CGFloat) {
        baseViewHeight.constant = height
    }

    @IBAction func tapEditButton(_ sender: Any) {
        delegate.getGoalData(row: editButton.tag)
    }
    
    @IBAction func tapAdditionButton(_ sender: Any) {
        delegate.transtionToRegistrationView(num: additionButton.tag)
    }
    
    private func setUpGradientView() {
        gradientView.layer.cornerRadius = 15
        gradientView.layer.masksToBounds = true
        
        gradientLayer = CAGradientLayer()
        gradientLayer.startPoint = CGPoint.init(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint.init(x: 1, y: 1)
        gradientView.layer.insertSublayer(gradientLayer, at: 0)
        
        gradientView.didLayoutSubView = { [weak self] bounds in
            // layerのframe情報をgradientViewのもので更新
            self?.gradientLayer.frame = bounds
        }
    }
    
    /// 目標達成の場合のグラデーション
    func setUpAchievedColor() {
        let topColor = UIColor(red: 230/255, green: 219/255, blue: 255/255, alpha: 0.8).cgColor
        let bottopColor = UIColor(red: 0, green: 163/255, blue: 255/255, alpha: 0.4).cgColor
        let gradientColors: [CGColor] = [topColor, bottopColor]
        gradientLayer.colors = gradientColors
    }
    
    /// 目標未達成の場合のグラデーション
    func setUpNotAchievedColor() {
        let topColor = UIColor(red: 242/255, green: 242/255, blue: 242/255, alpha: 0.8).cgColor
        let bottopColor = UIColor(red: 146/255, green: 146/255, blue: 146/255, alpha: 0.4).cgColor
        let gradientColors: [CGColor] = [topColor, bottopColor]
        gradientLayer.colors = gradientColors
    }
    
}
