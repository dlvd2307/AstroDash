//
//  Gamescene.swift
//  Astro Dash
//
//  Created by Dylan van Dijk on 03/08/2023.
//  Copyright © 2024 Dylan van Dijk. All rights reserved.
//



import GoogleMobileAds
import SpriteKit
import GameplayKit
import AVFoundation


//To keep spaceship within screen.
func clamp<T: Comparable>(_ value: T, min: T, max: T) -> T {
    if value < min {
        return min
    } else if value > max {
        return max
    } else {
        return value
    }
}
struct PhysicsCategories {
    static let none: UInt32 = 0
    static let spaceship: UInt32 = 0b1
    static let asteroid: UInt32 = 0b10
    static let projectile: UInt32 = 0b100
    static let powerUp: UInt32 = 0b1000 // New category for power-ups
}



    
class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var countdownTimer: Timer?
    var countdownValue: Int = 3
    var score = 0
    var scoreLabel: SKLabelNode!
    var spaceship: SKSpriteNode!
    var spaceshipExhaust: SKEmitterNode!
    var bg1: SKSpriteNode!
    var bg2: SKSpriteNode!
    var activeAsteroids: [SKSpriteNode] = []
    var spaceshipVelocity = CGVector(dx: 0, dy: 0)
    let maxAsteroids: Int = 20
    var gameIsOver = false
    var gameOverLabel: SKLabelNode!
    var tryAgainButton: SKSpriteNode!
    var musicButton: SKSpriteNode!
    var backgroundMusic: SKAudioNode!
    var isMusicPlaying = true
    var isMuted = false
    var spawnAsteroidAction: SKAction!
    var waitAction: SKAction!
    var backgroundMusicPlayer: AVAudioPlayer!
    var blasterButton: SKSpriteNode!
    var explosionSoundPlayer: AVAudioPlayer?
    var lastProjectileTime: TimeInterval = 0
    var isGameActive = true // This flag is used to check if the game is still active
    var finalScoreLabel: SKLabelNode! // Label to display the final score
    var activeBackgroundObject: SKSpriteNode? // Property to track active background object
    var shieldNode: SKSpriteNode?
  
    
    
    override func didMove(to view: SKView) {
       
        super.didMove(to: view)
        self.scaleMode = .aspectFill
        let scaleToFit = min(view.bounds.width / size.width, view.bounds.height / size.height)
        self.size.width *= scaleToFit
        self.size.height *= scaleToFit
        
        physicsWorld.contactDelegate = self
        
        let spawnAction = SKAction.run(spawnBackgroundObject)
        let delayAction = SKAction.wait(forDuration: 15) // 15 seconds between spawns
        let spawnOrder = SKAction.sequence([spawnAction, delayAction])
        let repeatSpawn = SKAction.repeatForever(spawnOrder)
        self.run(repeatSpawn)
        
        
        
        if let backgroundMusic = backgroundMusic {
            backgroundMusic.autoplayLooped = true
            addChild(backgroundMusic)
        }
        
        if let soundURL = Bundle.main.url(forResource: "explosionSound", withExtension: "mp3") {
            do {
                explosionSoundPlayer = try AVAudioPlayer(contentsOf: soundURL)
            } catch {
                print("Error loading explosion sound: \(error)")
            }
        }
        loadExplosionSound()
        
        musicButton = SKSpriteNode(imageNamed: isMuted ? "musicOff" : "musicOn")
        musicButton.xScale = 0.5
        musicButton.yScale = 0.5
        musicButton.position = CGPoint(x: frame.maxX - 50, y: frame.minY + 50)
        musicButton.name = "musicButton"
        addChild(musicButton)
        
        if let musicPath = Bundle.main.path(forResource: "backgroundMusic", ofType: "mp3") {
            let url = URL(fileURLWithPath: musicPath)
            backgroundMusicPlayer = try? AVAudioPlayer(contentsOf: url)
            backgroundMusicPlayer.numberOfLoops = -1 // Infinite loop
            backgroundMusicPlayer.play()
        }
        
        spawnAsteroidAction = SKAction.run { [unowned self] in self.spawnAsteroid() }
        waitAction = SKAction.wait(forDuration: 0.5) // Set a fixed wait duration of 1 second
        
        
        // Set up score label
        scoreLabel = SKLabelNode(fontNamed: "Chalkduster")
        scoreLabel.text = "Score: 0"
        scoreLabel.fontSize = 15
        scoreLabel.fontColor = SKColor.white
        scoreLabel.position = CGPoint(x: frame.minX + 80, y: frame.maxY - 100)
        addChild(scoreLabel)
        
        
        // Start incrementing score
        let incrementScoreAction = SKAction.run { [unowned self] in
            self.score += 10
            self.scoreLabel.text = "Score: \(self.score)"
        }
        let waitOneSecondAction = SKAction.wait(forDuration: 1)
        let scoreSequence = SKAction.sequence([waitOneSecondAction, incrementScoreAction])
        let scoreForever = SKAction.repeatForever(scoreSequence)
        run(scoreForever, withKey: "incrementingScore")
        
        // Start spawning asteroids
        let spawnSequence = SKAction.sequence([spawnAsteroidAction, waitAction])
        let spawnForever = SKAction.repeatForever(spawnSequence)
        run(spawnForever, withKey: "spawning")
        
        spaceship = SKSpriteNode(imageNamed: "spaceship")
        spaceship.xScale = 0.5
        spaceship.yScale = 0.5
        spaceship.position = CGPoint(x: view.bounds.midX, y: view.bounds.minY + spaceship.frame.height / 2 + 50)
        spaceship.physicsBody = SKPhysicsBody(circleOfRadius: spaceship.size.width/2)
        spaceship.physicsBody?.affectedByGravity = false
        spaceship.physicsBody?.categoryBitMask = PhysicsCategories.spaceship
        spaceship.physicsBody?.collisionBitMask = PhysicsCategories.asteroid
        spaceship.physicsBody?.contactTestBitMask = PhysicsCategories.asteroid
        
        
        spaceship.name = "spaceship"
        addChild(spaceship)
        
        
        tryAgainButton = SKSpriteNode(imageNamed: "button")
        tryAgainButton.position = CGPoint(x: frame.midX, y: frame.midY - 100)
        tryAgainButton.isHidden = true
        addChild(tryAgainButton)
        
        bg1 = SKSpriteNode(imageNamed: "space")
        bg1.size = view.bounds.size
        bg1.anchorPoint = CGPoint(x: 0.5, y: 0)
        bg1.position = CGPoint(x: frame.midX, y: frame.minY)
        bg1.zPosition = -2
        addChild(bg1)
        
        bg2 = SKSpriteNode(imageNamed: "space")
        bg2.size = view.bounds.size
        bg2.anchorPoint = CGPoint(x: 0.5, y: 0)
        bg2.position = CGPoint(x: frame.midX, y: bg1.position.y + bg1.size.height)
        bg2.zPosition = -2
        addChild(bg2)
        
        let moveDown = SKAction.moveBy(x: 0, y: -self.size.height, duration: 10)
        let moveReset = SKAction.moveBy(x: 0, y: self.size.height, duration: 0)
        let moveLoop = SKAction.sequence([moveDown, moveReset])
        let moveForever = SKAction.repeatForever(moveLoop)
        
        bg1.run(moveForever)
        bg2.run(moveForever)
        
        
        physicsWorld.gravity = CGVector(dx: 0, dy: 0) // No gravity
        
        blasterButton = SKSpriteNode(imageNamed: "blasterButton")
        blasterButton?.size = CGSize(width: blasterButton.size.width * 1.5, height: blasterButton.size.height * 1.5)
        blasterButton?.position = CGPoint(x: frame.maxX - 300, y: frame.minY + 70)
        blasterButton?.name = "blasterButton"
        if let blaster = blasterButton {
            addChild(blaster)
        }
        let spawnPowerUpAction = SKAction.run { [unowned self] in self.spawnPowerUp() }
        let powerUpSpawnDelay = SKAction.wait(forDuration: 30.0) // Spawn a power-up every 10 seconds
        let powerUpSpawnSequence = SKAction.sequence([spawnPowerUpAction, powerUpSpawnDelay])
        let powerUpSpawnForever = SKAction.repeatForever(powerUpSpawnSequence)
        run(powerUpSpawnForever, withKey: "spawnPowerUp")
        
        func startSpawningObjects() {
            let spawnAction = SKAction.run(spawnBackgroundObject)
            let delayAction = SKAction.wait(forDuration: 10) // 20 seconds between spawns
            let spawnOrder = SKAction.sequence([spawnAction, delayAction])
            let repeatSpawn = SKAction.repeatForever(spawnOrder)
            self.run(repeatSpawn)
        }
        
        
    }
    
    @objc func spawnBackgroundObject() {
        print("Attempting to spawn background object...")
        guard activeBackgroundObject == nil else {
            print("Background object already active.")
            return
        }
        
        // List of available background object images
        let objects = ["planet", "planet01", "planet02", "planet03", "planet04", "planet05", "planet06", "planet07", "planet08", "planet09"]
        
        // Pick a random object
        let randomIndex = Int(arc4random_uniform(UInt32(objects.count)))
        let object = SKSpriteNode(imageNamed: objects[randomIndex])
        
        // Set the scale randomly among three predefined scales
        let scales: [CGFloat] = [0.01, 0.03, 0.05, 0.08, 0.1, 0.3,0.5, 0.7] // Adjust these scales as you see fit
            let randomScaleIndex = Int(arc4random_uniform(UInt32(scales.count)))
           
        // Set the object's position, size, and zPosition so it appears in the background
        object.zPosition = -1
        object.setScale(scales[randomScaleIndex])
        object.position = CGPoint(x: CGFloat(GKRandomSource.sharedRandom().nextInt(upperBound: Int(size.width))), y: size.height + object.size.height / 2)
        
        activeBackgroundObject = object
        addChild(object)
        
        let moveAction = SKAction.moveBy(x: 0, y: -(size.height + object.size.height), duration: 15) // Adjust duration as needed
        
        let clearAction = SKAction.run { [weak self] in
            self?.activeBackgroundObject = nil
        }
        let removeAction = SKAction.removeFromParent()
        let moveAndClear = SKAction.sequence([moveAction, clearAction, removeAction])
        object.run(moveAndClear)
        
     
    }
    func startCountdown(completion: @escaping () -> Void) {
        let countdownLabel = SKLabelNode(fontNamed: "Chalkduster")
        countdownLabel.fontSize = 30
        countdownLabel.fontColor = SKColor.white
        countdownLabel.position = CGPoint(x: frame.midX, y: frame.midY)
        countdownLabel.zPosition = 100
        addChild(countdownLabel)
    
        let countdownAction = SKAction.sequence([
            SKAction.run { countdownLabel.text = "3" },
            SKAction.wait(forDuration: 1),
            SKAction.run { countdownLabel.text = "2" },
            SKAction.wait(forDuration: 1),
            SKAction.run { countdownLabel.text = "1" },
            SKAction.wait(forDuration: 1),
            SKAction.run {
                countdownLabel.removeFromParent()
                completion() // This will start the game
            }
        ])

        countdownLabel.run(countdownAction)
    }
    func toggleMusic() {
        isMusicPlaying = !isMusicPlaying
        if isMusicPlaying {
            musicButton.texture = SKTexture(imageNamed: "musicOn")
            backgroundMusicPlayer.play()
        } else {
            musicButton.texture = SKTexture(imageNamed: "musicOff")
            backgroundMusicPlayer.pause()
        }
    }
    
    func shootBlaster() {
        
        let projectile = SKSpriteNode(imageNamed: "projectile")
        let currentTime = CACurrentMediaTime()
        let fireRate: TimeInterval = 0.5 // Set the desired fire rate in seconds (1 projectile per second in this example)
        
        if currentTime - lastProjectileTime >= fireRate {
            lastProjectileTime = currentTime
            
            projectile.position = spaceship.position
            projectile.zPosition = 1
            projectile.name = "projectile"
            
            // Physics properties for collision detection
            projectile.physicsBody = SKPhysicsBody(rectangleOf: projectile.size)
            projectile.physicsBody?.categoryBitMask = PhysicsCategories.projectile
            projectile.physicsBody?.collisionBitMask = PhysicsCategories.none
            
            projectile.physicsBody?.contactTestBitMask = PhysicsCategories.asteroid
            
            addChild(projectile)
            
            // Move the projectile upwards
            let moveUp = SKAction.moveBy(x: 0, y: size.height, duration: 1)
            let remove = SKAction.removeFromParent()
            projectile.run(SKAction.sequence([moveUp, remove]))
        }
    }
    func loadExplosionSound() {
        if let soundURL = Bundle.main.url(forResource: "explosionSound", withExtension: "mp3") {
            do {
                explosionSoundPlayer = try AVAudioPlayer(contentsOf: soundURL)
            } catch {
                print("Error loading explosion sound: \(error)")
            }
        }
    }
    func spawnPowerUp() {
        let powerUp = SKSpriteNode(imageNamed: "powerUp") // Assuming you have an image asset named "powerUp"
        powerUp.xScale = 0.5
        powerUp.yScale = 0.5
        powerUp.position = CGPoint(x: CGFloat.random(in: frame.minX + powerUp.size.width/2 ... frame.maxX - powerUp.size.width/2),
                                  y: frame.maxY + powerUp.size.height/2)
        powerUp.physicsBody = SKPhysicsBody(circleOfRadius: powerUp.size.width/2)
        powerUp.physicsBody?.categoryBitMask = PhysicsCategories.powerUp
        powerUp.physicsBody?.collisionBitMask = PhysicsCategories.none
        powerUp.physicsBody?.contactTestBitMask = PhysicsCategories.spaceship
        powerUp.name = "powerUp"
        addChild(powerUp)

        let moveAction = SKAction.moveBy(x: 0, y: -frame.size.height - powerUp.size.height, duration: 10.0)
        let removeAction = SKAction.removeFromParent()
        let moveAndRemove = SKAction.sequence([moveAction, removeAction])
        powerUp.run(moveAndRemove)
    }
    
    
    func spawnAsteroid() {
        guard activeAsteroids.count < maxAsteroids else { return }
        print("Asteroids array size: \(activeAsteroids.count)") // Debug print
        
        let asteroid = SKSpriteNode(imageNamed: "asteroid")
        asteroid.xScale = 0.5
        asteroid.yScale = 0.5
        let randomScale = CGFloat(GKRandomSource.sharedRandom().nextUniform() * 1.0 + 0.2)
        asteroid.setScale(randomScale)
        asteroid.physicsBody = SKPhysicsBody(circleOfRadius: asteroid.size.width/2)
        asteroid.physicsBody?.categoryBitMask = PhysicsCategories.asteroid
        asteroid.physicsBody?.collisionBitMask = PhysicsCategories.asteroid // Asteroids will only collide with other asteroids
        asteroid.physicsBody?.contactTestBitMask = PhysicsCategories.spaceship | PhysicsCategories.projectile
        asteroid.physicsBody?.restitution = 1 // Perfectly elastic collisions
        asteroid.physicsBody?.linearDamping = 0 // No drag
        asteroid.physicsBody?.mass = randomScale // Mass proportional to size
        
        
        let randomSpeed = CGFloat(GKRandomSource.sharedRandom().nextUniform() * 300.0 + 100.0)
        let randomX = GKRandomDistribution(lowestValue: Int(frame.minX + asteroid.frame.width/2), highestValue: Int(frame.maxX - asteroid.frame.width/2))
        asteroid.position = CGPoint(x: CGFloat(randomX.nextInt()), y: frame.maxY + asteroid.frame.height/2)
        let randomDX = GKRandomDistribution(lowestValue: -50, highestValue: 50)
        asteroid.physicsBody?.velocity = CGVector(dx: randomDX.nextInt(), dy: -Int(randomSpeed))
        
        asteroid.name = "asteroid"
        addChild(asteroid)
        activeAsteroids.append(asteroid)
        
        let moveAction = SKAction.moveBy(x: 0, y: -frame.size.height, duration: 20.0)
        let removeAction = SKAction.removeFromParent()
        let moveAndRemove = SKAction.sequence([moveAction, removeAction])
        
        asteroid.run(moveAndRemove) { [weak self] in
            if let index = self?.activeAsteroids.firstIndex(of: asteroid) {
                self?.activeAsteroids.remove(at: index)
            }
        }
    }
    func activatePowerUp(spaceship: SKSpriteNode, powerUp: SKSpriteNode) {
        // Grant temporary invincibility
        spaceship.physicsBody?.categoryBitMask = PhysicsCategories.none // Spaceship becomes intangible
        // Create and add the shield node
           shieldNode = SKSpriteNode(imageNamed: "shield") // Assuming you have an image asset named "shield"
           shieldNode?.position = spaceship.position
           shieldNode?.zPosition = spaceship.zPosition - 1 // Make the shield appear behind the spaceship
           shieldNode?.alpha = 0.5 // Set the shield's transparency
           addChild(shieldNode!)
        let invincibilityDuration: TimeInterval = 8.0 // 5 seconds of invincibility
        let restorePhysicsCategory = SKAction.run {
            spaceship.physicsBody?.categoryBitMask = PhysicsCategories.spaceship
        }
        let invincibilityAction = SKAction.sequence([
            SKAction.wait(forDuration: invincibilityDuration),
            restorePhysicsCategory
        ])
        spaceship.run(invincibilityAction)

        // Remove the power-up from the scene
        powerUp.removeFromParent()
    }
    
    
    
    
    func projectileDidCollideWithAsteroid(projectile: SKSpriteNode, asteroid: SKSpriteNode) {
        // Create explosion effect for the projectile
        if let projectileExplosion = SKEmitterNode(fileNamed: "ProjectileExplosion") {
            projectileExplosion.position = projectile.position
            addChild(projectileExplosion)
        }
        let explosionSound = SKAction.playSoundFileNamed("rockexplosion.mp3", waitForCompletion: false)
        run(explosionSound)
        
        // Create explosion effect for the asteroid
        if let asteroidExplosion = SKEmitterNode(fileNamed: "AsteroidExplosion") {
            asteroidExplosion.position = asteroid.position
            addChild(asteroidExplosion)
        }
        
        // Remove the projectile and asteroid from the scene
        projectile.removeFromParent()
        asteroid.removeFromParent()
        
        if let index = activeAsteroids.firstIndex(of: asteroid) {
            activeAsteroids.remove(at: index)
        }
        // Increment score
        score += 10
        scoreLabel.text = "Score: \(score)"
    }
    
    
    
    override func update(_ currentTime: TimeInterval) {
        // Apply spaceship velocity
        spaceship.position.x += spaceshipVelocity.dx
        spaceship.position.y += spaceshipVelocity.dy
        
        // Clamp the new position to keep the spaceship within the screen bounds
        let clampedX = clamp(spaceship.position.x, min: spaceship.size.width / 2, max: size.width - spaceship.size.width / 2)
        let clampedY = clamp(spaceship.position.y, min: spaceship.size.height / 2, max: size.height - spaceship.size.height / 2)
        
        
        spaceship.position = CGPoint(x: clampedX, y: clampedY)
        
        // Remove asteroids that are no longer on the screen
        for asteroid in activeAsteroids {
            if !frame.intersects(asteroid.frame) {
                if let index = activeAsteroids.firstIndex(of: asteroid) {
                    activeAsteroids.remove(at: index)
                    // Update the shield's position to match the spaceship
                        if let shield = shieldNode {
                            shield.position = spaceship.position
                        }
                    }
                }
            }
        }
    }
    
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        if blasterButton?.frame.contains(location) == true {
            shootBlaster()
        } else if musicButton.frame.contains(location) {
            toggleMusic()
        } else if tryAgainButton.frame.contains(location) && !tryAgainButton.isHidden {
            restartGame()
        } else {
            setSpaceshipVelocity(for: location) //Only set velocity on touches began
        }
    }
    
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        setSpaceshipVelocity(for: location) // Continuously update velocity while moving
    }
    
    func setSpaceshipVelocity(for location: CGPoint) {
        let dx = location.x - spaceship.position.x
        let dy = location.y - spaceship.position.y
        let angle = atan2(dy, dx)
        
        spaceship.run(SKAction.rotate(toAngle: angle - CGFloat.pi / 2, duration: 0.1))
        
        let distance = sqrt(dx * dx + dy * dy)
        let speed: CGFloat = 0.05 // Adjust this value to change the damping effect
        
        // Apply easing using linear interpolation (lerp)
        let easedDX = lerp(start: spaceshipVelocity.dx, end: speed * dx, t: 0.2)
        let easedDY = lerp(start: spaceshipVelocity.dy, end: speed * dy, t: 0.2)
        spaceshipVelocity = CGVector(dx: easedDX, dy: easedDY)
    }
    
    func lerp(start: CGFloat, end: CGFloat, t: CGFloat) -> CGFloat {
        return (1 - t) * start + t * end
    }
    
    func explodeSpaceship() {
        if let spaceshipExplosion = SKEmitterNode(fileNamed: "SpaceshipExplosion") {
            spaceshipExplosion.position = spaceship.position
            addChild(spaceshipExplosion)
            
            // Play the explosion sound
            explosionSoundPlayer?.play()
        }
        
        spaceship.removeFromParent()
        gameIsOver = true
        showGameOver()
    }
    func spaceshipDidCollideWithAsteroid(spaceship: SKSpriteNode, asteroid: SKSpriteNode) {
        // Create explosion effect for the spaceship
        if let spaceshipExplosion = SKEmitterNode(fileNamed: "SpaceshipExplosion") {
            spaceshipExplosion.position = spaceship.position
            addChild(spaceshipExplosion)
        }
        
        // Create explosion effect for the asteroid
        if let asteroidExplosion = SKEmitterNode(fileNamed: "AsteroidExplosion") {
            asteroidExplosion.position = asteroid.position
            addChild(asteroidExplosion)
        }
        
        // Play the explosion sound
        explosionSoundPlayer?.play()
        
        // Remove the spaceship and asteroid from the scene
        spaceship.removeFromParent()
        asteroid.removeFromParent()
        
        // Handle game over or any other actions you may want to take
        // For example, show the "Game Over" label and restart button.
        showGameOver()
    }
    
    
    
    func didBegin(_ contact: SKPhysicsContact) {
        let firstBody = contact.bodyA
        let secondBody = contact.bodyB
        
        if (firstBody.categoryBitMask == PhysicsCategories.spaceship && secondBody.categoryBitMask == PhysicsCategories.asteroid) ||
            (firstBody.categoryBitMask == PhysicsCategories.asteroid && secondBody.categoryBitMask == PhysicsCategories.spaceship) {
            // Spaceship collided with an asteroid
            spaceshipDidCollideWithAsteroid(spaceship: firstBody.node as! SKSpriteNode, asteroid: secondBody.node as! SKSpriteNode)
        } else if firstBody.categoryBitMask == PhysicsCategories.projectile && secondBody.categoryBitMask == PhysicsCategories.asteroid {
            // Projectile collided with an asteroid
            if let projectile = firstBody.node as? SKSpriteNode,
               let asteroid = secondBody.node as? SKSpriteNode {
                projectileDidCollideWithAsteroid(projectile: projectile, asteroid: asteroid)
            }
        } else if (firstBody.categoryBitMask == PhysicsCategories.spaceship && secondBody.categoryBitMask == PhysicsCategories.powerUp) ||
                  (firstBody.categoryBitMask == PhysicsCategories.powerUp && secondBody.categoryBitMask == PhysicsCategories.spaceship) {
            // Spaceship collided with a power-up
            activatePowerUp(spaceship: firstBody.node as! SKSpriteNode, powerUp: secondBody.node as! SKSpriteNode)

        }
    }
    func activatePowerUp(spaceship: SKSpriteNode, powerUp: SKSpriteNode) {
        // Implement your power-up logic here
        // For example, you can temporarily increase the spaceship's firepower or speed
        print("Power-up collected!")

        // Remove the power-up from the scene
        powerUp.removeFromParent()
    }
    
    func updateScore() {
        if isGameActive { // Only update the score if the game is still active
            // Your code to update the score goes here
        }
    }
    
    
    func showGameOver() {
        isGameActive = false // Stop updating the score
        gameOverLabel = SKLabelNode(fontNamed: "Chalkduster")
        gameOverLabel.text = "Game Over!"
        gameOverLabel.fontSize = 30
        gameOverLabel.fontColor = SKColor.red
        gameOverLabel.position = CGPoint(x: frame.midX, y: frame.midY)
        gameOverLabel.zPosition = 200
        addChild(gameOverLabel)
        addRestartLabel()
        tryAgainButton.isHidden = false
        // Stop all actions and physics
        self.physicsWorld.speed = 0
        self.removeAction(forKey: "spawning")
        self.removeAction(forKey: "incrementingScore") // Stop incrementing score
        finalScoreLabel = SKLabelNode(fontNamed: "Chalkduster")
        finalScoreLabel.text = "" // Initially empty
        finalScoreLabel.fontSize = 15
        finalScoreLabel.position = CGPoint(x: size.width/2, y: size.height/2 - 20)
        addChild(finalScoreLabel)
        finalScoreLabel.text = "Final Score: \(score)"
        
        let isNewHighScore = checkForNewHighScore(score)
        if isNewHighScore {
            let congratsLabel = SKLabelNode(fontNamed: "Chalkduster")
            congratsLabel.text = "Congratulations, new high score!"
            congratsLabel.fontSize = 15
            congratsLabel.fontColor = SKColor.white
            congratsLabel.position = CGPoint(x: frame.midX, y: frame.midY + 50)
            congratsLabel.zPosition = 10
            addChild(congratsLabel)
            
            
        }
    }
    
    func addRestartLabel() {
        let restartLabel = SKLabelNode(fontNamed: "Chalkduster")
        restartLabel.text = "Restart?"
        restartLabel.fontSize = 20
        restartLabel.fontColor = SKColor.white
        restartLabel.position = CGPoint(x: size.width/2, y: size.height/2 - 50)
        restartLabel.zPosition = 200
        restartLabel.name = "restartLabel"
        addChild(restartLabel)
    }
    
    
    func stopGame() {
        // Stop all actions and physics
        self.physicsWorld.speed = 0
        self.removeAction(forKey: "spawning")
        self.removeAction(forKey: "incrementingScore") // Stop incrementing score
        
        
        
    }
    
    
    func restartGame() {
        self.physicsWorld.speed = 1
        self.removeAllChildren()
        activeAsteroids.removeAll() // Clear the activeAsteroids array
        self.removeAction(forKey: "spawnBackgroundObject")
        self.scaleMode = .aspectFill
        let view = self.view!
        let scaleToFit = min(view.bounds.width / size.width, view.bounds.height / size.height)
        self.size.width *= scaleToFit
        self.size.height *= scaleToFit
        activeBackgroundObject = nil
            for asteroid in activeAsteroids {
                asteroid.removeFromParent()
            }
            activeAsteroids.removeAll()
            
            let restartButton = childNode(withName: "restartButton")
            restartButton?.removeFromParent()
            
            
            // Reset spaceship
            spaceship = SKSpriteNode(imageNamed: "spaceship")
            spaceship.xScale = 0.5
            spaceship.yScale = 0.5
            spaceship.position = CGPoint(x: frame.midX, y: frame.minY + spaceship.frame.height/2 + 50)
            spaceship.physicsBody = SKPhysicsBody(circleOfRadius: spaceship.size.width/2)
            spaceship.physicsBody?.affectedByGravity = false
            spaceship.physicsBody?.categoryBitMask = PhysicsCategories.spaceship
            spaceship.physicsBody?.contactTestBitMask = PhysicsCategories.asteroid
            spaceship.physicsBody?.collisionBitMask = 0 // spaceship doesn't collide with anything
            spaceship.name = "spaceship"
            addChild(spaceship)
            
            // Reset background
            bg1 = SKSpriteNode(imageNamed: "space")
            bg1.size = self.size
            bg1.anchorPoint = CGPoint(x: 0.5, y: 0)
            bg1.position = CGPoint(x: frame.midX, y: frame.minY)
            bg1.zPosition = -1
            addChild(bg1)
            
            bg2 = SKSpriteNode(imageNamed: "space")
            bg2.size = self.size
            bg2.anchorPoint = CGPoint(x: 0.5, y: 0)
            bg2.position = CGPoint(x: frame.midX, y: bg1.position.y + bg1.size.height)
            bg2.zPosition = -1
            addChild(bg2)
            
            let moveDown = SKAction.moveBy(x: 0, y: -self.size.height, duration: 15)
            let moveReset = SKAction.moveBy(x: 0, y: self.size.height, duration: 0)
            let moveLoop = SKAction.sequence([moveDown, moveReset])
            let moveForever = SKAction.repeatForever(moveLoop)
            
            bg1.run(moveForever)
            bg2.run(moveForever)
            
        let spawnAction = SKAction.run(spawnBackgroundObject)
            let delayAction = SKAction.wait(forDuration: 30) // 20 seconds between spawns
            let spawnOrder = SKAction.sequence([spawnAction, delayAction])
            let repeatSpawn = SKAction.repeatForever(spawnOrder)
            self.run(repeatSpawn, withKey: "spawnBackgroundObject") // Use a key to identify the action
            
            
            
            // Reset tryAgainButton
            tryAgainButton = SKSpriteNode(imageNamed: "button")
            tryAgainButton.position = CGPoint(x: frame.midX, y: frame.midY - 100)
            tryAgainButton.isHidden = true
            tryAgainButton.zPosition = 200
            addChild(tryAgainButton)
            
            if action(forKey: "spawning") == nil {
                // Restart asteroid spawning
                spawnAsteroidAction = SKAction.run { [unowned self] in self.spawnAsteroid() }
                waitAction = SKAction.wait(forDuration: 0.5) // Set a fixed wait duration of 1 second
                let spawnSequence = SKAction.sequence([spawnAsteroidAction, waitAction])
                let spawnForever = SKAction.repeatForever(spawnSequence)
                run(spawnForever, withKey: "spawning")
                
            }
            
            
            // Reset score
            score = 0
            
            // Reset score label
            scoreLabel = SKLabelNode(fontNamed: "Chalkduster")
            scoreLabel.text = "Score: 0"
            scoreLabel.fontSize = 15
            scoreLabel.fontColor = SKColor.white
            scoreLabel.position = CGPoint(x: frame.minX + 80, y: frame.maxY - 100)
            scoreLabel.zPosition = 1 // Set zPosition to 1 so it's drawn on top of the background
            addChild(scoreLabel) // Add score label back to the scene
            
            // Start incrementing score
            let incrementScoreAction = SKAction.run { [unowned self] in
                self.score += 10
                self.scoreLabel.text = "Score: \(self.score)"
            }
            let waitOneSecondAction = SKAction.wait(forDuration: 1)
            let scoreSequence = SKAction.sequence([waitOneSecondAction, incrementScoreAction])
            let scoreForever = SKAction.repeatForever(scoreSequence)
            run(scoreForever, withKey: "incrementingScore") // Restart incrementing score
            
            if backgroundMusicPlayer != nil && !backgroundMusicPlayer.isPlaying {
                backgroundMusicPlayer.play()
            }
            musicButton = SKSpriteNode(imageNamed: isMuted ? "musicOff" : "musicOn")
            musicButton.xScale = 0.5
            musicButton.yScale = 0.5
            musicButton.position = CGPoint(x: frame.maxX - 50, y: frame.minY + 50)
            musicButton.name = "musicButton"
            addChild(musicButton)
            
            blasterButton = SKSpriteNode(imageNamed: "blasterButton")
            blasterButton?.size = CGSize(width: blasterButton.size.width * 1.5, height: blasterButton.size.height * 1.5)
            blasterButton?.position = CGPoint(x: frame.maxX - 300, y: frame.minY + 70)
            blasterButton?.name = "blasterButton"
            if let blaster = blasterButton {
                addChild(blaster)
            }
            
        }
        func saveHighScore(_ score: Int) {
            let defaults = UserDefaults.standard
            var highScores = defaults.array(forKey: "highScores") as? [Int] ?? [Int]()
            
            highScores.append(score)
            highScores.sort(by: >) // Sort in descending order
            highScores = Array(highScores.prefix(3)) // Keep only the top 3 scores
            
            defaults.set(highScores, forKey: "highScores")
        }
        
        func getHighScores() -> [Int] {
            let defaults = UserDefaults.standard
            return defaults.array(forKey: "highScores") as? [Int] ?? [Int]()
        }
        func checkForNewHighScore(_ score: Int) -> Bool {
            let highScores = getHighScores()
            
            if highScores.count < 3 || score > highScores.last! {
                saveHighScore(score)
                return true
            }
            
            return false
        }
        func displayHighScores() {
            let highScores = getHighScores()
            
            for (index, score) in highScores.enumerated() {
                let label = SKLabelNode(fontNamed: "Chalkduster")
                label.text = "High Score \(index + 1): \(score)"
                label.fontSize = 20
                label.fontColor = SKColor.white
                label.position = CGPoint(x: frame.midX, y: frame.midY - CGFloat(index * 30))
                label.zPosition = 10
                addChild(label)
            }
        }
    
