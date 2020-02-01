//
//  AdbManager.swift
//  Gamer
//
//  Created by Nikolay Riskov on 28.01.20.
//  Copyright © 2020 Nikolay Riskov. All rights reserved.
//

import Cocoa
import CoreGraphics

class AdbManager{
    var screenSize = CGSize(width: 1520, height: 720)    //Could be loaded with `adb shell wm size`
    let maxFlickTime = 1000                               //[ms]
    
    func takeScreenshot(completion: @escaping (NSImage?)->Void){
        let homeDir = ProcessInfo.processInfo.environment["HOME"] ?? "/Users/riskov"
        let adb = URL(fileURLWithPath: "\(homeDir)/Library/Android/sdk/platform-tools/adb")
        DispatchQueue(label: "reader").async {
            let pipe = Pipe()
            let proc = Process()
            proc.arguments = ["exec-out", "screencap -p"]
            proc.executableURL = adb
            proc.standardOutput = pipe
            proc.waitUntilExit()
            let _ = try? proc.run()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let image = NSImage(data: data){
                DispatchQueue.main.async {
                    self.screenSize = image.size
                    completion(image)
                }
            }
        }
   }
    
     ///TODO: documentation
     func flick(startPoint: CGPoint, endPoint: CGPoint, duration: Float){
         let p1 = startPoint.pointByMultiplying(screenSize)
         let p2 = endPoint.pointByMultiplying(screenSize)
         let dur = Int(duration * Float(maxFlickTime))
         print("\(p2.x), \(p2.y), \(dur)")
         adbShell("input swipe \(p1.x) \(p1.y) \(p2.x) \(p2.y) \(dur)")
     }
    
     func adbShell(_ cmd: String){
        let homeDir = ProcessInfo.processInfo.environment["HOME"] ?? "/Users/riskov"
        let adb = URL(fileURLWithPath: "\(homeDir)/Library/Android/sdk/platform-tools/adb")
              
        let proc = Process()
        proc.executableURL = adb
        proc.arguments = ["shell", cmd]
        //proc.waitUntilExit()
        let _ = try? proc.run()
    }
    
    func startActivity(withName name: String){
        //TODO
    }
    
    
}
