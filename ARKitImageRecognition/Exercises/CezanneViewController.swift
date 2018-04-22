//
//  CezanneViewController.swift
//  ARKitImageRecognition
//
//  Created by Jonathan Scheiding on 4/22/18.
//  Copyright © 2018 Apple. All rights reserved.
//

import Foundation
import ARKit
import SceneKit
import UIKit

class CezanneViewController : ViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapGesture(_:))))
    }
    
    override func getARReferenceImages() -> Set<ARReferenceImage>? {
        return ARReferenceImage.referenceImages(inGroupNamed: "Exercise - Cezanne", bundle: nil)
    }
    
    override func respondToImage(node: SCNNode, imageAnchor: ARImageAnchor) {
        let referenceImage = imageAnchor.referenceImage
        let referenceSize = referenceImage.physicalSize
        let iconSize = referenceSize.width / 4
        let startPoint = CGPoint(
            x: (-referenceSize.width / 2) + (iconSize / 2),
            y: (referenceSize.height / 2) + (iconSize / 2))

        self.referenceNode = node
        self.referenceImage = referenceImage
        
        let tipSize = CGSize(width: referenceSize.width, height: referenceSize.width * 0.368)
        let tipPosition = SCNVector3Make(0, 0, -Float(referenceSize.height + tipSize.height) * 1.1 / 2.0)
        self.addImage(name: "year", size: tipSize, position: tipPosition, node: node)
        
        ["year2", "year4", "year3", "year1"]
            .enumerated()
            .forEach { (index, name) in
                let size = CGSize(width: iconSize, height: iconSize)
                let position = SCNVector3(
                    x: Float(startPoint.x + (iconSize * CGFloat(index))),
                    y: 0,
                    z: Float(startPoint.y))
                
                let planeNode = self.addImage(name: name, size: size, position: position, node: node)
                planeNode.opacity = 0.6
        }
    }
    
    @objc func tapGesture(_ gesture: UITapGestureRecognizer) {
        let results = self.sceneView.hitTest(gesture.location(in: gesture.view), types: ARHitTestResult.ResultType.featurePoint)
        guard let result: ARHitTestResult = results.first else {
            return
        }
        
        let hits = self.sceneView.hitTest(gesture.location(in: gesture.view), options: nil)
        if let tappedNode = hits.first?.node {
            print("Tapped node: \(tappedNode.name)")
            if(tappedNode.name == "year2") {
                self.resetTracking()
                performSegue(withIdentifier: "showCezanne", sender: self)
            } else {
                self.showOverlay(year: tappedNode.name!)
            }
        }
    }
    
    func showOverlay(year: String) {
        guard let referenceImage = self.referenceImage else { return }
        guard let referenceNode = self.referenceNode else { return }
        
        let imageName =  "painting-\(year)"
        print("Showing \(imageName)")
        
        let overlay = SCNPlane(width: referenceImage.physicalSize.width,
                                 height: referenceImage.physicalSize.height)

        let overlayNode = SCNNode(geometry: overlay)
        overlayNode.opacity = 0

        let overlayImage = SCNMaterial()
        overlayImage.diffuse.contents = UIImage(named: imageName)

        overlay.materials = [overlayImage]
        
        overlayNode.eulerAngles.x = -.pi / 2
        referenceNode.addChildNode(overlayNode)
        overlayNode.runAction(self.fadeOverlayAction)
    }
    
    
    var fadeOverlayAction: SCNAction {
        return .sequence([
            .fadeOpacity(to: 1, duration: 0.5),
            .wait(duration: 1),
            .fadeOut(duration: 0.5),
            .removeFromParentNode()
            ])
    }
}
