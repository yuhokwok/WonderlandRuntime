//
//  RealityBuilderProject.swift
//  Reality Builder
//
//  Created by Reality Builder Team on 25/5/2022.
//

import UIKit

class WonderlandProject : UIDocument {
    var encoder = JSONEncoder()
    var decoder = JSONDecoder()
    
    var fileWrapper = FileWrapper(directoryWithFileWrappers:[:])
    
    var project : Project?
    var editorInfo : ProjectEditorInfo?
    
    override init(fileURL url: URL) {
        print("\(#function)")
        print("\(url.absoluteString)")
        super.init(fileURL: url)
    }
    
    //MARK: - function required by UIDocument for load and save
    //this function will be invoked if you call "save" function
    var testObject : TestJSONObject?
    override func contents(forType typeName: String) throws -> Any {
        print("\(#function)")
        
        //load information here, if no, create new information
        print("type:\(typeName)")
        let testObjectWrapper = encodeToWrapper(object: testObject!)
        let wrappers : [String : FileWrapper] = ["testObject.data" : testObjectWrapper!]
        
        return FileWrapper(directoryWithFileWrappers: wrappers)
    }
    
    
    
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        
        print("\(#function)")
        if let fileWrapper = contents as? FileWrapper {
            print("file wrapper: \(fileWrapper)")
            self.fileWrapper = fileWrapper
            if let item = fileWrapper.fileWrappers?["contents.plist"] {
                if let fileContents = item.regularFileContents {
                    if let dictionary = try? PropertyListSerialization.propertyList(from: fileContents, options: [], format: nil) as? NSDictionary {
                        print(dictionary)
                    }
                }
            }
            
            //load keynote
            self.project = self.load()
            print("WonderlandProject::project loaded")
            self.editorInfo = self.loadProjectEditorInfo()
            print("WonderlandProject::project editor info loaded")
        }
        
    }
    
    override var savingFileType: String? {
        return "com.arthaslan.wonderland.wonderlandproj"
    }
    
    override func close(completionHandler: ((Bool) -> Void)? = nil) {
        self.save()
        print("WonderlandProject::project saved")
        self.saveProjectEditorInfo()
        print("WonderlandProject::project editor info saved")
        super.close(completionHandler: completionHandler)
    }
    
    func save() {
        self.saveProject()
        if let project = project {
            editorInfo?.verify(project, clearMissing: true)
        }
        self.saveProjectEditorInfo()
    }
    
    func saveProject() {
        guard let data = try? encoder.encode(self.project) else {
            fatalError("can't save keynote")
        }
        
        let url = self.fileURL
        let fileURL = url.appendingPathComponent("project.wonderlandprojcode")
        
        do {
            print("save at :\(url.absoluteString)")
            try data.write(to: fileURL, options: .atomic)
        } catch _ {
            fatalError("can't save keynote")
        }
    }
    
    func saveProjectEditorInfo() {
        guard let data = try? encoder.encode(self.editorInfo) else {
            fatalError("can't save editor info")
        }
        
        let url = self.fileURL
        let fileURL = url.appendingPathComponent("project.projecteditorinfo")
        
        do {
            print("save at :\(url.absoluteString)")
            try data.write(to: fileURL, options: .atomic)
        } catch _ {
            fatalError("can't save keynote")
        }
    }
    
    func saveUSDZ(usdzURL : URL) -> URL?{
        let url = self.fileURL
        let destinationUrl = url.appendingPathComponent(usdzURL.lastPathComponent)
        do {
            // Remove the file at destination if it already exists
            if FileManager.default.fileExists(atPath: destinationUrl.path) {
                try FileManager.default.removeItem(at: destinationUrl)
            }
            // Copy the file to the Documents directory
            try FileManager.default.copyItem(at: usdzURL, to: destinationUrl)
            return destinationUrl
        } catch {
            print("Error copying USDZ file: \(error)")
            return nil
        }
    }
    
    func saveThumbnail(image : UIImage?, for identifier : String, type : ImageCache.ThumbnailType) -> URL? {
        guard let image = image else {
            return nil
        }
        let url = self.fileURL
        let fileURL = url.appendingPathComponent("thumbnail\(type == .startup ? "-startup" : "")-\(identifier).png")
        guard let data = image.pngData() else {
            return nil
        }
        
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            return nil
        }
    }
    
    func thumbnail(for identifier : String, type : ImageCache.ThumbnailType) -> UIImage? {
        let url = self.fileURL
        let fileURL = url.appendingPathComponent("thumbnail\(type == .startup ? "-startup" : "")-\(identifier).png")
        guard let data = try? Data(contentsOf: fileURL) else {
            return nil
        }
        
        return UIImage(data: data)
    }
    
    func saveThumbnail(image : UIImage?) {
        guard let image = image else {
            return
        }
        let url = self.fileURL
        let fileURL = url.appendingPathComponent("thumbnail.png")
        guard let data = image.pngData() else {
            return
        }
        try? data.write(to: fileURL)
    }
    

    
    func load() -> Project {
        let project : Project
        let url = self.fileURL
        let fileURL = url.appendingPathComponent("project.wonderlandprojcode")
        guard let data = try? Data(contentsOf: fileURL) else {
            project = self.new()
            return project
        }
        guard let pj = try? decoder.decode(Project.self, from: data) else {
            project = self.new()
            return project
        }
        project = pj
        return project
    }
    
    func loadProjectEditorInfo() -> ProjectEditorInfo {
        guard let project = project else { return ProjectEditorInfo.new() }
        
        var editorInfo : ProjectEditorInfo
        let url = self.fileURL
        let fileURL = url.appendingPathComponent("project.projecteditorinfo")
        guard let data = try? Data(contentsOf: fileURL) else {
            editorInfo = ProjectEditorInfo.new(project)
            return editorInfo
        }
        guard let ei = try? decoder.decode(ProjectEditorInfo.self, from: data) else {
            editorInfo = ProjectEditorInfo.new(project)
            return editorInfo
        }
        editorInfo = ei
        editorInfo.verify(project)
        return editorInfo
    }
    
    func new() -> Project {
        let project = Project.new()
        return project
    }
    
    
    
    func encodeToWrapper<T: Encodable>(object : T) -> FileWrapper? {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(object) else {
            return nil
        }
        return FileWrapper(regularFileWithContents: data)
    }
    
    //MARK: - Error handling
    override func handleError(_ error: Error, userInteractionPermitted: Bool) {
        print("\(#function)")
        print(error)
        super.handleError(error, userInteractionPermitted: userInteractionPermitted)
    }
    
    override func finishedHandlingError(_ error: Error, recovered: Bool) {
        print("\(#function)")
        print(error)
        super.finishedHandlingError(error, recovered: recovered)
    }
    
    override func userInteractionNoLongerPermitted(forError error: Error) {
        print("\(#function)")
        print(error)
        super.userInteractionNoLongerPermitted(forError: error)
    }
    
    var projectName : String {
        return self.fileURL.lastPathComponent.replacingOccurrences(of: ".wonderlandproj", with: "")
    }
}
