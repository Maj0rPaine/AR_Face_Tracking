//
//  ViewController.swift
//  AR_Face_Tracking
//
//  Created by Chris Paine on 1/15/19.
//  Copyright © 2019 Chris Paine. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController {
    var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        guard ARFaceTrackingConfiguration.isSupported else {
            fatalError("Face tracking is not supported on this device")
        }
        
        sceneView = ARSCNView(frame: view.bounds)
        sceneView.delegate = self
        
        view.addSubview(sceneView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let config = ARFaceTrackingConfiguration()
        
        sceneView.session.run(config)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        sceneView.session.pause()
    }
}

extension ViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let plane = SCNPlane(width: 0.2, height: 0.25)
        plane.firstMaterial?.diffuse.contents = #imageLiteral(resourceName: "helmet")
        plane.firstMaterial?.isDoubleSided = false
        return SCNNode(geometry: plane)
    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        // Bump y position slightly
        let position = node.position
        node.position = SCNVector3(position.x, position.y + 0.03, position.z)
    }
}

