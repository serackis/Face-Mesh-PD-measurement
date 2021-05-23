//
//  ViewController.swift
//  True Depth
//
//  Created by Sai Kambampati on 2/23/19.
//  Copyright © 2019 AppCoda. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var faceLabel: UILabel!
    @IBOutlet weak var labelView: UIView!
    var analysis = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        labelView.layer.cornerRadius = 10

        sceneView.delegate = self
        sceneView.showsStatistics = true
        guard ARFaceTrackingConfiguration.isSupported else {
            fatalError("Face tracking is not supported on this device")
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Create a session configuration
        let configuration = ARFaceTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Pause the view's session
        sceneView.session.pause()
    }

    // MARK: - ARSCNViewDelegate
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let faceMesh = ARSCNFaceGeometry(device: sceneView.device!)
        let node = SCNNode(geometry: faceMesh)
        for x in [1076, 1070, 1163, 1168, 1094, 358, 1108, 1102, 20, 661, 888, 822, 1047, 462, 376, 39] {
            let text = SCNText(string: "\(x)", extrusionDepth: 1)
            let txtnode = SCNNode(geometry: text)
            txtnode.scale = SCNVector3(x: 0.0002, y: 0.0002, z: 0.0002)
            txtnode.name = "\(x)"
            node.addChildNode(txtnode)
            txtnode.geometry?.firstMaterial?.fillMode = .fill
        }
        node.geometry?.firstMaterial?.fillMode = .lines
        node.geometry?.firstMaterial?.transparency = 0
        return node
    }
    /// Creates A GLKVector3 From a Simd_Float4
    ///
    /// - Parameter transform: simd_float4
    /// - Returns: GLKVector3
    func glkVector3FromARFaceAnchorTransform(_ transform: simd_float4) -> GLKVector3{

        return GLKVector3Make(transform.x, transform.y, transform.z)
    }
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if let faceAnchor = anchor as? ARFaceAnchor, let faceGeometry = node.geometry as? ARSCNFaceGeometry {
            
            for x in 0..<1220 {
                   let child = node.childNode(withName: "\(x)", recursively: false)
                   child?.position = SCNVector3(faceAnchor.geometry.vertices[x])
               }
            
            faceGeometry.update(from: faceAnchor.geometry)
            expression(anchor: faceAnchor)

            DispatchQueue.main.async {
                self.faceLabel.text = self.analysis
            }

        }
        //1. Check We Have A Valid ARFaceAnchor
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }


        //2. Get The Position Of The Left & Right Eyes
        let leftEyePosition = glkVector3FromARFaceAnchorTransform(faceAnchor.leftEyeTransform.columns.3)
        let righEyePosition = glkVector3FromARFaceAnchorTransform(faceAnchor.rightEyeTransform.columns.3)

        //3. Calculate The Distance Between Them
        let distanceBetweenEyesInMetres = GLKVector3Distance(leftEyePosition, righEyePosition)
        var distanceBetweenEyesInMM = distanceBetweenEyesInMetres*10000
//        self.analysis += "The Distance Between The Eyes Is Approximatly \(distanceBetweenEyesInMM)"
        distanceBetweenEyesInMM = distanceBetweenEyesInMM.rounded()/10
        self.analysis += "PD: \(distanceBetweenEyesInMM)"
        //print("The Distance Between The Eyes Is Approximatly \(distanceBetweenEyesInMM)")

    }




    func expression(anchor: ARFaceAnchor) {
        let smileLeft = anchor.blendShapes[.mouthSmileLeft]
        let smileRight = anchor.blendShapes[.mouthSmileRight]
//        let cheekPuff = anchor.blendShapes[.cheekPuff]
        let tongue = anchor.blendShapes[.tongueOut]
        self.analysis = ""

        if ((smileLeft?.decimalValue ?? 0.0) + (smileRight?.decimalValue ?? 0.0)) > 0.9 {
            self.analysis += "You are smiling. "
        }

//        if cheekPuff?.decimalValue ?? 0.0 > 0.1 {
//            self.analysis += "Your cheeks are puffed. "
//        }

        if tongue?.decimalValue ?? 0.0 > 0.1 {
            self.analysis += "Don't stick your tongue out! "
        }
    }
}
