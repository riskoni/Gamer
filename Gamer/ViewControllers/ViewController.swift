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
    let adbManager = AdbManager()
    var game: Game?

    override func viewDidLoad() {
        super.viewDidLoad()
       
        game = FootballBlackMini(population: 100)
        game?.delegate = self
    }
    
   @IBAction func onButton(sender: NSView){
        if let game = game {
            adbManager.startActivity(withName: game.activityName)
            //takeScreenshot()
            //adbManager.flick(dx: 0.2, dy: 0.5, duration: 0.4)
        }
    }
}

extension ViewController: GameDelegate{
    
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
    
}

