//
//  LJNetManager+Video.swift
//  Wweevv
//
//  Created by panjinyong on 2021/1/18.
//

import Foundation
import Alamofire
import WevModel
//MARK: 视频相关

extension LJNetManager {
    
    /// 视频相关
    public struct Video {
       
        /// 我关注的直播列表
        static public func feedList(nextPageToken: String?,
                             completion: @escaping RequestCompletion) {
            let params = ["nextPageToken": nextPageToken ?? "",
                          "channelIdArray": "",
                          "keyWord": ""]
            LJNetManager.request(url: "v1/api/Feed/video/list/", method: .post, bodyParameters: params, completion: completion)
        }
        
        /// 发现的直播banner列表
        static public func discoverBannerList(completion: @escaping RequestCompletion) {
            LJNetManager.request(url: "v1/api/Live/video/banner/list", method: .get, completion: completion)
        }

        /// 发现的直播列表
        /// - Parameters:
        ///   - channelArray: 频道筛选
        ///   - keyWord: 关键字搜索
        ///   - nextPageToken: 下一页token，由上个请求得到，第一页传nil
        ///   - offset: 关键字搜索情况下的请求才需要传，由上个请求得到，第一页传nil
        ///   - latitude: 纬度
        ///   - longitude: 经度
        ///   - completion: completion description
        static public func discoverList(channelArray: [WEVChannel],
                                 keyWord: String?,
                                 nextPageToken: String?,
                                 offset: Int?,
                                 latitude: Double?,
                                 longitude: Double?,
                                 completion: @escaping RequestCompletion) {
            var params = ["channelIdArray": "",
                          "keyWord": keyWord ?? "",
                          "nextPageToken": nextPageToken ?? "",
                          "offset": offset ?? 0] as [String : Any]
            if let latitude = latitude, let longitude = longitude {
                params["latitude"] = latitude
                params["longitude"] = longitude
            }
            if !channelArray.isEmpty {
                params.updateValue(channelArray.map{$0.rawValue}.joined(separator: ","), forKey: "channelIdArray")
            }
            LJNetManager.request(url: "v1/api/Discovery/video/list", method: .post, bodyParameters: params, completion: completion)
        }

        /// 根据输入内容匹配直播名字
        static public func searchName(liveName: String,
                               completion: @escaping RequestCompletion) {
            let params = ["liveName": liveName]
            LJNetManager.request(url: "v1/api/Live/LiveName/search", method: .post, bodyParameters: params, completion: completion)
        }

        /// 订阅某主播
        static public func subscribe(channel: WEVChannel,
                              liveId: String,
                              completion: @escaping RequestCompletion) {
            LJNetManager.request(url: "v1/api/Live/video/Substr/\(channel.rawValue)/\(liveId)", method: .post, completion: completion)
        }
        
        /// 取消订阅某主播
        static public func unsubscribe(channel: WEVChannel,
                                liveId: String,
                                completion: @escaping RequestCompletion) {
            LJNetManager.request(url: "v1/api/Live/video/Substr/\(channel.rawValue)/\(liveId)", method: .delete, completion: completion)
        }

        /// 我关注的主播列表
        static public func subscribeList(page: Int,
                                  size: Int,
                                  completion: @escaping RequestCompletion) {
            LJNetManager.request(url: "v1/api/Live/video/Substr/\(page)/\(size)", method: .get, completion: completion)
        }
        
        /// 用户是否可观看此视频（此视频是否需要成年，且当前用户是否已成年）
        static public func checkPermission(videoId: String,
                                    completion: @escaping RequestCompletion) {
            LJNetManager.request(url: "v1/api/checkPermission/\(videoId)", method: .post, completion: completion)
        }
    }
}
