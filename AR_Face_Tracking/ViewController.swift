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
    
    var orientationNumber:UInt32 = 6
    
    let redLayer = CIImage(image: #imageLiteral(resourceName: "red-layer"))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        guard ARFaceTrackingConfiguration.isSupported else {
            fatalError("Face tracking is not supported on this device")
        }
        
        sceneView = ARSCNView(frame: view.bounds)
        sceneView.delegate = self
        
        view.addSubview(sceneView)
        
        NotificationCenter.default.addObserver(self, selector: #selector(onOrientationChange(notification:)), name: UIDevice.orientationDidChangeNotification, object: nil)
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
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.all
    }
    
    @objc func onOrientationChange(notification: NSNotification){
        switch UIDevice.current.orientation {
        case .landscapeLeft:
            orientationNumber = 0
        case .landscapeRight:
            orientationNumber = 3
        case .portrait:
            orientationNumber = 6
        case .portraitUpsideDown:
            orientationNumber = 8
        default:
            orientationNumber = 6
        }
        
    }
}

extension ViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let plane = SCNPlane(width: 0.17, height: 0.22)
        plane.firstMaterial?.diffuse.contents = #imageLiteral(resourceName: "helmet")
        plane.firstMaterial?.isDoubleSided = false
        return SCNNode(geometry: plane)
    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        // Bump y position slightly
        let position = node.position
        node.position = SCNVector3(position.x, position.y + 0.03, position.z)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard let capturedImage = sceneView.session.currentFrame?.capturedImage else {
            return
        }
        
        let ciImage = CIImage.init(cvPixelBuffer: capturedImage)
        
        let filter: CIFilter = CIFilter(name: "CIMultiplyCompositing")!
        filter.setValue(redLayer, forKey: kCIInputImageKey)
        filter.setValue(ciImage, forKey: kCIInputBackgroundImageKey)
        
        let context = CIContext()
        
        let result = filter.outputImage!.oriented(CGImagePropertyOrientation(rawValue: orientationNumber)!)
        //let result = filter.outputImage!.applyingFilter("CIFalseColor", parameters: ["inputColor0": CIColor(color: UIColor.red), "inputColor1": CIColor(color: UIColor.clear)]).oriented(CGImagePropertyOrientation(rawValue: orientationNumber)!)
        
        if let cgImage = context.createCGImage(result, from: result.extent) {
            sceneView.scene.background.contents = cgImage
        }
        
    }
}
