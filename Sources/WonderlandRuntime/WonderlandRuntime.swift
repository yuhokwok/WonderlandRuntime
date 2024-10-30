// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import SwiftUI
import UIKit

@MainActor
public struct WonderlandRuntimeView : View {
    
    
    @State var isReady : Bool = false
    
    var name : String
    var archiveURL : URL?
    var unarchiveURL : URL?
    @State var documentHandler : DocumentHandler? = nil
    
    public init(name : String) {
        self.name = name
        archiveURL = Bundle.main.url(forResource: name, withExtension: "wonderlandz")
        unarchiveURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    }
    
    public var body : some View {
        VStack  {
            if let documentHandler = self.documentHandler {
                RuntimeContainer(documentHandler: documentHandler)
                    .ignoresSafeArea()
            } else {
                VStack {
                    Text("Preparing your Wonderland...")
                    ProgressView().progressViewStyle(.circular)
                }
            }
        }
        .onAppear {
            if let url = archiveURL, let durl = unarchiveURL, let projurl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appending(path: "\(name).wonderlandproj") {
                ArchiveManager.unzipFile(at: url, to: durl)
                let document = WonderlandProject(fileURL: projurl)
                document.open(completionHandler: {
                    self.documentHandler = DocumentHandler(document: document)
                    isReady = $0
                })
            }
        }
    }
}


