//
//  FootballBlackMini.swift
//  Gamer
//
//  Created by Nikolay Riskov on 28.01.20.
//  Copyright © 2020 Nikolay Riskov. All rights reserved.
//

import Foundation
import Cocoa

protocol Game {
    var activityName: String {get}
    var delegate: GameDelegate? {get set}
    init(population: Int)
    
}

protocol GameDelegate {
    func requestScreenshot(completion: @escaping (NSImage?)->Void)
    func sendFlickToDevice(x: Float, y: Float, x2: Float, y2: Float, duration: Float)
}

class FootballBlackMini: Game {
    let activityName = "TODO"
    
    fileprivate let black = NSColor(calibratedRed: 0, green: 0, blue: 0, alpha: 1)
    fileprivate let white = NSColor(calibratedRed: 1, green: 1, blue: 1, alpha: 1)
    var currentGeneration = 0
    var currentNeuralNet = 0
    var neuralNets = [NeuralNet]()
    var delegate: GameDelegate? = nil
    
    
    required init(population: Int){
        //Input is just the position of the obstacle x, y
        //Output is touchStart x,y, touchEnd x,y and flick speed
        let structure = try! NeuralNet.Structure(nodes: [2,10,5], hiddenActivation: .rectifiedLinear, outputActivation: .softmax)
        
        for _ in 0..<population{
            let nn = try! NeuralNet(structure: structure, randomizeLastLayer: true)
            neuralNets.append(nn)
        }
    }
    
    func process(screenshot: NSImage) {
        let context = screenshot.getCgContext()
        if let pixels = context?.data?.assumingMemoryBound(to: UInt8.self){
            let point = detectObstacle(pixels: pixels, size: screenshot.size)
            let score = detectScore(pixels: pixels, size: screenshot.size)
            let x = point.x / screenshot.size.width
            let y = point.y / screenshot.size.height
            if score == 0 { //Game has ended:
                //TODO:
//                neuralNetwork.updateInputs([x, y])
//                neuralNetwork.forwardProp()
            }else{
                //Perform Forward propagation
                //Send flick
            }
        }
    }
    
    
    ///Detects the obstacle and returns the top coorfinate of the opening::
    ///Position is marked with x:
    ///                            |
    ///                            x
    ///
    ///
    ///                            |
    ///                            |
    ///                            |
    ///---------------------------------------------------
    fileprivate func detectObstacle(pixels: UnsafeMutablePointer<UInt8>, size: NSSize) -> CGPoint{
        var result = CGPoint.zero
        guard size.width > 0 else{
            return result
        }
        
        //1. Create a bounding rect in which we perform the scans
        let xMargin = size.width * 0.25
        let width = size.width * 0.45
        let yMargin = size.height * 0.4
        let boundingRect = CGRect(x: xMargin, y: yMargin, width: width, height: size.height - yMargin)
        let bytesPerRow = 4 * Int(size.width)

        //2. Make a few horizontal scanlines
        let numLines = 8
        var lines = [CGLine]()
        for i in 0..<numLines {
            let yPos = boundingRect.origin.y + ((boundingRect.size.height * CGFloat(i)) / CGFloat(numLines))
            let p1 = CGPoint(x: boundingRect.origin.x, y: yPos)
            let p2 = CGPoint(x: p1.x + boundingRect.size.width, y: yPos)
            let line = CGLine(p1: p1, p2: p2)
            lines.append(line)
        }

        //3. Find first black pixel in each line
        var points: [CGPoint] = lines.map{ $0.findFirstPixel(matching: black, in: pixels, bytesPerRow: bytesPerRow) }
        /* filter outliers */
        points = points.filter{ $0.x > boundingRect.minX + 20 }
        points = points.filter{ $0.x < boundingRect.maxX - 20 }

        guard points.count > 0 else{
            return result
        }
        
        //4. Find the point
        let xPoint: CGFloat = points.reduce(0, {$0 + $1.x}) / CGFloat(points.count)
        let verticalLine = CGLine(p1: CGPoint(x: xPoint+2, y: 10), p2: CGPoint(x: xPoint+2, y: size.height))
        let yPoint = verticalLine.findFirstPixel(matching: white, in: pixels, bytesPerRow: bytesPerRow).y
        
        
        result = CGPoint(x: xPoint, y: yPoint)
        return result
    }
    
    fileprivate func detectScore(pixels: UnsafeMutablePointer<UInt8>, size: NSSize) -> Int{
        //TODO:
        return 0
    }

    
}
