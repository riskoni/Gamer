//
//  ViewController.swift
//  Gamer
//
//  Created by Nikolay Riskov on 27.01.20.
//  Copyright © 2020 Nikolay Riskov. All rights reserved.
//

import Cocoa
import CoreGraphics

class ViewController: NSViewController {
    
    @IBOutlet weak var imageView: NSImageView?
    @IBOutlet weak var dot: NSView?
    
    let adbManager = AdbManager()
    var game: Game?
    var currentGeneration = 0

    override func viewDidLoad() {
        super.viewDidLoad()
       
        game = FootballBlackMini(population: 33, delegate: self)
    }
    
   @IBAction func onButton(sender: NSView){
        if let game = game {
            game.start(generation: currentGeneration)
        }
    }
}

extension ViewController: GameDelegate{
    
    func detectedObstacle(_ pt: CGPoint){
        dot?.frame.origin = pt.pointByMultiplying(CGSize(width: 304, height: 144))
    }
    
    func sendFlickToDevice(x: Float, y: Float, x2: Float, y2: Float, duration: Float) {
        let p1 = CGPoint(x: CGFloat(x), y: CGFloat(y))
        let p2 = CGPoint(x: CGFloat(x2), y: CGFloat(y2))
        adbManager.flick(startPoint: p1, endPoint: p2, duration: duration)
    }
    
    func requestScreenshot(completion: @escaping (NSImage?) -> Void) {
        adbManager.takeScreenshot { [weak self](image) in
            self?.imageView?.image = image
            if let image = image {
                completion(image)
            }
        }
    }
    
    func allPlayersFinished() {
        let sortedPlayers = game!.players.sorted(by: { $0.score > $1.score })
        let url = URL(fileURLWithPath: "/Users/riskov/ML/bestPlayer\(currentGeneration).json")
        let _ = try? sortedPlayers[0].neuralNet.save(to: url)
        let DNAs = sortedPlayers.map{ $0.neuralNet.dna() }
        
        print(sortedPlayers.map{ $0.score })
        
        /* GA */
        /* Make sure top 1 player stays intact */
        game!.players[0].neuralNet.setDna(DNAs.first!)
        var playerIndex = 1
        for i in 1..<(DNAs.count/2)+1 {
            let dna = DNAs[i]
            let dna2 = DNAs[i-1]
            let crossoverPoint = Int(arc4random() % UInt32(dna.count))

            /* Crossover */
            let newDna = Array(dna[0..<crossoverPoint]) + Array(dna2[crossoverPoint..<dna2.count])
            var newDna2 = Array(dna2[0..<crossoverPoint]) + Array(dna[crossoverPoint..<dna.count])

            /* Mutate */
            for _ in 0..<1 {
                let rangeInt = UInt32(2_000_000_000)
                let randomFloat = (Float(arc4random_uniform(rangeInt)) - Float(rangeInt / 2)) / 1_000_000_000
                let mutatingPoint = Int(arc4random() % UInt32(dna.count))
                newDna2[mutatingPoint] = randomFloat
            }

            if(playerIndex < game!.players.count){
                game!.players[ playerIndex ].neuralNet.setDna(newDna)
                playerIndex += 1
            }
            if(playerIndex < game!.players.count){
                game!.players[playerIndex].neuralNet.setDna(newDna2)
                playerIndex += 1
            }
        }

        currentGeneration += 1
        game!.start(generation: currentGeneration)
    }
       
    
}

