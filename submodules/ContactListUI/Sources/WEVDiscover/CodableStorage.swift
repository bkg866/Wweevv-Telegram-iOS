//
//  CodableStorage.swift
//  _idx_ContactListUI_287961B2_ios_min13.0
//

import UIKit
import RESegmentedControl

struct DiscoverRootItems {
    static public func defaultOptions() -> [SegmentModel] {
        return [
            SegmentModel(title: "Youtube", imageName: "segment_youtube", searchStatus: DiscoverSearchStatus.youtube.rawValue),
            SegmentModel(title: "Twitch", imageName: "segemnt_twitch", searchStatus: DiscoverSearchStatus.twitch.rawValue),
            SegmentModel(title: "Rumble", imageName: "segment-rumble", searchStatus: DiscoverSearchStatus.rumble.rawValue),
            SegmentModel(title: "Tiktok", imageName: "segment-tiktok", searchStatus: DiscoverSearchStatus.tiktok.rawValue)
        ]
    }
    
    static public func readOptions() -> [SegmentModel] {
        //If you need to add new option on segment then first clear old store datas
        
        if let options = CodableStorage(forFileName: .segmentModel).retrieve(as: [SegmentModel].self) {
            if options.count == defaultOptions().count {
                return options
            } else {
                return defaultOptions()
            }
        } else {
            return defaultOptions()
        }
    }
    
    static public func save(options: [SegmentModel]) {
        CodableStorage(forFileName: .segmentModel).store(options)
    }
}

public class CodableStorage: NSObject {
    fileprivate var fileName: FileName = .segmentModel
    
    fileprivate var fileUrl: URL {
        let searchPathDirectory: FileManager.SearchPathDirectory = .cachesDirectory
        if let url = FileManager.default.urls(for: searchPathDirectory, in: .userDomainMask).first {
            return url
        } else {
            fatalError("Could not create URL for specified directory!")
        }
    }
    
    enum FileName: String {
        case segmentModel = "segmentModel.json"
    }
    
    init(forFileName fileName: FileName){
        self.fileName = fileName
        
        super.init()
    }
    
    func store<T: Encodable>(_ object: T) {
        let url = fileUrl.appendingPathComponent(fileName.rawValue, isDirectory: false)
        
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(object)
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }
            FileManager.default.createFile(atPath: url.path, contents: data, attributes: nil)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    func retrieve<T: Decodable>(as type: T.Type) -> T? {
        let url = fileUrl.appendingPathComponent(fileName.rawValue, isDirectory: false)
        
        if !FileManager.default.fileExists(atPath: url.path) {
            return nil
        }
        
        if let data = FileManager.default.contents(atPath: url.path) {
            let decoder = JSONDecoder()
            do {
                let model = try decoder.decode(type, from: data)
                return model
            } catch {
                return nil
            }
        } else {
            return nil
        }
    }
    
    /// Remove specified file from specified directory
    func remove() {
        let url = fileUrl.appendingPathComponent(fileName.rawValue, isDirectory: false)
        if FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                fatalError(error.localizedDescription)
            }
        }
    }
    
    /// Returns BOOL indicating whether file exists at specified directory with specified file name
    var fileExists: Bool {
        let url = fileUrl.appendingPathComponent(fileName.rawValue, isDirectory: false)
        return FileManager.default.fileExists(atPath: url.path)
    }
}
