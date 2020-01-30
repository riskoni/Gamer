//
//  Player.swift
//  Gamer
//
//  Created by Nikolay Riskov on 31.01.20.
//  Copyright © 2020 Nikolay Riskov. All rights reserved.
//

import Foundation

enum PlayerState{
    case idle
    case playing
}

class Player{
    let neuralNet: NeuralNet
    var state = PlayerState.idle
    var score = 0
    
    init(neuralNet: NeuralNet){
        self.neuralNet = neuralNet
    }
    
    
    
}
