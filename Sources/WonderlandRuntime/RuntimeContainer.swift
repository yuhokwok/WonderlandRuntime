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
//        let storyboard = UIStoryboard(name: "Runtime", bundle: nil)
//
//        let vc = storyboard.instantiateViewController(withIdentifier: "Runtime")
//
//        guard let runtimeVC = vc as? RuntimeViewController else {
//            fatalError()
//        }
        
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


class RuntimeViewController : UIViewController {
    var delegate : RuntimeViewControllerDelegate?
    var project : Project?
    
    
    
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
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

