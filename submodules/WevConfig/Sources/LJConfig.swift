//
//  LJConfig.swift
//  Wweevv
//
//  Created by panjinyong on 2020/12/22.
//

import Foundation
import TelegramCore

public struct LJConfig {
        
    
    public static var baseURL: String {
        return "https://api.wweevv.app/"
    }
    
    public static let AppID = "1561108032"
    
    //youtube api key
    public struct Youtube {
        public static let apiKey = "AIzaSyCAZjYdBW5zV8ULYvjni3lqOV_URiZVfzU"
    }
    
    public struct SupabaseKeys {
        //Production
        public static let supabaseUrl = "https://pqxcxltwoifmxcmhghzf.supabase.co"
        public static let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBxeGN4bHR3b2lmbXhjbWhnaHpmIiwicm9sZSI6ImFub24iLCJpYXQiOjE2NjAxODczNDQsImV4cCI6MTk3NTc2MzM0NH0.NiufAQmZ3Oy7eP7wNWF-tvH-e2D-UIz-vPLpLAyDMow"
        
//        //Development
//        public static let supabaseUrl = "https://rlzbzdrueihvlzcqskgd.supabase.co"
//        public static let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJsemJ6ZHJ1ZWlodmx6Y3Fza2dkIiwicm9sZSI6ImFub24iLCJpYXQiOjE2NjQ2MDE3MTYsImV4cCI6MTk4MDE3NzcxNn0.vlmVDDf50rb5SJ68F5u6IyckeTrW9c6Oa3_YhFyhD7c"
        
    }
    
    public struct API {
        public static let token = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJ7XCJ1c2VySWRcIjpcInVzX2M1TTN6MER4OHZcIixcImVtYWlsXCI6XCJ3d2VldnYxQGdtYWlsLmNvbVwifSIsImlhdCI6MTY2MzI0MTQ2N30.GEYCOKk5xbsMX0lk0q0EE6nRl4KiHRaFzYS2i2M3PSuATx82i_giIu-UE3wJq3owPTxCQD47q67V92SL1Q3q5A"
    }
    
    public struct SupabaseColumns {
        public static let clips = "id,user_id,user_name,profile_image_url,clip_id,clip_embed_url,clip_title,clip_view_count,clip_thumbnail_url"
        public static let youtube = "id,blob,channelId,channelTitle,is_live"
        public static let rumble = "id,title,thumbnail_url,embed_url,m3u8,viewer_count"
        public static let tiktok = "id,title,thumbnail_url,embed_url,m3u8,viewer_count"
    }
    
    public struct SupabaseTablesName {
        public static let youtube = "slim_video"
        public static let clips = "clips"
        public static let rumble = "rumble"
        public static let tiktok = "tiktok"
        public static let watchLater = "watch_later"
        public static let videoLikes = "video_likes"
        public static let subscribeVideo = "subscribed_channel"
    }
    
    public struct SupabaseViews {
        public static let watchLater = "watch_later_view"
        public static let subscribeView = "subscribed_channels_view"
        public static let feedLive = "fetch_live_videos"
    }
}
