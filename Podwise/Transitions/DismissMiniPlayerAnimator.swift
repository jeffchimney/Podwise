//
//  DismissMiniPlayerAnimator.swift
//  Podwise
//
//  Created by Jeff Chimney on 2018-01-05.
//  Copyright © 2018 Jeff Chimney. All rights reserved.
//

import UIKit

class DismissMiniPlayerAnimator : NSObject {
}

extension DismissMiniPlayerAnimator : UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.6
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard
            let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from),
            let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)
        else {
            return
        }
        let containerView = transitionContext.containerView
        // 1
        let snapshot = containerView.viewWithTag(MiniPlayerTransitionHelper.snapshotNumber)
        
        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            animations: {
                // 2
                snapshot?.frame = CGRect(origin: CGPoint.zero, size: UIScreen.main.bounds.size)
        }, completion: { _ in
                let didTransitionComplete = !transitionContext.transitionWasCancelled
                if didTransitionComplete {
                // 3
                containerView.insertSubview(toVC.view, aboveSubview: fromVC.view)
                snapshot?.removeFromSuperview()
            }
            transitionContext.completeTransition(didTransitionComplete)
        })
    }
}
