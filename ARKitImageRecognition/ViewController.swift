/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Main view controller for the AR experience.
*/

import ARKit
import SceneKit
import UIKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    
    @IBOutlet weak var blurView: UIVisualEffectView!
    
    var successNode: SCNNode? = nil
    var failureNodes: [SCNNode] = []
    
    /// The view controller that displays the status and "restart experience" UI.
    lazy var statusViewController: StatusViewController = {
        return childViewControllers.lazy.flatMap({ $0 as? StatusViewController }).first!
    }()
    
    /// A serial queue for thread safety when modifying the SceneKit node graph.
    let updateQueue = DispatchQueue(label: Bundle.main.bundleIdentifier! +
        ".serialSceneKitQueue")
    
    /// Convenience accessor for the session owned by ARSCNView.
    var session: ARSession {
        return sceneView.session
    }
    
    var referenceNode: SCNNode? = nil
    var referenceImage: ARReferenceImage? = nil
    
    // MARK: - View Controller Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.session.delegate = self

        sceneView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapGesture(_:))))

        // Hook up status view controller callback(s).
        statusViewController.restartExperienceHandler = { [unowned self] in
            self.restartExperience()
        }
    }

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		// Prevent the screen from being dimmed to avoid interuppting the AR experience.
		UIApplication.shared.isIdleTimerDisabled = true

        // Start the AR experience
        resetTracking()
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

        session.pause()
	}

    // MARK: - Session management (Image detection setup)
    
    /// Prevents restarting the session while a restart is in progress.
    var isRestartAvailable = true

    /// Creates a new AR configuration to run on the `session`.
    /// - Tag: ARReferenceImage-Loading
	func resetTracking() {
        
        guard let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil) else {
            fatalError("Missing expected asset catalog resources.")
        }
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.detectionImages = referenceImages
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])

        statusViewController.scheduleMessage("Look around to detect images", inSeconds: 7.5, messageType: .contentPlacement)
	}

    // MARK: - ARSCNViewDelegate (Image detection results)
    /// - Tag: ARImageAnchor-Visualizing
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let imageAnchor = anchor as? ARImageAnchor else { return }
        let referenceImage = imageAnchor.referenceImage
        updateQueue.async {
            let iconSize = referenceImage.physicalSize.width / 4
            let startPoint = CGPoint(
                x: (-referenceImage.physicalSize.width / 2) + (iconSize / 2),
                y: (referenceImage.physicalSize.height / 2) + (iconSize / 2))

            self.referenceNode = node
            self.referenceImage = referenceImage
            
            ["hand", "nose", "ear", "foot"]
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
                    
                    node.addChildNode(planeNode)
                    
                    if(name == "ear") {
                        self.successNode = planeNode
                    } else {
                        self.failureNodes.append(planeNode)
                    }
                }
        }

        DispatchQueue.main.async {
            let imageName = referenceImage.name ?? ""
            self.statusViewController.cancelAllScheduledMessages()
            self.statusViewController.showMessage("Detected image “\(imageName)”")
        }
    }

    @objc func tapGesture(_ gesture: UITapGestureRecognizer) {
        let results = self.sceneView.hitTest(gesture.location(in: gesture.view), types: ARHitTestResult.ResultType.featurePoint)
        guard let result: ARHitTestResult = results.first else {
            return
        }
        
        let hits = self.sceneView.hitTest(gesture.location(in: gesture.view), options: nil)
        if let tappedNode = hits.first?.node {
            if(tappedNode == self.successNode) {
                self.resetTracking()
                performSegue(withIdentifier: "showVanGogh", sender: self)
            } else {
                self.failureNodes.forEach { node in
                    if (node == tappedNode) {
                        self.highlightImage(color: UIColor.red)
                    }
                }
            }
        }
    }
    
    func highlightImage(color: UIColor) {
        guard let referenceImage = self.referenceImage else { return }
        guard let referenceNode = self.referenceNode else { return }
        
        let highlight = SCNPlane(width: referenceImage.physicalSize.width,
                                 height: referenceImage.physicalSize.height)
        let highlightNode = SCNNode(geometry: highlight)
        highlightNode.opacity = 0
        
        let material = SCNMaterial()
        material.diffuse.contents = color
        highlight.materials = [material]
        
        highlightNode.eulerAngles.x = -.pi / 2
        referenceNode.addChildNode(highlightNode)
        highlightNode.runAction(self.imageHighlightAction)
    }
    
    var imageHighlightAction: SCNAction {
        return .sequence([
            .fadeOpacity(to: 0.45, duration: 0.25),
            .fadeOpacity(to: 0.15, duration: 0.25),
            .fadeOpacity(to: 0.45, duration: 0.25),
            .fadeOpacity(to: 0.15, duration: 0.25),
            .fadeOpacity(to: 0.45, duration: 0.25),
            .fadeOut(duration: 0.5),
            .removeFromParentNode()
        ])
    }
}
