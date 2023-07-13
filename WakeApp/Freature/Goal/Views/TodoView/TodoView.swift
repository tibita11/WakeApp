//
//  TodoView.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/07/05.
//

import UIKit

protocol TodoViewDelegate: AnyObject {
    /// タグ番目のDocumentIDを取得
    ///
    /// - Parameters:
    ///   - section: セル作成時に代入したGoalsコレクションのrow番目
    ///   - num: EditiButtonに登録されているタグ
    func getTodoData(section: Int, row: Int)
}

class TodoView: UIView {
    
    @IBOutlet weak var focusStackView: UIStackView!
    @IBOutlet weak var focusView: UIView! {
        didSet {
            focusView.layer.cornerRadius = 10
            focusView.layer.shadowColor = UIColor.black.cgColor
            focusView.layer.shadowOpacity = 0.3
            focusView.layer.shadowRadius = 3.0
            focusView.layer.shadowOffset = CGSize(width: 0.0, height: 3.0)
        }
    }
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var startDateLabel: UILabel!
    @IBOutlet weak var endDateLabel: UILabel!
    /// GoalsコレクションのDocumentIDを取得する際に使用する
    var section: Int? = nil
    weak var delegate: TodoViewDelegate!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadNib()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadNib()
    }
    
    func loadNib() {
        let view = Bundle.main.loadNibNamed("TodoView", owner: self, options: nil)?.first as! UIView
        view.frame = self.bounds
        self.addSubview(view)
    }
    
    @IBAction func tapEditButton(_ sender: Any) {
        guard let section else { return }
        delegate.getTodoData(section: section, row: editButton.tag)
    }
    
}
