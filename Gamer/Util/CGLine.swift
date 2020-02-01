//
//  CGLine.swift
//  Gamer
//
//  Created by Nikolay Riskov on 28.01.20.
//  Copyright © 2020 Nikolay Riskov. All rights reserved.
//

import Cocoa

struct CGLine{
    let p1: CGPoint
    let p2: CGPoint
    
    var description: String{
        return "\(p1) - \(p2)"
    }
   
    func findFirstPixel(matching color: NSColor, in pixels: UnsafeMutablePointer<UInt8>, bytesPerRow: Int) -> CGPoint{
        let dx = p2.x - p1.x
        let dy = p2.y - p1.y
        let distance = sqrt(dx*dx + dy*dy)
        
        for i in 1..<Int(distance){
            /* Linear interpolation */
            let point = CGPoint(x: p1.x + dx*CGFloat(i)/distance,
                                y: p1.y + dy*CGFloat(i)/distance)
            let byteNum = bytesPerRow * Int(point.y) + 4 * Int(point.x)
            let r = (CGFloat(pixels[byteNum])) / 255.0
            let g = (CGFloat(pixels[byteNum + 1])) / 255.0
            let b = (CGFloat(pixels[byteNum + 2])) / 255.0
            let pixelColor = NSColor(calibratedRed: r, green: g, blue: b, alpha: 1)
            if(pixelColor.colorIsSimilar(to: color, percentage: 0.1)){
                return point
            }
        }
        
        return CGPoint.zero
    }
}
