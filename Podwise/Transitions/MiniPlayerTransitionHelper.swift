//
//  MiniPlayerTransitionHelper.swift
//  Podwise
//
//  Created by Jeff Chimney on 2018-01-05.
//  Copyright © 2018 Jeff Chimney. All rights reserved.
//

import Foundation
import UIKit

enum Direction {
    case Up
    case Down
}

struct MiniPlayerTransitionHelper {
    
    static let miniPlayerHeight:CGFloat = 1.0
    static let percentThreshold:CGFloat = 0.10
    static let snapshotNumber = 12345
    
    static func calculateProgress(translationInView:CGPoint, viewBounds:CGRect, direction:Direction) -> CGFloat {
        let pointOnAxis:CGFloat
        let axisLength:CGFloat
        switch direction {
        case .Up, .Down:
            pointOnAxis = translationInView.y
            axisLength = viewBounds.height
//        case .Left, .Right:
//            pointOnAxis = translationInView.x
//            axisLength = viewBounds.width
        }
        let movementOnAxis = pointOnAxis / axisLength
        let positiveMovementOnAxis:Float
        let positiveMovementOnAxisPercent:Float
        switch direction {
        case .Down: // positive // right
            positiveMovementOnAxis = fmaxf(Float(-movementOnAxis), 0.0)
            positiveMovementOnAxisPercent = fminf(positiveMovementOnAxis, 1.0)
            return CGFloat(positiveMovementOnAxisPercent)
        case .Up: // negative // left
            positiveMovementOnAxis = fminf(Float(movementOnAxis), 0.0)
            positiveMovementOnAxisPercent = fmaxf(positiveMovementOnAxis, -1.0)
            return CGFloat(-positiveMovementOnAxisPercent)
        }
    }
    
    static func mapGestureStateToInteractor(gestureState:UIGestureRecognizer.State, progress:CGFloat, interactor: Interactor?, triggerSegue: () -> Void){
        guard let interactor = interactor else { return }
        switch gestureState {
        case .began:
            interactor.hasStarted = true
            triggerSegue()
        case .changed:
            interactor.shouldFinish = progress > percentThreshold
            print(interactor.shouldFinish)
            interactor.update(progress)
        case .cancelled:
            interactor.hasStarted = false
            interactor.cancel()
        case .ended:
            interactor.hasStarted = false
            interactor.shouldFinish
                ? interactor.finish()
                : interactor.cancel()
            print("ended and \(interactor.shouldFinish)")
        case .failed:
            interactor.shouldFinish = progress > percentThreshold
            if interactor.shouldFinish {
                interactor.hasStarted = true
                triggerSegue()
                if interactor.shouldFinish {
                    interactor.finish()
                    interactor.hasStarted = false
                }
            }
        default:
            break
        }
    }
}
