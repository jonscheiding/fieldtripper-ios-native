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
        let iconSize = referenceImage.physicalSize.width / 4
        let startPoint = CGPoint(
            x: (-referenceImage.physicalSize.width / 2) + (iconSize / 2),
            y: (referenceImage.physicalSize.height / 2) + (iconSize / 2))

        self.referenceNode = node
        self.referenceImage = referenceImage
        
        ["year1", "year2", "year3", "year4"]
            .enumerated()
            .forEach { (index, name) in
                let material = SCNMaterial()
                material.diffuse.contents = UIImage(named: name)
                
                let plane = SCNPlane(width: iconSize * 0.8, height: iconSize * 0.8)
                plane.materials = [material]
                
                let planeNode = SCNNode(geometry: plane)
                planeNode.opacity = 0.6
                
                planeNode.position = SCNVector3(
                    x: Float(startPoint.x - (iconSize * CGFloat(0.1)) + (iconSize * CGFloat(index))),
                    y: 0,
                    z: Float(startPoint.y + (iconSize * CGFloat(0.1))))
                
                /*
                 `SCNPlane` is vertically oriented in its local coordinate space, but
                 `ARImageAnchor` assumes the image is horizontal in its local space, so
                 rotate the plane to match.
                 */
                planeNode.eulerAngles.x = -.pi / 2
                planeNode.name = name
                node.addChildNode(planeNode)
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
