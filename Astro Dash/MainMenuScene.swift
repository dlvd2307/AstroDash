//
//  MainMenuScene.swift
//  Astro Dash
//
//  Created by Dylan van Dijk on 03/08/2023.
//  Copyright © 2023 Dylan van Dijk. All rights reserved.
//


import SpriteKit
import UIKit
import Foundation

class MainMenuScene: SKScene {
    
    var bg1: SKSpriteNode!
    var bg2: SKSpriteNode!
    
    override func didMove(to view: SKView) {
        // Set up the background
        bg1 = SKSpriteNode(imageNamed: "space")
        bg1.size = self.size
        bg1.anchorPoint = CGPoint(x: 0.5, y: 0)
        bg1.position = CGPoint(x: frame.midX, y: frame.minY)
        bg1.zPosition = 0
        addChild(bg1)
        
        bg2 = SKSpriteNode(imageNamed: "space")
        bg2.size = self.size
        bg2.anchorPoint = CGPoint(x: 0.5, y: 0)
        bg2.position = CGPoint(x: frame.midX, y: bg1.position.y + bg1.size.height)
        bg2.zPosition = 0
        addChild(bg2)
        
        let moveDown = SKAction.moveBy(x: 0, y: -self.size.height, duration: 20)
        let moveReset = SKAction.moveBy(x: 0, y: self.size.height, duration: 0)
        let moveLoop = SKAction.sequence([moveDown, moveReset])
        let moveForever = SKAction.repeatForever(moveLoop)
        
        bg1.run(moveForever)
        bg2.run(moveForever)
        
        let title = SKLabelNode(fontNamed: "Chalkduster")
        title.text = "Astro Dash"
        title.fontSize = 70
        title.fontColor = SKColor.white
        title.position = CGPoint(x: self.size.width/20 - 20, y: self.size.height/20 + 300)
        title.zPosition = 1
        addChild(title)

        let startButton = SKLabelNode(fontNamed: "Chalkduster")
        startButton.text = "Start Game"
        startButton.fontSize = 50
        startButton.fontColor = SKColor.white
        startButton.position = CGPoint(x: self.size.width/20 - 20, y: self.size.height/20 - 20)
        startButton.zPosition = 1
        startButton.name = "startButton"
        addChild(startButton)

        let highScores = getHighScores()

        for (index, score) in highScores.enumerated() {
            let label = SKLabelNode(fontNamed: "Chalkduster")
            label.text = "High Score \(index + 1): \(score)"
            label.fontSize = 30
            label.fontColor = SKColor.white
            label.position = CGPoint(x: self.size.width/20 - 20, y: startButton.position.y - CGFloat((index + 1) * 40) - 300)
            label.zPosition = 1
            addChild(label)
        }



    }
    func getHighScores() -> [Int] {
        let defaults = UserDefaults.standard
        return defaults.array(forKey: "highScores") as? [Int] ?? [Int]()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            let location = t.location(in: self)
            let node = self.nodes(at: location)
            for n in node {
                if n.name == "startButton" {
                    let scene = GameScene(size: size)
                    scene.scaleMode = .aspectFill
                    let transition = SKTransition.fade(withDuration: 1.0)
                    self.view?.presentScene(scene, transition: transition)
                }
            }
        }
    }
}

