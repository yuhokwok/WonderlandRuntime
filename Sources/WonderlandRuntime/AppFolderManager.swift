//
//  CaptureFolderManager.swift
//  FBPLand
//
//  Created by Reality Builder Team on 27/4/2022.
//

import Foundation
import UIKit

class AppFolderManager {
    static private let workQueue = DispatchQueue(label: "CaptureFolderManager.Work", qos: .userInitiated)
    
    var captureDir: URL? = nil
    init(url captureDir: URL) {
        self.captureDir = captureDir
    }
    
    static func deleteFolder(url : URL) -> Bool {
        do {
            try FileManager.default.removeItem(at: url)
            return true
        } catch {
            print(error.localizedDescription)
            return false
        }
    }
    
    static func requestProjectList(completion : @escaping @Sendable  ([URL])->Void){
        workQueue.async {
            guard let docFolder = AppFolderManager.documentFolder() else {
                completion([])
                return
            }
            

            guard let folderListing =
                    try? FileManager.default.contentsOfDirectory(at: docFolder,
                                     includingPropertiesForKeys: [.contentModificationDateKey],
                                     options: [ .skipsHiddenFiles ]) else {
                completion([])
                return
            }
            
            // Sort by creation date, newest first.
            let sortedFolderListing = folderListing
                .sorted { lhs, rhs in
                    modifyDate(for: lhs) > modifyDate(for: rhs)
                }
                .filter {
                    url in
                    return url.pathExtension == "wonderlandproj"
                }
            completion(sortedFolderListing)
        }
    }
    
    static func getUSDZURL(objectType : String, fileName : String) -> URL? {
        guard let documentsFolder =
                try? FileManager.default.url(for: .documentDirectory,
                                             in: .userDomainMask,
                                             appropriateFor: nil, create: false) else {
            return nil
        }
        return documentsFolder.appendingPathComponent("\(objectType)/\(fileName)", isDirectory: false)
    }
    
    static func requestVoxelListing(completion : @escaping @Sendable ([URL])->Void){
        workQueue.async {
            guard let docFolder = AppFolderManager.voxelFolder() else {
                completion([])
                return
            }
            

            guard let folderListing =
                    try? FileManager.default.contentsOfDirectory(at: docFolder,
                                     includingPropertiesForKeys: [.creationDateKey],
                                     options: [ .skipsHiddenFiles ]) else {
                completion([])
                return
            }
            
            // Sort by creation date, newest first.
            let sortedFolderListing = folderListing
                .sorted { lhs, rhs in
                    creationDate(for: lhs) > creationDate(for: rhs)
                }
            completion(sortedFolderListing)
        }
        
    }
    
    static func requestFirstImage(for url : URL) -> UIImage? {
        guard let folderListing = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: [.creationDateKey],
                                                                               options: [.skipsHiddenFiles]) else {
            return nil
        }
        let sortedFolderListing = folderListing
            .sorted { lhs, rhs in
                creationDate(for: lhs) > creationDate(for: rhs)
            }.filter {
                url in
                return  url.absoluteString.lowercased().hasSuffix("jpg") ||
                        url.absoluteString.lowercased().hasSuffix("heic") ||
                        url.absoluteString.lowercased().hasSuffix("png")
            }
        
        if sortedFolderListing.count == 0 {
            return nil
        }
        
        if let data = try? Data(contentsOf: sortedFolderListing[0]) {
            return UIImage(data: data)
        }
        return nil
    }
    
    static func requestUSDZListing(completion : @escaping @Sendable ([URL])->Void){
        workQueue.async {
            guard let docFolder = AppFolderManager.usdzsFolder() else {
                completion([])
                return
            }
            

            guard let folderListing =
                    try? FileManager.default.contentsOfDirectory(at: docFolder,
                                     includingPropertiesForKeys: [.creationDateKey],
                                     options: [ .skipsHiddenFiles ]) else {
                completion([])
                return
            }
            
            
            
            //print("folderListing: \(folderListing)")
            
            let fullPaths = folderListing.map({
                url in
                var theUrl = url
                return theUrl.appending(path: "Models/model-mobile.usdz")
            })
            

            // Sort by creation date, newest first.
            let sortedFolderListing = fullPaths
                .sorted { lhs, rhs in
                    creationDate(for: lhs) > creationDate(for: rhs)
                }.filter {
                    url in
                    print("\(url.absoluteString)")
                    let path = url.absoluteString
                    return FileManager.default.fileExists(atPath: path.replacingOccurrences(of: "file:///", with: "/"))
                    //return url.absoluteString.hasSuffix("usdz")
                }
            completion(sortedFolderListing)
        }
        
    }
    
    static func requestCaptureFolderListing(completion : @escaping @Sendable ([URL])->Void){
        workQueue.async {
            guard let docFolder = AppFolderManager.capturesFolder() else {
                completion([])
                return
            }
            
            guard let folderListing =
                    try? FileManager.default
                .contentsOfDirectory(at: docFolder,
                                     includingPropertiesForKeys: [.creationDateKey],
                                     options: [ .skipsHiddenFiles ]) else {
                completion([])
                return
            }
            
            // Sort by creation date, newest first.
            let sortedFolderListing = folderListing
                .sorted { lhs, rhs in
                    creationDate(for: lhs) > creationDate(for: rhs)
                }
            completion(sortedFolderListing)
        }
        
    }
    

    /// The method returns a URL to the app's documents folder, where it stores all captures.
    static func documentFolder() -> URL? {
        guard let documentsFolder =
                try? FileManager.default.url(for: .documentDirectory,
                                             in: .userDomainMask,
                                             appropriateFor: nil, create: false) else {
            return nil
        }
        return documentsFolder
    }
    
    /// The method returns a URL to the app's documents folder, where it stores all captures.
    static func voxelFolder() -> URL? {
        guard let documentsFolder =
                try? FileManager.default.url(for: .documentDirectory,
                                             in: .userDomainMask,
                                             appropriateFor: nil, create: false) else {
            return nil
        }
        return documentsFolder.appendingPathComponent("voxel/", isDirectory: true)
    }
    
    /// The method returns a URL to the app's documents folder, where it stores all captures.
    static func usdzsFolder() -> URL? {
        guard let documentsFolder =
                try? FileManager.default.url(for: .documentDirectory,
                                             in: .userDomainMask,
                                             appropriateFor: nil, create: false) else {
            return nil
        }
        return documentsFolder.appendingPathComponent("Scans/", isDirectory: true)
    }
    
    
    /// The method returns a URL to the app's documents folder, where it stores all captures.
    static func capturesFolder() -> URL? {
        guard let documentsFolder =
                try? FileManager.default.url(for: .documentDirectory,
                                             in: .userDomainMask,
                                             appropriateFor: nil, create: false) else {
            return nil
        }
        return documentsFolder.appendingPathComponent("Captures/", isDirectory: true)
    }

    private static func modifyDate(for url: URL) -> Date {
        let date = try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
        
        if date == nil {
            print("creation data is nil for: \(url.path).")
            return Date.distantPast
        } else {
            return date!
        }
    }
    
    
    private static func creationDate(for url: URL) -> Date {
        let date = try? url.resourceValues(forKeys: [.creationDateKey]).creationDate
        
        if date == nil {
            print("creation data is nil for: \(url.path).")
            return Date.distantPast
        } else {
            return date!
        }
    }
    

}
