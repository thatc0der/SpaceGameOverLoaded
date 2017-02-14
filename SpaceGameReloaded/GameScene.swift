//
//  GameScene.swift
//  SpaceGameReloaded
//
//  Created by Hagin Onyango on 2/8/17.
//  Copyright © 2017 Hagin Onyango. All rights reserved.
//

import SpriteKit
import GameplayKit
import CoreMotion
import AVFoundation

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var starfield:SKEmitterNode!
    var player:SKSpriteNode!
    var alienDestroyer:SKSpriteNode!
    
    var scoreLabel:SKLabelNode!
    var score:Int = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    
    
    var gameTimer:Timer!
    
    var possibleAliens = ["alien", "alien2", "alien3"]
   
    let photonTorpedoCategory:UInt32 = 0x1 << 0
    let alienCategory:UInt32 = 0x1 << 1
    let alienDestroyerCategory:UInt32 = 0x1 << 2
    let playerCategory:UInt32 = 0x1 << 3
    let alienTorpedoCategory:UInt32 = 0x1 << 4
    
    let motionManger = CMMotionManager()
    var xAcceleration:CGFloat = 0
    
    var livesArray:[SKSpriteNode]!

    var bgMusic: AVAudioPlayer?
    var explosionSound: AVAudioPlayer?
    
    func playSound() {
        let url = Bundle.main.url(forResource: "Snap", withExtension: "mp3")!
       
        do {
            bgMusic = try AVAudioPlayer(contentsOf: url)
            guard let bgmusic = bgMusic else { return }
            
            bgmusic.prepareToPlay()
            bgmusic.play()
            
        } catch let error {
            print(error.localizedDescription)
        }
    }
    override func didMove(to view: SKView) {
        
        playSound()

        addLives()
        
        starfield = SKEmitterNode(fileNamed: "Starfield")
        starfield.position = CGPoint(x: 0, y: 1472)
        starfield.advanceSimulationTime(10)
        self.addChild(starfield)
        
        starfield.zPosition = -1
        
        player = SKSpriteNode(imageNamed: "shuttle")
        
        player.position = CGPoint(x: self.frame.size.width / 2, y: player.size.height / 2 + 20)
        player.physicsBody = SKPhysicsBody(rectangleOf: player.size)
        player.physicsBody?.isDynamic = true
        
        player.physicsBody?.categoryBitMask = playerCategory
        player.physicsBody?.contactTestBitMask = alienTorpedoCategory
        player.physicsBody?.collisionBitMask = 0
        
        self.addChild(player)
        
        self.physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        self.physicsWorld.contactDelegate = self
        
        scoreLabel = SKLabelNode(text: "Score: 0")
        scoreLabel.position = CGPoint(x: 80, y: self.frame.size.height - 70)
        scoreLabel.fontName = "AmericanTypewriter-Bold"
        scoreLabel.fontSize = 28
        scoreLabel.fontColor = UIColor.white
        score = 0
        
        self.addChild(scoreLabel)
        
        var timeInterval = 1.0
        
        if UserDefaults.standard.bool(forKey: "hard") {
            timeInterval = 0.5
        }
        
        
        gameTimer = Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(addAlien), userInfo: nil, repeats: true)
        
        gameTimer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(spawnAlienDestroyer), userInfo: nil, repeats: true)
        
        
        motionManger.accelerometerUpdateInterval = 0.2
        motionManger.startAccelerometerUpdates(to: OperationQueue.current!) { (data:CMAccelerometerData?, error:Error?) in
            if let accelerometerData = data {
                let acceleration = accelerometerData.acceleration
                self.xAcceleration = CGFloat(acceleration.x) * 0.75 + self.xAcceleration * 0.25
            }
        }
        
        
        
    }
    
    func addLives() {
        livesArray = [SKSpriteNode]()
        
        for live in 1...3 {
            let liveNode = SKSpriteNode(imageNamed: "shuttle")
            
            liveNode.position = CGPoint(x: self.frame.size.width - CGFloat(4 - live) * liveNode.size.width , y: self.frame.size.height - 60)
            
            self.addChild(liveNode)
            livesArray.append(liveNode)
        }
    }
    
    func spawnAlienDestroyer () {
        alienDestroyer = SKSpriteNode(imageNamed: "alienDestroyer")
        let randomAlienPosition = GKRandomDistribution(lowestValue: 20, highestValue: 300)
        
        let position = CGFloat(randomAlienPosition.nextInt())
        
        alienDestroyer.position = CGPoint(x: position, y: self.frame.size.height + alienDestroyer.size.height)
        alienDestroyer.physicsBody = SKPhysicsBody(rectangleOf: alienDestroyer.size)
        alienDestroyer.physicsBody?.isDynamic = true
        
        alienDestroyer.physicsBody?.categoryBitMask = alienDestroyerCategory
        alienDestroyer.physicsBody?.contactTestBitMask = photonTorpedoCategory
        alienDestroyer.physicsBody?.collisionBitMask = 0
        
        self.addChild(alienDestroyer)
        
        //how long the alienDestoryer is on the screen
        let animationDuration:TimeInterval = 6
        
        var actionArray = [SKAction]()
        
        actionArray.append(SKAction.move(to: CGPoint(x: position, y: -alienDestroyer.size.height), duration: animationDuration))
        
        
        
        enemyTorpedo()
        
        actionArray.append(SKAction.run {
            
            let loose = SKAudioNode(fileNamed: "loose.mp3")
            loose.autoplayLooped = false
            self.addChild(loose)
            
            loose.run(SKAction.changeVolume(by: 0.5, duration: 0))
            
            if self.livesArray.count > 0 {
                let liveNode = self.livesArray.first
                liveNode!.removeFromParent()
                self.livesArray.removeFirst()
                
                if self.livesArray.count == 0 {
                    // GameOverScreen Transiton
                    self.bgMusic?.stop()
                    let transition = SKTransition.flipHorizontal(withDuration: 0.5)
                    let gameOver = SKScene(fileNamed: "GameOverScene") as! GameOverScene 
                    gameOver.score = self.score
                    self.view?.presentScene(gameOver, transition: transition)
                    
                }
            }
        })
        actionArray.append(SKAction.removeFromParent())
        alienDestroyer.run(SKAction.sequence(actionArray))
        
    }
    
    func addAlien () {
        possibleAliens = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: possibleAliens) as! [String]
        
        let alien = SKSpriteNode(imageNamed: possibleAliens[0])
        
        let randomAlienPosition = GKRandomDistribution(lowestValue: 20, highestValue: 300)
        
        let position = CGFloat(randomAlienPosition.nextInt())
        
        alien.position = CGPoint(x: position, y: self.frame.size.height + alien.size.height)
        
        alien.physicsBody = SKPhysicsBody(rectangleOf: alien.size)
        alien.physicsBody?.isDynamic = true
        
        alien.physicsBody?.categoryBitMask = alienCategory
        alien.physicsBody?.contactTestBitMask = photonTorpedoCategory
        alien.physicsBody?.collisionBitMask = 0
        
        self.addChild(alien)
        
        let animationDuration:TimeInterval = 6
        
        var actionArray = [SKAction]()
        
        actionArray.append(SKAction.move(to: CGPoint(x: position, y: -alien.size.height), duration: animationDuration))
        
        //run block is for detectin losers :P
        actionArray.append(SKAction.run {
            
            self.run(SKAction.playSoundFileNamed("loose.mp3", waitForCompletion: false))
            
            if self.livesArray.count > 0 {
                let liveNode = self.livesArray.first
                liveNode!.removeFromParent()
                self.livesArray.removeFirst()
                
                if self.livesArray.count == 0 {
                    // GameOverScreen Transiton
                    self.bgMusic?.stop()
                    self.removeAllChildren()
                    let transition = SKTransition.flipHorizontal(withDuration: 0.5)
                    let gameOver = SKScene(fileNamed: "GameOverScene") as! GameOverScene
                    gameOver.score = self.score
                    self.view?.presentScene(gameOver, transition: transition)
                }
            }
        })
        actionArray.append(SKAction.removeFromParent())
        
        alien.run(SKAction.sequence(actionArray))
        
    }
    
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        fireTorpedo()
    }
    
    func enemyTorpedo() {
        let alienTorpedo = SKSpriteNode(imageNamed: "alienTorpedo")
        
        alienTorpedo.position =  alienDestroyer.position
        alienTorpedo.position.y -= 10
        alienTorpedo.physicsBody = SKPhysicsBody(circleOfRadius: alienTorpedo.size.width / 2)
        alienTorpedo.physicsBody?.isDynamic = true
        
        alienTorpedo.physicsBody?.categoryBitMask = alienTorpedoCategory
        alienTorpedo.physicsBody?.contactTestBitMask = playerCategory | photonTorpedoCategory
        alienTorpedo.physicsBody?.collisionBitMask = 0
        
        self.addChild(alienTorpedo)
        
        let animationDuration:TimeInterval = 2.0
        
        var actionArray = [SKAction]()
        
        actionArray.append(SKAction.move(to: CGPoint(x: alienDestroyer.position.x, y: -alienDestroyer.size.height), duration: animationDuration))

        actionArray.append(SKAction.run {
            
            self.run(SKAction.playSoundFileNamed("loose.mp3", waitForCompletion: false))
            
            if self.livesArray.count > 0 {
                let liveNode = self.livesArray.first
                liveNode!.removeFromParent()
                self.livesArray.removeFirst()
                
                if self.livesArray.count == 0 {
                    self.bgMusic?.stop()
                    // GameOverScreen Transiton
                    let transition = SKTransition.flipHorizontal(withDuration: 0.5)
                    let gameOver = SKScene(fileNamed: "GameOverScene") as! GameOverScene
                    gameOver.score = self.score
                    self.view?.presentScene(gameOver, transition: transition)
                    
                }
            }
        })
        actionArray.append(SKAction.removeFromParent())
        
        alienTorpedo.run(SKAction.sequence(actionArray))

    }
    
    func fireTorpedo() {
        self.run(SKAction.playSoundFileNamed("torpedo.mp3", waitForCompletion: false))
        
        let torpedoNode = SKSpriteNode(imageNamed: "torpedo")
        torpedoNode.position = player.position
        torpedoNode.position.y += 5
        
        torpedoNode.physicsBody = SKPhysicsBody(circleOfRadius: torpedoNode.size.width / 2)
        torpedoNode.physicsBody?.isDynamic = true
        
        torpedoNode.physicsBody?.categoryBitMask = photonTorpedoCategory
        torpedoNode.physicsBody?.contactTestBitMask = alienCategory | alienDestroyerCategory | alienTorpedoCategory
        torpedoNode.physicsBody?.collisionBitMask = 0
        torpedoNode.physicsBody?.usesPreciseCollisionDetection = true
        
        self.addChild(torpedoNode)
        
        let animationDuration:TimeInterval = 0.3
        
        var actionArray = [SKAction]()
        
        actionArray.append(SKAction.move(to: CGPoint(x: player.position.x, y: self.frame.size.height + 10), duration: animationDuration))
        actionArray.append(SKAction.removeFromParent())
        
        torpedoNode.run(SKAction.sequence(actionArray))
        
    }
    
    
    func didBegin(_ contact: SKPhysicsContact) {
        var firstBody:SKPhysicsBody
        var secondBody:SKPhysicsBody
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        }else{
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        if (firstBody.categoryBitMask & photonTorpedoCategory) != 0 && (secondBody.categoryBitMask & alienCategory) != 0 {
            torpedoDidCollideWithAlien(torpedoNode: firstBody.node as? SKSpriteNode, alienNode: secondBody.node as? SKSpriteNode)
        }
        
        
        if (firstBody.categoryBitMask & photonTorpedoCategory ) != 0 && (secondBody.categoryBitMask & alienDestroyerCategory) != 0 {
            torpedoDidCollideWithAlien(torpedoNode: firstBody.node as? SKSpriteNode, alienNode: secondBody.node as? SKSpriteNode)
        }
        
        
        if (firstBody.categoryBitMask == alienTorpedoCategory)  && (secondBody.categoryBitMask == playerCategory) || (firstBody.categoryBitMask == playerCategory ) && (secondBody.categoryBitMask == alienTorpedoCategory){
            alienTorpedoHitPlayer(playerNode: firstBody.node as? SKSpriteNode, alienTorpedoNode: secondBody.node as? SKSpriteNode)
        }
        
        if (firstBody.categoryBitMask == photonTorpedoCategory ) && (secondBody.categoryBitMask == alienTorpedoCategory) || (firstBody.categoryBitMask == alienTorpedoCategory) && (secondBody.categoryBitMask == photonTorpedoCategory) {
            torpedoCollidedWithTorpedo(playerTorpedo: firstBody.node as? SKSpriteNode, alienTorpedoNode: secondBody.node as? SKSpriteNode)
        }
    }
    
    func alienTorpedoHitPlayer (playerNode:SKSpriteNode?, alienTorpedoNode:SKSpriteNode?) {
        
        if let explosion = SKEmitterNode(fileNamed:  "Explosion") {
          
        
            if let torpedo = alienTorpedoNode {
                explosion.position = torpedo.position
            }
            
            self.addChild(explosion)
            
            self.run(SKAction.playSoundFileNamed("explosion.mp3", waitForCompletion: false))
            
            if let torpedo = alienTorpedoNode {
                torpedo.removeFromParent()
            }
            self.run(SKAction.wait(forDuration: 2)) {
                explosion.removeFromParent()
            }
        
        score -= 50
        }
    }
    
    func torpedoCollidedWithTorpedo(playerTorpedo: SKSpriteNode?, alienTorpedoNode:SKSpriteNode?){
        
        if let explosion = SKEmitterNode(fileNamed: "Explosion") {
            
            if let opponentTorpedo = alienTorpedoNode {
                explosion.position = opponentTorpedo.position
            }
            self.addChild(explosion)
            
            self.run(SKAction.playSoundFileNamed("explosion.mp3", waitForCompletion: false))
            if let opponentTorpedo = alienTorpedoNode {
                opponentTorpedo.removeFromParent()
            }
            
            if let myTorpedo = playerTorpedo {
                myTorpedo.removeFromParent()
            }
            
            self.run(SKAction.wait(forDuration: 2)) {
                explosion.removeFromParent()
            }
        }
    }
    
    func torpedoDidCollideWithAlien (torpedoNode:SKSpriteNode?, alienNode:SKSpriteNode?) {
        
        if let explosion = SKEmitterNode(fileNamed: "Explosion") {
            
            if let alien = alienNode {
                explosion.position = alien.position
            }
            
            self.addChild(explosion)
            
            self.run(SKAction.playSoundFileNamed("explosion.mp3", waitForCompletion: false))
            
            if let torpedo = torpedoNode {
                torpedo.removeFromParent()
            }
            
            if let alien = alienNode {
                alien.removeFromParent()
            }
            
            self.run(SKAction.wait(forDuration: 2)) {
                explosion.removeFromParent()
            }
            
            score += 5
        }
    }
    
    override func didSimulatePhysics() {
        
        player.position.x += xAcceleration * 50
        
        if player.position.x < -20 {
            player.position = CGPoint(x: self.size.width + 20, y: player.position.y)
        }else if player.position.x > self.size.width + 20 {
            player.position = CGPoint(x: -20, y: player.position.y)
        }
        
    }

    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
}
