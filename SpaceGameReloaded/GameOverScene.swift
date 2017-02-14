//
//  GameOver.swift
//  SpacegameReloaded
//
//  Created by Hagin Onyango on 2/8/17.
//  Copyright © 2017 Hagin Onyango. All rights reserved.
//

import UIKit
import SpriteKit

class GameOverScene: SKScene {

    var score:Int = 0
    
    var scoreLabel:SKLabelNode!
    var newGameButtonNode:SKSpriteNode!
    var difficultyButtonNode:SKSpriteNode!
    var difficultyLabel:SKLabelNode!
 
    override func didMove(to view: SKView) {
        
        scoreLabel = self.childNode(withName: "scoreLabel") as! SKLabelNode
        scoreLabel.text = "\(score)"
        
        newGameButtonNode = self.childNode(withName: "newGameButton") as! SKSpriteNode
        newGameButtonNode.texture = SKTexture(imageNamed: "newGameButton")
        
        difficultyButtonNode = self.childNode(withName:"difficultyButton") as! SKSpriteNode
        difficultyButtonNode.texture = SKTexture(imageNamed: "difficultyButton")
        
        difficultyLabel = self.childNode(withName: "difficultyLabel") as! SKLabelNode
        
        

    }
 
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        if let location = touch?.location(in: self) {
            let node = self.nodes(at: location)
            
            if node[0].name == "newGameButton" {
                let transition = SKTransition.flipHorizontal(withDuration: 0.5)
                let gameScene = GameScene(size: self.size)
                self.view!.presentScene(gameScene, transition: transition)
                
            } else if node[0].name == "difficultyButton" {
                changeDifficulty()
            }
        }

    }
    
    func changeDifficulty(){
        
        let userDefaults = UserDefaults.standard
        
        if difficultyLabel.text == "Easy" {
            difficultyLabel.text = "Hard"
            userDefaults.set(true, forKey: "hard")
        }else{
            difficultyLabel.text = "Easy"
            userDefaults.set(false, forKey: "hard")
        }
        
        userDefaults.synchronize()
    }
}

