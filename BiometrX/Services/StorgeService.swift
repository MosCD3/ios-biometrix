//
//  StorageService.swift
//  patient
//
//  Created by Mostafa Youssef on 10/11/19.
//  Copyright © 2019 Phzio. All rights reserved.
//

import Foundation
class StorgeService {
    
    var defaults = UserDefaults.standard
    static let key_outbound = "outbount_"
    static let key_api = "api_"
    let maxKeyValue_Size = 50000 //in bytes
    let maxDefaults_Size = 1000000 //in bytes
    static let maxFullLog_Size = 1000000
    static let maxCompLog_Size = 1000000
    static let maxLogItem_Size = 50000
    
    func saveData(key: String, object: Any?) {
       
        print("Called to save data for key:\(key)")
        //checking size of defaults object
        let defaultsSize = StorgeService.getSizeOfUserDefaults()
        if defaultsSize ?? 0 > maxDefaults_Size {
            print("Defaults object size too high: \(defaultsSize ?? 0), wiping out API cache")
            clearApiCached()
        }
        
        if let object_str = object as? String {
            let _size = object_str.count
            print("Size of saved string for key:\(key)  is:\(_size)")
            
            //TODO: if too large, save in app lifecycle
            if _size > maxKeyValue_Size {
                print("Size of string for key:\(key) is:\(_size), this is too large for storing, (max:\(maxKeyValue_Size))")
                return
            }
        }
        
        defaults.set( object, forKey: key)
    }
    
    func clearData(key: String) {
        defaults.removeObject(forKey: key)
    }
    func getString(key: String) -> String? {
        var returned: String?
        guard
            let value = defaults.string(forKey: key)
            else { return returned }
        
        returned = value
        return returned
    }
    
    func getBool(key: String) -> Bool? {
        if let _ = defaults.value(forKey: key) {
            return defaults.bool(forKey: key)
        }
        return nil
    }
    
    func getInt(key: String) -> Int? {
        if let _ = defaults.value(forKey: key) {
            return defaults.integer(forKey: key)
        }
        return nil
    }
    
    
    func loopDefaults() {
        for (key, value) in UserDefaults.standard.dictionaryRepresentation() {
            print("\(key) = \(value) \n")
        }
    }
    
    func getListOutbounds() -> [String] {
        
        var returned = [String]()
        for (key, value) in UserDefaults.standard.dictionaryRepresentation() {
            
            if key.contains(StorgeService.key_outbound) {
                returned.append(value as? String ?? "")
            }
        }
        
        return returned
    }
    
    
    //MARK: Stored data check
    //Return size in Bytes
    static func getSizeOfUserDefaults() -> Int? {
        guard let libraryDir = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.libraryDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).first else {
            return nil
        }
        
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
            return nil
        }
        
        let filepath = "\(libraryDir)/Preferences/\(bundleIdentifier).plist"
        let filesize = try? FileManager.default.attributesOfItem(atPath: filepath)
        let retVal = filesize?[FileAttributeKey.size]
        return retVal as? Int
    }
    
    static func getSizeOfStoredMedia() -> Double {
        print("Checking file size")
        return clearStoredMedia(onlySize: true)
    }
    
    

    
    static func clearStoredMedia(onlySize: Bool = false) -> Double {
        let fileManager = FileManager.default
        var totalSize: Double = 0.0
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            
            // if you want to filter the directory contents you can do like this:
            //    let mp3Files = fileURLs.filter{ $0.pathExtension == "mp3" }
            //    print("mp3 urls:",mp3Files)
            //    let mp3FileNames = mp3Files.map{ $0.deletingPathExtension().lastPathComponent }
            //    print("mp3 list:", mp3FileNames)
            
            // process files
            for file_url in fileURLs {
                print("stored file url:\(file_url)")
                let size = fileSizeGet(forURL: file_url)
                print(" >size is:", size)
                totalSize += size
                if !onlySize {
                    let fileName = file_url.lastPathComponent
                    _ = checkFileExists(fileName: fileName, isDelete: true)
                }
                
            }
        } catch {
            print("Error while enumerating files \(documentsURL.path): \(error.localizedDescription)")
        }
        
        return totalSize
    }
    
    func clearApiCached() {
        print("\nCached strings before clearing ==>")
        loopDefaults()
        for (key, _) in UserDefaults.standard.dictionaryRepresentation() {
            if key.contains(StorgeService.key_api) {
                clearData(key: key)
            }
        }
        loopDefaults()
    }
    
    static func fileSizeGet(forURL url: Any) -> Double {
        var fileURL: URL?
        var fileSize: Double = 0.0
        if (url is URL) || (url is String)
        {
            if (url is URL) {
                fileURL = url as? URL
            }
            else {
                fileURL = URL(fileURLWithPath: url as! String)
            }
            var fileSizeValue = 0.0
            try? fileSizeValue = (fileURL?.resourceValues(forKeys: [URLResourceKey.fileSizeKey]).allValues.first?.value as! Double?)!
            if fileSizeValue > 0.0 {
                fileSize = (Double(fileSizeValue) / (1024))
            }
        }
        
        //In Kb
        return fileSize
    }
    
    
    
    
    
    static func checkFileExists(fileName: String, isDelete: Bool = false) -> (Bool, String?) {
        
        print("Checking file named: \(fileName)")
        
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let url = NSURL(fileURLWithPath: path)
        if let pathComponent = url.appendingPathComponent(fileName) {
            let filePath = pathComponent.path
            let fileManager = FileManager.default
            
            var filePath_abs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            filePath_abs.appendPathComponent(fileName)
            
           
            if fileManager.fileExists(atPath: filePath) {
                print("File Available")
                print("full path for fle: \(filePath_abs.absoluteString)")
                
                if isDelete {
                    deleteFile(filePath: filePath)
                }
                
                return (true, filePath_abs.absoluteString)
                
            } else {
                print("File not available in local storage!")
            }
        } else {
            print( "File directory unavalable!")
        }
        
        return (false, nil)
    }
    
    
    static func deleteFile (filePath: String) {
        do {
            try FileManager.default.removeItem(atPath: filePath)
        } catch {
            print("Error deleting file:", error.localizedDescription)
        }
        
    }
    
    //MARK: Singleton
    static let shared: StorgeService = StorgeService()
}
