//
//  OffsetableRefreshControl.swift
//  _idx_FeedLists_B7BC47B5_ios_min13.0
//
//

import UIKit

extension UIRefreshControl {
    
    func beginRefreshingWithAnimation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            if let scrollView = self.superview as? UIScrollView {
                scrollView.setContentOffset(CGPoint(x: 0, y: scrollView.contentOffset.y - self.frame.height), animated: true)
            }
            self.beginRefreshing()
        }
    }
}

class OffsetableRefreshControl: UIRefreshControl {
    
    var offset: CGFloat = 64
    override var frame: CGRect {
        set {
            var rect = newValue
            rect.origin.y += offset
            super.frame = rect
        }
        get {
            return super.frame
        }
    }
}
