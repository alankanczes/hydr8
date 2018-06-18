//
//  GameViewController.swift
//  GeometryFighter
//
//  Created by Alan Kanczes on 6/10/18.
//  Copyright © 2018 Alan Kanczes. All rights reserved.
//

import UIKit
import SceneKit

class PlaybackViewController: UIViewController {

    var scnView: SCNView!
    var scnScene: SCNScene!
    var cameraNode: SCNNode!
    var randomNode: SCNNode?
    
    // array of String:SCNNode - String is sensorName
    var sensorNodes: [String:SCNNode] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        setupScene()
        setupCamera()
        spawnShape()  // Spawn a random shape
        addBody()

    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    // Downcast your view (UIView) to SCNView for cast reduction! :)
    func setupView() {
        scnView = self.view as! SCNView
        scnView.showsStatistics = true
        scnView.allowsCameraControl = true
        scnView.autoenablesDefaultLighting = true
    }
    
    // Create a scene! Not the drama kind...
    func setupScene() {
        scnScene = SCNScene()
        scnView.scene = scnScene
        scnView.backgroundColor = UIColor.blue
        //scnScene.background.contents = "Assets.xcassets/water-background-42.jpg"

    }
    
    func setupCamera() {
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 10)
        scnScene.rootNode.addChildNode(cameraNode)
    }
    
    func addBody(){
        var geometryNode: SCNNode
        
        // Set up geometry for sensor
        var geometry:SCNGeometry
        geometry = SCNCapsule(capRadius: 0.05, height: 0.2)
        
        // Left Leg
        geometryNode = SCNNode(geometry: geometry)
        geometryNode.position = SCNVector3(x: -0.5, y:-0.5, z:0)
        scnScene.rootNode.addChildNode(geometryNode)
        sensorNodes["LeftLeg"] = geometryNode
        Log.write("Added left leg.")
        
        // Right Leg
        geometryNode = SCNNode(geometry: geometry)
        geometryNode.position = SCNVector3(x: 0.5, y:-0.5, z:0)
        scnScene.rootNode.addChildNode(geometryNode)
        sensorNodes["RightLeg"] = geometryNode
        Log.write("Added right leg.")
        
        // Left Arm
        geometryNode = SCNNode(geometry: geometry)
        geometryNode.position = SCNVector3(x: -0.5, y:0.5, z:0)
        scnScene.rootNode.addChildNode(geometryNode)
        sensorNodes["LeftArm"] = geometryNode
        Log.write("Added left arm.")
        
        
        // Right Arm
        geometryNode = SCNNode(geometry: geometry)
        geometryNode.position = SCNVector3(x: 0.5, y:0.5, z:0)
        scnScene.rootNode.addChildNode(geometryNode)
        sensorNodes["RightArm"] = geometryNode
        Log.write("Added right arm.")
        
        // Chest
        geometryNode = SCNNode(geometry: geometry)
        geometryNode.position = SCNVector3(x: 0.0, y:0.5, z:0)
        scnScene.rootNode.addChildNode(geometryNode)
        sensorNodes["Chest"] = geometryNode
        Log.write("Added Chest.")
        
        // Head
        geometryNode = SCNNode(geometry: geometry)
        geometryNode.position = SCNVector3(x: 0.0, y:1.0, z:0)
        scnScene.rootNode.addChildNode(geometryNode)
        sensorNodes["Head"] = geometryNode
        Log.write("Added Head.")
        
    }
    
    func spawnShape() {
        var geometry:SCNGeometry
        switch ShapeType.random() {
        case ShapeType.sphere:
            geometry = SCNSphere(radius: 0.1)
        case ShapeType.capsule:
            geometry = SCNCapsule(capRadius: 0.05, height: 0.1)
        case ShapeType.cone:
            geometry = SCNCone(topRadius: 0.1, bottomRadius: 1.0, height: 0.1)
        case ShapeType.cylinder:
            geometry = SCNCylinder(radius: 0.1, height: 0.1)
        case ShapeType.pyramid:
            geometry = SCNPyramid(width: 0.1, height: 0.1, length: 0.1)
        case ShapeType.torus:
            geometry = SCNTorus(ringRadius: 0.1, pipeRadius: 0.25)
        default:
            geometry = SCNBox(width: 0.1, height: 0.1, length: 0.1,
                              chamferRadius: 0.0)
        }
        
        let geometryNode = SCNNode(geometry: geometry)
        randomNode=geometryNode
        scnScene.rootNode.addChildNode(geometryNode)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
