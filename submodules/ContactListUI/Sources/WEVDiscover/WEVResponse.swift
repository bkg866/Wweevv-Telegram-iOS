//
//  WEVResponse.swift
//  _idx_ContactListUI_1D7887AF_ios_min13.0
//
//  Created by Apple on 15/09/22.
//

import Foundation
import UIKit
import HandyJSON
import WevModel
struct WEVVideoModel: HandyJSON {
    
     var channel: WEVChannel?
     var liveId = ""
     var id = ""
     var videoDescription = ""
     var videoId = ""
     var videoPublishedAt = ""
     var videoThumbnailsUrl = ""
     var videoTitle = ""
     var videoUrl = ""
     var wweevvVideoUrl = ""
     var views = 0
     var anchor: Anchor?
     var isSponsored = false
    
     mutating func mapping(mapper: HelpingMapper) {
        mapper <<< self.channel <-- "channelId"
        mapper <<< self.anchor <-- "livePojo"
        mapper <<< self.isSponsored <-- "sponsorFlag"
    }


    /// 主播
    struct Anchor: HandyJSON {
         var channel: WEVChannel?
         var liveDescription = ""
         var id = ""
         var liveHeadUrl = ""
         var liveId = ""
         var liveName = ""
         var regionCode = ""
        /// 是否已订阅
         var isSubscribed = false
        
         mutating func mapping(mapper: HelpingMapper) {
            mapper <<<
                self.channel <-- "channelId"
            
            mapper <<<
                self.isSubscribed <-- "substrFlag"
        }
        
    }
}
extension WEVVideoModel {
    public var videlLiveUrl: String? {
        get {
            var url:String? = nil
            switch channel {
            case .youtube:
                url = "https://www.youtube.com/watch?v=\(videoId)"
            case .twitch:
                url = "https://www.twitch.tv/\(videoId)"
            case .facebook:
                //url = "https://www.youtube.com/watch?v=\(videoId)"
                url = nil
            default:
                return nil
            }
            return url
        }
    }

}

open class DictionaryEncoder {
    let jsonEncoder = JSONEncoder()

    /// Encodes given Encodable value into an array or dictionary
    public func encode<T>(_ value: T) throws -> Any where T: Encodable {
        let jsonData = try jsonEncoder.encode(value)
        return try JSONSerialization.jsonObject(with: jsonData, options: .allowFragments)
    }
}

open class DictionaryDecoder {
    let jsonDecoder = JSONDecoder()

    /// Decodes given Decodable type from given array or dictionary
    public func decode<T>(_ type: T.Type, from json: Any) throws -> T where T: Decodable {
        let jsonData = try JSONSerialization.data(withJSONObject: json, options: [])
        return try jsonDecoder.decode(type, from: jsonData)
    }
}
