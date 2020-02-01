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
    var players: [Player] {get set}
    init(population: Int, delegate: GameDelegate)
    func start(generation: Int)
    
}

protocol GameDelegate {
    func detectedObstacle(_ pt: CGPoint);
    func requestScreenshot(completion: @escaping (NSImage?)->Void)
    func sendFlickToDevice(x: Float, y: Float, x2: Float, y2: Float, duration: Float)
    func allPlayersFinished()
}

typealias UInt8Ptr = UnsafeMutablePointer<UInt8>


class FootballBlackMini: Game {
    let activityName = "TODO"
    var players = [Player]()
    fileprivate var playerIndex = 0
    fileprivate var delegate: GameDelegate!
    
    var currentPlayer: Player? {
        if playerIndex < players.count {
            return players[playerIndex]
        }
        return nil
    }
    
    required init(population: Int, delegate: GameDelegate){
        self.delegate = delegate
        
        //Input is just the position of the obstacle x, y
        //Output is touchStart x,y, touchEnd x,y and flick speed
        let structure = try! NeuralNet.Structure(nodes: [2,6,3], hiddenActivation: .rectifiedLinear, outputActivation: .sigmoid)
        
        for _ in 0..<population{
            let nn = try! NeuralNet(structure: structure, randomizeLastLayer: true)
            players.append(Player(neuralNet: nn))
        }
    }
    
    func start(generation: Int){
        print("**Starting generation \(generation)")
        for player in players{
            player.state = .idle
            player.score = 0
        }
        playerIndex = 0
        requestScreenshot()
    }
    
    
    fileprivate func requestScreenshot(){
        delegate?.requestScreenshot(completion: { (image) in
            if let image = image{
                self.process(screenshot: image)
            }else{
                print("**ERROR Screenshot is not received. Retrying...")
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                    self?.requestScreenshot()
                }
            }
        })
    }
    
    var lastObstaclePos = CGPoint.zero
    fileprivate func process(screenshot: NSImage) {
        let context = screenshot.getCgContext()
        if let pixels = context?.data?.assumingMemoryBound(to: UInt8.self){
            let obstaclePos = detectObstacle(pixels: pixels, pixelsSize: screenshot.size)
            var scoreIsZero = detectIfScoreIsZero(pixels: pixels, pixelsSize: screenshot.size)
            let x = Float(obstaclePos.x) / Float(screenshot.size.width)
            let y = Float(obstaclePos.y) / Float(screenshot.size.height)
            delegate.detectedObstacle(CGPoint(x: CGFloat(x), y: CGFloat(y)))
            
            /* We have cases with no ball flick */
            if !scoreIsZero && lastObstaclePos == obstaclePos {
                scoreIsZero = true
            }
            lastObstaclePos = obstaclePos
            
            if currentPlayer != nil && currentPlayer!.state == .playing && scoreIsZero {
                /* Game has ended */
                playerIndex += 1
            }
            
            guard let player = currentPlayer else {
                delegate?.allPlayersFinished()
                return
            }
            
            player.state = .playing
            if !scoreIsZero {
                player.score += 1
            }
            
            let result: [Float] = try! player.neuralNet.infer([x, y])
            delegate?.sendFlickToDevice(x: 0.05, y: 0.1, x2: result[0], y2: result[1], duration: result[2])
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.requestScreenshot()
            }


        }else{
            print("**ERROR Could not process the screenshot. Retrying...")
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                self?.requestScreenshot()
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
    fileprivate func detectObstacle(pixels: UInt8Ptr, pixelsSize: NSSize) -> CGPoint{
        let black = NSColor(calibratedRed: 0, green: 0, blue: 0, alpha: 1)
        let white = NSColor(calibratedRed: 1, green: 1, blue: 1, alpha: 1)
        let bytesPerRow = 4 * Int(pixelsSize.width)

        var result = CGPoint.zero
        guard pixelsSize.width > 0 else{
            return result
        }
        
        //1. Create a bounding rect in which we perform the scans
        let xMargin = pixelsSize.width * 0.25
        let width = pixelsSize.width * 0.45
        let yMargin = pixelsSize.height * 0.4
        let boundingRect = CGRect(x: xMargin, y: yMargin, width: width, height: pixelsSize.height - yMargin)

        //2. Make horizontal and vertical scans:
        let xPoint = horizontalScan(for: black, in: boundingRect, pixels: pixels, pixelsSize: pixelsSize)
        let verticalLine = CGLine(p1: CGPoint(x: xPoint+10, y: 10), p2: CGPoint(x: xPoint+10, y: pixelsSize.height))
        var yPoint = verticalLine.findFirstPixel(matching: white, in: pixels, bytesPerRow: bytesPerRow).y
        //yPoint is upside down!
        yPoint = pixelsSize.height - yPoint
        
        result = CGPoint(x: xPoint, y: yPoint)
        return result
    }
    
    ///Dirty and ugly way of detetmining if the score is zero. Might not work on different resolutions
    ///
    ///Method should be changed
    fileprivate func detectIfScoreIsZero(pixels: UInt8Ptr, pixelsSize: NSSize) -> Bool{
        let black = NSColor(calibratedRed: 0, green: 0, blue: 0, alpha: 1)
        guard pixelsSize.width > 0 else{
            return true
        }
        
        //Create a bounding rect in which we perform the scans
        let xMargin = pixelsSize.width * 0.2
        let yMargin = pixelsSize.height * 0.2
        let boundingRect = CGRect(x: xMargin, y: yMargin, width: 200, height: 200)
        let xPoint = horizontalScan(for: black, in: boundingRect, pixels: pixels, pixelsSize: pixelsSize)
        return (xPoint == 357)  //So bad!!!!!
    }
    
    ///Horizontally finds the first pixel of the given color in the area
    fileprivate func horizontalScan(for color: NSColor, in area: CGRect, pixels: UInt8Ptr, pixelsSize: NSSize) -> CGFloat{
        let bytesPerRow = 4 * Int(pixelsSize.width)
        var result: CGFloat = 0
        let numLines = 8
        var lines = [CGLine]()
        for i in 0..<numLines {
            let yPos = area.origin.y + ((area.size.height * CGFloat(i)) / CGFloat(numLines))
            let p1 = CGPoint(x: area.origin.x, y: yPos)
            let p2 = CGPoint(x: p1.x + area.size.width, y: yPos)
            let line = CGLine(p1: p1, p2: p2)
            lines.append(line)
        }

        /* Find first black pixel in each line */
        var points: [CGPoint] = lines.map{ $0.findFirstPixel(matching: color, in: pixels, bytesPerRow: bytesPerRow) }
        points = points.filter{ $0.x > area.minX + 20 }
        points = points.filter{ $0.x < area.maxX - 20 }

        guard points.count > 0 else{
            return result
        }
        
        result = points.reduce(0, {$0 + $1.x}) / CGFloat(points.count)
        return result
    }
    
}
