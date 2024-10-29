// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import SwiftUI
import RealityKit
import ARKit
import UIKit

@MainActor
public struct WonderlandRuntimeView : View {
    
    var url : URL?
    
    public init(name : String) {
        url = Bundle.main.url(forResource: name, withExtension: "wonderlandproj")
    }
    
    public var body : some View {
        VStack  {
            if let url = url {
                Text("Hello Wonderland")
            } else {
                Text("No Wonderland Loaded")
            }
        }
    }
}

protocol RuntimeViewControllerDelegate {
    func updateUserCount( count : Int)
    func receivedEvent( num : Int)
}


class RuntimeViewController : UIViewController {
    var delegate : RuntimeViewControllerDelegate?
    var project : Project?
}


struct RuntimeContainer : UIViewControllerRepresentable {
    
    var documentHandler : DocumentHandler
    
    @Binding var num : Int
    @Binding var showAnimation : Bool
    
    class Coordinator : NSObject, @preconcurrency RuntimeViewControllerDelegate {
        @MainActor func receivedEvent(num: Int) {
            parent.showAnimation.toggle()
        }
        
        
        var parent : RuntimeContainer
        
        init(_ parent: RuntimeContainer) {
            self.parent = parent
        }
        

        
        @MainActor func updateUserCount(count: Int) {
            if count >= 1 {
                parent.num = 2
            } else {
                parent.num = 1
            }
        }
        
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> RuntimeViewController {
        let storyboard = UIStoryboard(name: "Runtime", bundle: nil)
        
        let vc = storyboard.instantiateViewController(withIdentifier: "Runtime")
        
        guard let runtimeVC = vc as? RuntimeViewController else {
            fatalError()
        }
        
        runtimeVC.delegate = context.coordinator
        runtimeVC.project = documentHandler.project
        
        return runtimeVC
    }
    
    func updateUIViewController(_ uiViewController: RuntimeViewController, context: Context) {
        
        
    }
    
    typealias UIViewControllerType = RuntimeViewController
    
    
    
    
}
