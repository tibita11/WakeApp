//
//  LoardingView.swift
//  WakeApp
//
//  Created by 鈴木楓香 on 2023/06/01.
//

import UIKit

class LoadingView: UIView {
    
    @IBOutlet weak var baseView: UIView! {
        didSet {
            baseView.layer.cornerRadius = 5
        }
    }
    @IBOutlet weak var indicatorView: UIActivityIndicatorView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadNib()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadNib()
    }
    
    func loadNib() {
        let view = Bundle.main.loadNibNamed("LoadingView", owner: self, options: nil)?.first as! UIView
        view.frame = self.bounds
        self.addSubview(view)
    }
    
}
