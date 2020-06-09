//
//  SimultaneousCamera_ViewController.swift
//  ARKit-Invader
//
//  Created by drama on 2019/09/16.
//  Copyright © 2019 1901drama. All rights reserved.
//

import Foundation
import SceneKit
import ARKit
import UIKit
import ISEmojiView

class SimultaneousCamera_ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate, EmojiViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    @IBOutlet weak var textView: UITextView!
    
    var BackFaceNode = SCNNode()
    var FrontFaceNode = SCNNode()
    let device = MTLCreateSystemDefaultDevice()!
    private var originalJawY: Float = 0
    private var originalTongueZ: Float = 0
    
    private var jawNode : SCNNode?
    private var tongueNode : SCNNode?
    private var headNode : SCNNode?
    private var noseNode : SCNNode?
    private var eyeLeftNode : SCNNode?
    private var eyeRightNode : SCNNode?
    private var textNode : SCNNode?
    
    private var jawHeight: Float = 0.0
    
    private var tongueHeight: Float = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.session.delegate = self

        let configuration = ARWorldTrackingConfiguration()
        configuration.userFaceTrackingEnabled = true
        sceneView.session.run(configuration)
        

        BackFaceNode = SCNReferenceNode(named: "robotHead")
        jawNode = BackFaceNode.childNode(withName: "jaw", recursively: true)!
        tongueNode = BackFaceNode.childNode(withName: "tongue", recursively: true)!
        noseNode = BackFaceNode.childNode(withName: "nose", recursively: true)!
        eyeLeftNode = BackFaceNode.childNode(withName: "eyeLeft", recursively: true)!
        eyeRightNode = BackFaceNode.childNode(withName: "eyeRight", recursively: true)!
        jawHeight = {
            let (min, max) = jawNode!.boundingBox
            return max.y - min.y
        }()
        
        tongueHeight = {
            let (min, max) = tongueNode!.boundingBox
            return max.z - min.z
        }()
        BackFaceNode.position = SCNVector3(0,0,-0.2)
        BackFaceNode.geometry = ARSCNFaceGeometry(device: device)!
        sceneView.scene.rootNode.addChildNode(BackFaceNode)
        
        let keyboardSettings = KeyboardSettings(bottomType: .categories)
        let emojiView = EmojiView(keyboardSettings: keyboardSettings)
        emojiView.translatesAutoresizingMaskIntoConstraints = false
        emojiView.delegate = self
        textView.inputView = emojiView
    }

    // MARK: - Delegate
    
    // callback when tap a emoji on keyboard
    func emojiViewDidSelectEmoji(_ emoji: String, emojiView: EmojiView) {
        FrontFaceNode.geometry?.firstMaterial?.diffuse.contents = emoji.image()
    }
        
    // callback when tap delete button on keyboard
    func emojiViewDidPressDeleteBackwardButton(_ emojiView: EmojiView) {
        textView.resignFirstResponder()
    }


    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard anchor is ARFaceAnchor else { return }
        
        FrontFaceNode.geometry = ARSCNFaceGeometry(device: device)!
        jawNode!.geometry?.firstMaterial?.diffuse.contents = "👄".image()
        noseNode!.geometry?.firstMaterial?.diffuse.contents = "🐽".image()
        tongueNode!.geometry?.firstMaterial?.diffuse.contents = "👅".image()
        originalJawY = jawNode!.position.y
        originalTongueZ = tongueNode!.position.z
        node.addChildNode(FrontFaceNode)
    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
        
        let blendShapes = faceAnchor.blendShapes
                if #available(iOS 12.0, *) {
                    guard let eyeBlinkLeft = blendShapes[.eyeBlinkLeft] as? Float,
                        let eyeBlinkRight = blendShapes[.eyeBlinkRight] as? Float,
                        let jawOpen = blendShapes[.jawOpen] as? Float,
                        let tongueOut = blendShapes[.tongueOut] as? Float,
                        let noseSneerLeft = blendShapes[.noseSneerLeft] as? Float
                        else { return }
                    eyeLeftNode!.scale.z = 1 - eyeBlinkLeft
                    eyeRightNode!.scale.z = 1 - eyeBlinkRight
                    noseNode!.scale.x = 0.02 - noseSneerLeft
                    jawNode!.position.y = originalJawY - jawHeight * jawOpen
                    tongueNode!.position.z = originalTongueZ + tongueHeight * tongueOut
                } else {
                    // Fallback on earlier versions
                    guard let eyeBlinkLeft = blendShapes[.eyeBlinkLeft] as? Float,
                        let eyeBlinkRight = blendShapes[.eyeBlinkRight] as? Float,
                        let jawOpen = blendShapes[.jawOpen] as? Float
                        else { return }
                    eyeLeftNode!.scale.z = 1 - eyeBlinkLeft
                    eyeRightNode!.scale.z = 1 - eyeBlinkRight
                    jawNode!.position.y = originalJawY - jawHeight * jawOpen
                }
        
        for Node in node.childNodes{
            guard let geometry = Node.geometry as? ARSCNFaceGeometry else { return }
            geometry.update(from: faceAnchor.geometry)
            BackFaceNode.geometry = geometry
        }
    }
    
}
