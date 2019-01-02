//
//  PresentMiniPlayerAnimator.swift
//  Podwise
//
//  Created by Jeff Chimney on 2018-01-05.
//  Copyright © 2018 Jeff Chimney. All rights reserved.
//

import UIKit

class PresentMiniPlayerAnimator : NSObject {
}

extension PresentMiniPlayerAnimator : UIViewControllerAnimatedTransitioning {
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

        containerView.insertSubview(toVC.view, belowSubview: fromVC.view)
        
        let snapshot = fromVC.view.snapshotView(afterScreenUpdates: false)
        snapshot?.tag = MiniPlayerTransitionHelper.snapshotNumber
        snapshot?.isUserInteractionEnabled = false
        snapshot?.layer.shadowOpacity = 0.7
        containerView.insertSubview(snapshot!, aboveSubview: toVC.view)
        fromVC.view.isHidden = true
        
        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            animations: {
                snapshot!.center.y -= UIScreen.main.bounds.height * MiniPlayerTransitionHelper.miniPlayerHeight
        },
            completion: { _ in
                let impact = UIImpactFeedbackGenerator()
                impact.prepare()
                impact.impactOccurred()
                fromVC.view.isHidden = false
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
        )
    }
}
