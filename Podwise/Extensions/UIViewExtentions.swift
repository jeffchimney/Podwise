//
//  UIViewExtentions.swift
//  Podwise
//
//  Created by Jeff Chimney on 2019-01-03.
//  Copyright © 2019 Jeff Chimney. All rights reserved.
//
import UIKit

extension UIView  {
    
    func makeSnapshot() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(bounds.size, true, 0.0)
        drawHierarchy(in: bounds, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
