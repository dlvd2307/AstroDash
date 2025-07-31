//
//  GameViewController.swift
//  Astro Dash
//
//  Created by Dylan van Dijk on 03/08/2023.
//  Copyright © 2023 Dylan van Dijk. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit
import GoogleMobileAds




class GameViewController: UIViewController, GADBannerViewDelegate { // Conform to GADBannerViewDelegate
    var bannerView: GADBannerView!
    


    override func viewDidLoad() {

        super.viewDidLoad()
        
        bannerView = GADBannerView(adSize: GADAdSizeBanner)
        bannerView.delegate = self // Set the delegate
        bannerView.adUnitID = "ca-app-pub-2912046126777694/2815934945" // Replace with your AdMob ad unit ID
        bannerView.rootViewController = self
        bannerView.load(GADRequest())
        addBannerViewToView(bannerView)
        let bannerHeight = GADAdSizeBanner.size.height
        bannerView.frame = CGRect(x: (view.frame.size.width - GADAdSizeBanner.size.width) / 2,
                                  y: view.safeAreaInsets.top,
                                  width: GADAdSizeBanner.size.width,
                                  height: bannerHeight)


        if let scene = MainMenuScene(fileNamed: "MainMenuScene") {
            // Set the scale mode to scale to fit the window
            scene.scaleMode = .aspectFill
            
            // Present the scene
            if let view = self.view as! SKView? {
                view.presentScene(scene)
                view.presentScene(scene)
                view.ignoresSiblingOrder = true
                view.showsFPS = false
                view.showsNodeCount = false
                
                // Add constraints
                view.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    view.topAnchor.constraint(equalTo: self.view.topAnchor),
                    view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
                    view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                    view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
                ])
            }
        }
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
   
    func addBannerViewToView(_ bannerView: GADBannerView) {
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bannerView)

        NSLayoutConstraint.activate([
            bannerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            bannerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            bannerView.heightAnchor.constraint(equalToConstant: GADAdSizeBanner.size.height),
            bannerView.widthAnchor.constraint(equalToConstant: GADAdSizeBanner.size.width)
        ])
    }


        
    }
