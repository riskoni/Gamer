//
//  Extensions.swift
//  Gamer
//
//  Created by Nikolay Riskov on 28.01.20.
//  Copyright © 2020 Nikolay Riskov. All rights reserved.
//

import Foundation
import Cocoa

extension CGPoint{
    
    func pointByMultiplying(_ size: CGSize) -> CGPoint{
        return CGPoint(x: x*size.width, y: y*size.height)
    }
    
    func pointByOffsetting(dx: CGFloat, dy: CGFloat) -> CGPoint{
        return CGPoint(x: x+dx, y: y+dy)
    }
}

extension NSImage{
    
    func getCgContext() -> CGContext? {
        let width = Int(self.size.width)
        let height = Int(self.size.height)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        let bitmapInfo: UInt32 = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue

        let context = CGContext(data: nil,
                                width: width,
                                height: height,
                                bitsPerComponent: bitsPerComponent,
                                bytesPerRow: bytesPerRow,
                                space: colorSpace,
                                bitmapInfo: bitmapInfo)
        
        var imageRect = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height)
        let cgImage = self.cgImage(forProposedRect: &imageRect, context: nil, hints: nil)
        context?.draw(cgImage!, in: imageRect)
        
        return context
    }
    
}

extension NSColor{
    
    func colorIsSimilar(to other: NSColor, percentage: CGFloat) -> Bool{
        let dr = abs(self.redComponent   - other.redComponent)
        let dg = abs(self.greenComponent - other.greenComponent)
        let db = abs(self.blueComponent  - other.blueComponent)
        return (dr < percentage) && (dg < percentage) && (db < percentage)
    }
    
    
}
