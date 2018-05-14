//
//  NowPlayingView.swift
//  Podwise
//
//  Created by Jeff Chimney on 2018-05-10.
//  Copyright © 2018 Jeff Chimney. All rights reserved.
//

import Foundation
import UIKit

class NowPlayingView: UIView {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    func commonInit() {
        self.backgroundColor = .darkGray
        self.layer.masksToBounds = true
        self.layer.cornerRadius = self.frame.width/2
        self.isHidden = true
    }
    
    func play() {
        self.alpha = 0
        self.isHidden = false
        
        UIView.animate(withDuration: 0.25) {
            self.alpha = 1
        }
    }
    
    func stopPlaying() {
        UIView.animate(withDuration: 0.25, animations: {
            self.alpha = 0
        }) { (complete) in
            self.isHidden = true
        }
    }
}
