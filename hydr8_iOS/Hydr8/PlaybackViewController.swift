//
//  GameViewController.swift
//  GeometryFighter
//
//  Created by Alan Kanczes on 6/10/18.
//  Copyright © 2018 Alan Kanczes. All rights reserved.
//

import UIKit
import SceneKit


enum SensorPosition {
    case leftHand
    case leftForeArm
    case leftBicep
    case leftShoulder
    case leftHip
    case leftThigh
    case leftCalf
    case leftFoot
    
    case head
    case neck
    case back
    case chest
    
    case rightHand
    case rightForeArm
    case rightBicep
    case rightShoulder
    case rightHip
    case rightThigh
    case rightCalf
    case rightFoot
}

struct SensorLogNode {
    let scnNode: SCNNode
    var sensorLog: SensorLog?
}

class PlaybackViewController: UIViewController {

    var scnView: SCNView!
    var scnScene: SCNScene!
    var cameraNode: SCNNode!
    var randomNode: SCNNode?
    var spawnTime: TimeInterval = 0
    var spawnedNode: SCNNode?

    var currentIndex = 0
    
    // array of String:SCNNode - String is sensorName
    var sensorLogNodes: [SensorPosition:SensorLogNode] = [:]

    var session: Session?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        setupScene()
        setupCamera()
        
        // Add nodes to create body
        addBody()
        // spawnShape()

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
        
        scnView.delegate = self // Set up self as renderer
        scnView.isPlaying = true // Start the render loop!

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
    
    
    func moveNodes() {

        for (sensorPosition, sensorLogNode) in sensorLogNodes {
            guard let sensorLog =  sensorLogNode.sensorLog else {
                Log.write("Skipping sensorPosition: \(sensorPosition) - no sensorLog present.", .detail)
                continue
            }
            Log.write("Moving sensorPosition: \(sensorPosition) for index: \(currentIndex) ", .detail)
            guard let sensorMovementRecord = sensorLog.getMovementRecord(atIndex: currentIndex) else {
                Log.write("No movement record for sensorPosition: \(sensorPosition) for index: \(currentIndex) ", .detail)
                continue
            }
            Log.write("Changing sensorPosition: \(sensorPosition) for index: \(currentIndex) - x: \(String(describing: sensorMovementRecord.accelerometerValue.x)), y: \(sensorMovementRecord.accelerometerValue.y), z: \(sensorMovementRecord.accelerometerValue.z) ", .info)

            
            let force = SCNVector3(x: Float((sensorMovementRecord.accelerometerValue.x)), y: Float((sensorMovementRecord.accelerometerValue.y)), z: Float((sensorMovementRecord.accelerometerValue.z)))
            //let sensorPosition = SCNVector3(x: 0.05, y: 0.05, z: 0.05)
            //sensorLogNode.scnNode.physicsBody?.applyForce(force, at: position, asImpulse: true)
            //sensorLogNode.scnNode.physicsBody?.applyForce(force, asImpulse: true)
            
            let oldPosition = sensorLogNode.scnNode.position
            let newPosition = SCNVector3(x: oldPosition.x + force.x, y: oldPosition.y + force.y, z: oldPosition.z + force.z)

            /* let newPosition = SCNVector3(x: Float((sensorMovementRecord.accelerometerValue.x)), y: Float((sensorMovementRecord.accelerometerValue.y)), z: Float((sensorMovementRecord.accelerometerValue.z))) */
            
            sensorLogNode.scnNode.position = newPosition
        }

        currentIndex = currentIndex + 1

    }
    
    func addBody(){
        var geometryNode: SCNNode
        
        // Set up geometry for sensor
        var geometry:SCNGeometry
        geometry = SCNCapsule(capRadius: 0.05, height: 0.2)
        
        // Left Leg
        geometryNode = SCNNode(geometry: geometry)
        geometryNode.position = SCNVector3(x: -0.5, y:-0.5, z:0)
        geometryNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        scnScene.rootNode.addChildNode(geometryNode)
        sensorLogNodes[.leftFoot] = SensorLogNode(scnNode: geometryNode, sensorLog: session?.getSensorLog(row: 0))
        Log.write("Added \(SensorPosition.leftFoot)")
        
        // Right Leg
        geometryNode = SCNNode(geometry: geometry)
        geometryNode.position = SCNVector3(x: 0.5, y:-0.5, z:0)
        geometryNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        scnScene.rootNode.addChildNode(geometryNode)
        sensorLogNodes[.rightFoot] = SensorLogNode(scnNode: geometryNode, sensorLog: session?.getSensorLog(row: 1))
        Log.write("Added \(SensorPosition.rightFoot)")

        // Left Arm
        geometryNode = SCNNode(geometry: geometry)
        geometryNode.position = SCNVector3(x: -0.5, y:0.5, z:0)
        geometryNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        scnScene.rootNode.addChildNode(geometryNode)
        sensorLogNodes[.leftHand] = SensorLogNode(scnNode: geometryNode, sensorLog: nil)
        Log.write("Added \(SensorPosition.leftHand)")

        
        // Right Arm
        geometryNode = SCNNode(geometry: geometry)
        geometryNode.position = SCNVector3(x: 0.5, y:0.5, z:0)
        geometryNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        scnScene.rootNode.addChildNode(geometryNode)
        sensorLogNodes[.rightHand] = SensorLogNode(scnNode: geometryNode, sensorLog: nil)
        Log.write("Added \(SensorPosition.rightHand)")

        // Chest
        geometryNode = SCNNode(geometry: geometry)
        geometryNode.position = SCNVector3(x: 0.0, y:0.5, z:0)
        geometryNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        scnScene.rootNode.addChildNode(geometryNode)
        sensorLogNodes[.chest] = SensorLogNode(scnNode: geometryNode, sensorLog: nil)
        Log.write("Added \(SensorPosition.chest)")

        // Head
        geometryNode = SCNNode(geometry: geometry)
        geometryNode.position = SCNVector3(x: 0.0, y:1.0, z:0)
        geometryNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        scnScene.rootNode.addChildNode(geometryNode)
        sensorLogNodes[.head] = SensorLogNode(scnNode: geometryNode, sensorLog: nil)
        Log.write("Added \(SensorPosition.head)")

    }
    
    func spawnShape() -> SCNNode {
        var geometry:SCNGeometry
        switch ShapeType.random() {
        case ShapeType.sphere:
            geometry = SCNSphere(radius: 0.1)
        case ShapeType.capsule:
            geometry = SCNCapsule(capRadius: 0.05, height: 0.1)
        case ShapeType.cone:
            geometry = SCNCone(topRadius: 0.1, bottomRadius: 0.5, height: 0.3)
        case ShapeType.cylinder:
            geometry = SCNCylinder(radius: 0.1, height: 0.3)
        case ShapeType.pyramid:
            geometry = SCNPyramid(width: 0.1, height: 0.3, length: 0.1)
        case ShapeType.torus:
            geometry = SCNTorus(ringRadius: 0.2, pipeRadius: 0.1)
        default:
            geometry = SCNBox(width: 0.1, height: 0.3, length: 0.3,
                              chamferRadius: 0.0)
        }
        
        let geometryNode = SCNNode(geometry: geometry)
        randomNode=geometryNode
        scnScene.rootNode.addChildNode(geometryNode)
        
        return geometryNode
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }

}

// Add rendering delegate for
extension PlaybackViewController: SCNSceneRendererDelegate {
    func renderer(_ renderer: SCNSceneRenderer,
                  updateAtTime time: TimeInterval) {
        moveNodes()

        // Test to make shape is spawning, loop is moving.
        if time > spawnTime {
            Log.write("Spawning shape...", .detail)
            
            spawnedNode?.removeFromParentNode()
            spawnedNode = spawnShape()
            spawnTime = time + TimeInterval(1) // (Float.random(lower: 0.2, 1.5))
        }

        
    }
}


public extension Float {
    /// SwiftRandom extension
    public static func random(lower: Float = 0, _ upper: Float = 100) -> Float {
        return (Float(arc4random()) / 0xFFFFFFFF) * (upper - lower) + lower
    }
}
