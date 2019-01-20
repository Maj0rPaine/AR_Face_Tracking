//
//  ViewController.swift
//  AR_Face_Tracking
//
//  Created by Chris Paine on 1/15/19.
//  Copyright © 2019 Chris Paine. All rights reserved.
//

import UIKit
import ARKit

class SliderStack: UIStackView {
    var slider: UISlider = UISlider()
    
    var label: UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 30))
    
    var labelText: String!
    
    var valueChanged: ((_ value: Float) -> ())?
    
    convenience init(labelName: String, minVal: Float = -2, maxVal: Float = 2, defaultVal: Float = 0, valueChanged: @escaping (_ value: Float) -> ()) {
        self.init()
        label.text = "\(labelName): \(defaultVal)"
        label.textColor = .white
        
        labelText = labelName
        
        slider.minimumValue = minVal
        slider.maximumValue = maxVal
        slider.value = defaultVal
        slider.addTarget(self, action: #selector(sliderValueChanged(sender:)), for: .valueChanged)
        
        self.valueChanged = valueChanged
        
        addArrangedSubview(label)
        addArrangedSubview(slider)
        distribution = .fillEqually
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    @objc func sliderValueChanged(sender: UISlider) {
        label.text = "\(labelText!): \(sender.value)"
        valueChanged?(sender.value)
    }
}

class ViewController: UIViewController {
    var sceneView: ARSCNView!
    
    var orientationNumber:UInt32 = 6
    
    let redLayer = CIImage(image: #imageLiteral(resourceName: "red-layer"))
    
    var saturation: Float = 0.8
    
    var contrast: Float = 1.0
    
    var saturationLabel: UILabel = UILabel()
    
    var contrastLabel: UILabel = UILabel()
    
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
        
        let saturationStack = SliderStack(labelName: "Saturation", defaultVal: saturation) { (value) in
            self.saturation = value
        }
        let contrastStack = SliderStack(labelName: "Contrast", defaultVal: contrast) { (value) in
            self.contrast = value
        }
        
        let stackView = UIStackView(arrangedSubviews: [saturationStack, contrastStack])
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        stackView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        stackView.widthAnchor.constraint(equalToConstant: view.frame.width).isActive = true
        stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20).isActive = true
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
        guard let capturedImage = sceneView.session.currentFrame?.capturedImage,
            let ciOrientation = CGImagePropertyOrientation(rawValue: orientationNumber) else {
            return
        }
        
        let ciImage = CIImage.init(cvPixelBuffer: capturedImage)
    
        let multiplyFilter = CIFilter(name: "CIMultiplyCompositing")
        multiplyFilter?.setValue(redLayer, forKey: kCIInputImageKey)
        multiplyFilter?.setValue(ciImage, forKey: kCIInputBackgroundImageKey)
        
        var outputImage = multiplyFilter?.outputImage
        
        let colorFilter = CIFilter(name: "CIColorControls")
        colorFilter?.setValue(outputImage, forKey: kCIInputImageKey)
        colorFilter?.setValue(saturation, forKey: kCIInputSaturationKey)
        colorFilter?.setValue(contrast, forKey: kCIInputContrastKey)

        outputImage = colorFilter?.outputImage
    
        let context = CIContext()
        
        if let outputImage = outputImage?.oriented(ciOrientation),
            let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
            sceneView.scene.background.contents = cgImage
        }
    }
}
