//
//  RuntimeContainer.swift
//  WonderlandRuntime
//
//  Created by Yu Ho Kwok on 10/30/24.
//

import UIKit
import SwiftUI
import RealityKit
import ARKit
import FocusEntity


struct RuntimeContainer : UIViewControllerRepresentable {
    
    var documentHandler : DocumentHandler
    
//    @Binding var num : Int
//    @Binding var showAnimation : Bool
//
    class Coordinator : NSObject, RuntimeViewControllerDelegate {
        func receivedEvent(num: Int) {
//            parent.showAnimation.toggle()
        }
        
        
        var parent : RuntimeContainer
        
        init(_ parent: RuntimeContainer) {
            self.parent = parent
        }
        
        
        
        func updateUserCount(count: Int) {
//            if count >= 1 {
//                parent.num = 2
//            } else {
//                parent.num = 1
//            }
        }
        
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> RuntimeViewController {
        let runtimeVC = RuntimeViewController()
        runtimeVC.delegate = context.coordinator
        runtimeVC.project = documentHandler.project
        return runtimeVC
    }
    
    func updateUIViewController(_ uiViewController: RuntimeViewController, context: Context) {
        
        
    }
    
    typealias UIViewControllerType = RuntimeViewController
    
    
    
    
}


protocol RuntimeViewControllerDelegate {
    func updateUserCount( count : Int)
    func receivedEvent( num : Int)
}


class RuntimeViewController : UIViewController, RuntimeDelegate, UIGestureRecognizerDelegate {

    
    var delegate : RuntimeViewControllerDelegate?
    var project : Project?
    
    let coachingOverlay = ARCoachingOverlayView()
    var referenceAnchor : ARPlaneAnchor?
    
    var myAnchor: ARAnchor?
    
    var arView : ARView!
    
    @IBOutlet weak var arViewContainer: UIView?
    @IBOutlet weak var debugTextView : UITextView?
    @IBOutlet weak var screenLabel: UILabel?
    @IBOutlet weak var timerLabel: UILabel?
    
    var timer: Timer?
    var scheduleTimer: Timer?
    
    var isInitialized = false
    var isBuildObject = false
    
    let fullScreenSize = UIScreen.main.bounds.size

    let configuration = ARWorldTrackingConfiguration()
    var placeObjToView: UITapGestureRecognizer?

    var focusSquare : FocusEntity?
    
    override func loadView() {
        super.loadView()
            let view : ARView
#if !targetEnvironment(simulator)
                print("Wonderland::ARViewManager::checkout::runtime")
                view = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: true)
                view.environment.background = .cameraFeed()
#else
                view = ARView(frame: .zero)
                view.environment.background = .color(.white)
#endif
        view.frame = self.view.bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view.addSubview(view)
        
        self.arView = view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Runtime.shared.link(arView: self.arView)
        Runtime.shared.isAR = true
        
        //coaching overlay
        self.setupCoachingOverlay()
        
        self.setEditorGesture()
    
        focusSquare = FocusEntity(on: self.arView, focus: .classic)
        focusSquare?.name = "focusSquare"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.resetTracking()
    }
    
    func prepareOcclusionPlane() {
        #if targetEnvironment(simulator)
        #else
        //for holding the object
        let planeMesh = MeshResource.generatePlane(width: 5, depth: 5)
        let material = OcclusionMaterial()
        let occulusionPlane = ModelEntity(mesh: planeMesh, materials: [material])
        occulusionPlane.position.y = -0.001
        
        occulusionPlane.physicsBody = PhysicsBodyComponent(massProperties: .default, material: .default, mode: .kinematic)
        occulusionPlane.generateCollisionShapes(recursive: true)
        occulusionPlane.collision?.filter = CollisionFilter(group: Runtime.CollisonGroup.planeGroup, mask: .all)
        let anchorEntity = AnchorEntity(plane: .horizontal)
        anchorEntity.addChild(occulusionPlane)
        self.arView.scene.addAnchor(anchorEntity)
        #endif
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        Runtime.shared.clearUp()
        Runtime.shared.unlink()
        timer?.invalidate()
        
        super.viewWillDisappear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    @IBAction func resetTracking() {
        #if targetEnvironment(simulator)
        arView.cameraMode = .nonAR
        #else
//        configuration.isAutoFocusEnabled = true
        arView.automaticallyConfigureSession = true
        configuration.planeDetection = [.horizontal]
        configuration.environmentTexturing = .automatic
        //arView.renderOptions.remove(.disableGroundingShadows)
        //arView.environment.sceneUnderstanding.options.insert(.receivesLighting)
        //arView.debugOptions = [.showAnchorGeometry, .showPhysics, .showWorldOrigin]
        
        if (ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth)) {
            print("support sceneDepth")
            configuration.frameSemantics.insert([.sceneDepth, .personSegmentationWithDepth])
        } else {
            print("can't support sceneDepth")
        }
        #endif
        
        print("Wonderland::RuntimeViewController::resetTracking")
        arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    

    @objc func handlePan(_ recognizer : UIPanGestureRecognizer){
        guard isInitialized else {
            return
        }
        switch recognizer.state {
        case .began:
            print("tap started")
        case .changed:
            print("tap changed")
        default:
            print("tap ended")
        }
        
    }

//    var hasPlane = false
    // MARK: - Insert block section: place block on user tapped position
    @objc func handleTap(recognizer: UITapGestureRecognizer) {
        
        guard let arView = arView else { return }
        
        print("Wonderland::RuntimeViewController::HandleTap")
        
        let screenCenter = CGPoint(x: arView.bounds.midX, y: arView.bounds.midY)
        
        if recognizer.state == .ended {
            guard let focusSquare else { return }
            if (!isInitialized || Runtime.shared.didRemove) && focusSquare.onPlane {
                
                print("Wonderland::RuntimeViewController::HandleTap::single tapped - not initialized")
                let results = arView.raycast(from: screenCenter, allowing: .existingPlaneGeometry, alignment: .horizontal)
                let query = arView.makeRaycastQuery(from: screenCenter, allowing: .existingPlaneGeometry, alignment: .horizontal)
                
                for result in results {
                    print("\(result)")
                    
                    if let planeAnchor = result.anchor as? ARPlaneAnchor {
                        let position = focusSquare.position
                        //referenceAnchor = planeAnchor
                        focusSquare.removeFromParent()
                        self.focusSquare = nil
                        
                        ObjectBlock.sharedAnchor = planeAnchor
                        ObjectBlock.worldTransform = result.worldTransform
                        ObjectBlock.query = query
                        
#if targetEnvironment(simulator)
#else
                        //for holding the object
                        let planeMesh = MeshResource.generatePlane(width: 5, depth: 5)
                        let material = OcclusionMaterial()
                        let occulusionPlane = ModelEntity(mesh: planeMesh, materials: [material])
                        occulusionPlane.position.y = -0.001
                        
                        occulusionPlane.physicsBody = PhysicsBodyComponent(massProperties: .default, material: .default, mode: .kinematic)
                        occulusionPlane.generateCollisionShapes(recursive: true)
                        occulusionPlane.collision?.filter = CollisionFilter(group: Runtime.CollisonGroup.planeGroup, mask: .all)
                        let anchorEntity = AnchorEntity(world: position)
                        
                        anchorEntity.name = "anchorEntity"
                        anchorEntity.addChild(occulusionPlane)
                        
                        self.arView.scene.addAnchor(anchorEntity)
                        
                        
#endif
                        
                        Runtime.shared.delegate = self
                        let scene = project?.getStartScene() // project.scenes[0]
                        
                        guard let scene = scene else {
                            return
                        }
                        
                        Runtime.shared.intialize(scene: scene) {
                            block in
                            
                            //add object to view / reality scene
                            if block is DebugBlock {
                                
                            }
                            
                        }
                        self.isInitialized = true
                        Runtime.shared.didRemove = false

                        return
                    }
                }
                
                return
            }
            
        }
        print("Wonderland::RuntimeViewController::HandleTap::single tapped - initialized")
        
    }
    // Raycast (2D -> 3D point)
   // let results = arView.raycast(from: tapLocation, allowing: .estimatedPlane, alignment: .horizontal)
//        // If plane detected, get 3D position (x,y,z) and place object
//        if let firstResults = results.first {
//            let worldPos = simd_make_float3(firstResults.worldTransform.columns.3)
//
//            utility.addNewBlockToObjList(newCreatedBlock!)
//            blockVisualize(worldPos)
//            // when block place in VR world, remove gesture of tap
//            arView.removeGestureRecognizer(placeObjToView!)
//            // clear new block reference
//            newCreatedBlock = nil
////            if !hasPlane {
////                let anchor = ARAnchor(name: "Anchor for object placement", transform: firstResults.worldTransform)
////                arView.session.add(anchor: anchor)
////                let arWorldAnchor = AnchorEntity(anchor: anchor)
//
////                ARPlane(arView, arWorldAnchor, worldPos)
////                hasPlane = true
////            }
//        }
    
    // MARK: - Update section: pop up blocks's properties when double tapped target
    var currSelectBlock: Block?
    @objc func handleDoubleTap(_ recognizer : UITapGestureRecognizer){
        //let tapLocation = recognizer.location(in: arView)
        print("double tap")
        Runtime.shared.DoubleTap()
//        if let entity = arView.entity(at: tapLocation) as? ModelEntity {
//            currSelectBlock = utility.findBlock(entity)
//            if currSelectBlock?.type == "input" {
//                self.performSegue(withIdentifier: "displayInputPropertyView", sender: self)
//            } else if currSelectBlock?.type == "middle" {
//                self.performSegue(withIdentifier: "displayMiddlePropertyView", sender: self)
//            } else if currSelectBlock?.type == "output" {
//                if currSelectBlock?.name != "Reduce Time" {
//                    self.performSegue(withIdentifier: "displayOutputPropertyView", sender: self)
//                }
//            } else if currSelectBlock?.type == "object" {
//                self.performSegue(withIdentifier: "displayUSDZPropertyView", sender: self)
//            }
//        }
    }
    
    // MARK: - Delete section
    @objc func handleLongPress(recongnizer: UILongPressGestureRecognizer) {
        let tapLocation = recongnizer.location(in: arView)
        
//        if let entity = arView.entity(at: tapLocation) as? ModelEntity {
//            let selectedBlock = utility.findBlock(entity)
//            if selectedBlock?.outletPort == nil && selectedBlock?.inletPort1 == nil && selectedBlock?.inletPort1 == nil {
//                createPopUpConfirmation(selectedBlock!)
//            }
//        }
    }
    
    
    

    
    // MARK: - Prepare data pass to Property View
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

    }
    
    // MARK: - detect real world plane
    func startPlaneDectection() {
        let configuration = ARWorldTrackingConfiguration()
        #if targetEnvironment(simulator)
        arView.cameraMode = .nonAR
        #else
//        configuration.isAutoFocusEnabled = true
        arView.automaticallyConfigureSession = true
        configuration.planeDetection = [.vertical]
        configuration.environmentTexturing = .automatic
        configuration.isAutoFocusEnabled = true
        //arView.renderOptions.remove(.disableGroundingShadows)
        //arView.environment.sceneUnderstanding.options.insert(.receivesLighting)
        //arView.debugOptions = [.showAnchorGeometry, .showPhysics, .showWorldOrigin]
        
        if (ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth)) {
            print("support sceneDepth")
            configuration.frameSemantics.insert([.sceneDepth, .personSegmentationWithDepth])
        } else {
            print("can't support sceneDepth")
        }
        #endif
        arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    var currentSceneIndex = 0
    func nextScene(){
        //

        
        guard let project = project else {
            return
        }
        
        self.currentSceneIndex += 1
        if currentSceneIndex >= project.scenes.count {
            currentSceneIndex = project.scenes.count - 1
        } else {
            print("load for: \(currentSceneIndex)")
            self.resetScene()
            //load scene data
            self.prepareOcclusionPlane()
            
            Runtime.shared.intialize(scene: project.scenes[currentSceneIndex]) {
                block in
                
                //add object to view / reality scene
                if block is DebugBlock {
                        
                }
            }
        }

    }
    
    func resetScene() {
        self.arView.session.run(configuration, options: [.removeExistingAnchors, .resetTracking])
    }
    
    
    func runtime(_ runtime: Runtime, debug message: Any?) {
        guard let message = message else {
            return
        }
        let text = "====== \(Date().description) ======\n\(message)\n\n\(self.debugTextView?.text!)"
        self.debugTextView?.text = text
    }
    
    func runtime(_ runtime: Runtime, label message: Any?, color: Any?) {

        guard let message = message as? String, let color = color as? String  else {
            return
        }

        screenLabel?.layer.masksToBounds = true
        screenLabel?.layer.cornerRadius = 5
        screenLabel?.backgroundColor = Runtime.shared.hexStringToUIColor(hex: color)
        screenLabel?.text = message
        screenLabel?.isHidden = false
    }
    
    func runtime(_ runtime: Runtime, timer message: Any?, color: Any?) {
        guard let timer = message as? Timer, let color = color as? String else {
            return
        }
        
        timerLabel?.layer.masksToBounds = true
        timerLabel?.layer.cornerRadius = 5
        timerLabel?.isHidden = false
        timerLabel?.backgroundColor = Runtime.shared.hexStringToUIColor(hex: color)
        self.timer = timer
    }
    
    func runtime(_ runtime : Runtime, timeParam message: Any?) {
        guard let param = message as? String else {
            return
        }
        
        timerLabel?.text = param
    }
    
    func runtime(_ runtime : Runtime, scheduleTimer message: Any?) {
        guard let scheduleTimer = message as? Timer else {
            return
        }
        
        self.scheduleTimer = scheduleTimer
    }
    
    func runtime(_ runtime: Runtime, nextScene: Any?) {
        self.nextScene()
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    
}

extension RuntimeViewController : ARCoachingOverlayViewDelegate, ARSessionDelegate  {
    
    func coachingOverlayViewWillActivate(_ coachingOverlayView: ARCoachingOverlayView) {
    }
    
    /// - Tag: PresentUI
    func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView) {
    }

    /// - Tag: StartOver
    func coachingOverlayViewDidRequestSessionReset(_ coachingOverlayView: ARCoachingOverlayView) {
        resetTracking()
    }
    
    func setupCoachingOverlay() {
        // Set up coaching view
        coachingOverlay.session = arView.session
        coachingOverlay.delegate = self
        
        coachingOverlay.translatesAutoresizingMaskIntoConstraints = false
        arView.addSubview(coachingOverlay)
        
        NSLayoutConstraint.activate([
            coachingOverlay.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            coachingOverlay.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            coachingOverlay.widthAnchor.constraint(equalTo: view.widthAnchor),
            coachingOverlay.heightAnchor.constraint(equalTo: view.heightAnchor)
            ])
        
        setActivatesAutomatically()
        
        // Most of the virtual objects in this sample require a horizontal surface,
        // therefore coach the user to find a horizontal plane.
        setGoal()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [self] in
            coachingOverlay.setActive(true, animated: true)
        }
    }
    
    /// - Tag: CoachingActivatesAutomatically
    func setActivatesAutomatically() {
        coachingOverlay.activatesAutomatically = true
    }

    /// - Tag: CoachingGoal
    func setGoal() {
        coachingOverlay.goal = .horizontalPlane
    }
    
    func clearup() {
        focusSquare?.removeFromParent()
        
        coachingOverlay.delegate = nil
        coachingOverlay.session = nil
        coachingOverlay.activatesAutomatically = false
        coachingOverlay.removeFromSuperview()
        
        for gesture in arView.gestureRecognizers ?? [] {
            arView.removeGestureRecognizer(gesture)
        }
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        print("Runtime::tracking state: \(camera.trackingState)")
        
    }
    
    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        Runtime.shared.didRemove = true
//        for anchor in anchors {
//
//            print(anchor.name)
//        }
        
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        //print("Runtime::did update ar frame")
    }
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            if anchor is ARPlaneAnchor {
                Runtime.shared.hasARPlane = true
            }
        }
    }
}

extension RuntimeViewController {
    
    func setEditorGesture(){
        //single tap gesture
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:)))
        singleTap.numberOfTapsRequired = 1
        singleTap.numberOfTouchesRequired = 1
        singleTap.delegate = self
        arView.addGestureRecognizer(singleTap)
        
        // double gesture for set block's properties
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.numberOfTouchesRequired = 1
        doubleTap.delegate = self
        arView.addGestureRecognizer(doubleTap)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.delegate = self
        arView.addGestureRecognizer(panGesture)
        
        // long press gesture for delect block
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(recongnizer:)))
        arView.addGestureRecognizer(longPress)
        //arView.debugOptions = [.showPhysics]
        
    }
      
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isInitialized else {
            return
        }
        print("touchesBegan")
        Runtime.shared.touchDown()
        if let touch = touches.first {
//            let location = touch.location(in: arView)
//            Runtime.shared.touch(at: location)
            Runtime.shared.touch(at: touch)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isInitialized else {
            return
        }
        print("touchesMove")
        if let touch = touches.first {
//            let location = touch.location(in: arView)
//            Runtime.shared.touch(at: location)
//            Runtime.shared.touch(at: touch)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        guard isInitialized else {
            return
        }
        print("ended")
        Runtime.shared.touchUp()
        if let touch = touches.first {
//            let location = touch.location(in: arView)
//            Runtime.shared.touch(at: location)
//            Runtime.shared.touch(at: touch)
        }
    }
    
    
}
