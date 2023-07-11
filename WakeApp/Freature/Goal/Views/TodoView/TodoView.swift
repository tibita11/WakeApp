//
//  TodoView.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/07/05.
//

import UIKit

class TodoView: UIView {
    
    @IBOutlet weak var concentrationView: UIView! {
        didSet {
            concentrationView.layer.cornerRadius = 10
            concentrationView.layer.shadowColor = UIColor.black.cgColor
            concentrationView.layer.shadowOpacity = 0.3
            concentrationView.layer.shadowRadius = 3.0
            concentrationView.layer.shadowOffset = CGSize(width: 0.0, height: 3.0)
        }
    }
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var startDateLabel: UILabel!
    @IBOutlet weak var endDateLabel: UILabel!
    
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
    
}
