import Foundation
import UIKit
import Display
import AsyncDisplayKit
import Postbox
import TelegramCore
import SwiftSignalKit
import TelegramPresentationData
import MergeLists
import ItemListUI
import PresentationDataUtils
import AccountContext
import ShareController
import SearchBarNode
import SearchUI
import UndoUI
import TelegramUIPreferences
import TranslateUI
import PostgREST
import Realtime
import GalleryUI
import WevConfig
import WevModel
import Combine
import Alamofire
import AVFoundation
import RESegmentedControl

final class WEVFeedListControllerNode: ViewControllerTracingNode {
    private let context: AccountContext
    private var presentationData: PresentationData
    private weak var navigationBar: NavigationBar?
    private var controller: WEVFeedListController!
    private let requestActivateSearch: () -> Void
    private let requestDeactivateSearch: () -> Void
    private let present: (ViewController, Any?) -> Void
    private let push: (ViewController) -> Void
    
    private var didSetReady = false
    let _ready = ValuePromise<Bool>()
    
    private var containerLayout: (ContainerViewLayout, CGFloat)?
    private let presentationDataValue = Promise<PresentationData>()
    private let isEditing = ValuePromise<Bool>(false)
    private var isEditingValue: Bool = false {
        didSet {
            self.isEditing.set(self.isEditingValue)
        }
    }
    
    private let supabaseUrl = LJConfig.SupabaseKeys.supabaseUrl
    private let supabaseKey = LJConfig.SupabaseKeys.supabaseKey
    var arrWatchLater: [WatchLaterVideo] = []
    private var currentLayout: CGSize = .zero
    private var client: PostgrestClient?
    private var currentSegmentType: SegmentItemsType = .Popular
    
    //Code For Player
    private var getClipsToken: AnyCancellable?
    private var observeNewClipsToken: AnyCancellable?
    private var willDisplayCellToken: AnyCancellable?
    private var cellDisappearedToken: AnyCancellable?
    private var focusPublisher: AnyCancellable?
    private var cellActionToken: AnyCancellable?
    private var isPlayVideo = true
    var currentCell: ClipCell? {
        didSet {
            oldValue?.togglePlay(on: false, forceStop: nil)
            currentCell?.reloadVideo()
            currentCell?.togglePlay(on: true, forceStop: nil)
        }
    }
    var currentCellIndex: IndexPath?
    private let feedManager = FeedCollectionViewManager()
    private let feedView = FeedView()
    
    lazy var segmentHeight: CGFloat = 40
    
    init(context: AccountContext, presentationData: PresentationData, navigationBar: NavigationBar, controller: WEVFeedListController, requestActivateSearch: @escaping () -> Void, requestDeactivateSearch: @escaping () -> Void, updateCanStartEditing: @escaping (Bool?) -> Void, present: @escaping (ViewController, Any?) -> Void, push: @escaping (ViewController) -> Void) {
        self.context = context
        self.presentationData = presentationData
        self.presentationDataValue.set(.single(presentationData))
        self.navigationBar = navigationBar
        self.requestActivateSearch = requestActivateSearch
        self.requestDeactivateSearch = requestDeactivateSearch
        self.present = present
        self.push = push
        self.controller = controller
        super.init()
        self.backgroundColor = presentationData.theme.list.blocksBackgroundColor
    }
    
    private var navigationController: NavigationController? {
        if let navigationController = self.controller.navigationController as? NavigationController {
            return navigationController
        }
        return nil
    }
    
    enum SegmentItemsType: String {
        case Popular
        case Subscribed
        case WatchLater = "Watch Later"
    }
    
    //segment control
    private lazy var segmentControl: RESegmentedControl = {
        let segmentControl = RESegmentedControl()
        
        var segmentItems: [SegmentModel] = [
            SegmentModel(title: "Popular", searchStatus: SegmentItemsType.Popular.rawValue),
            SegmentModel(title: "Subscribed", searchStatus: SegmentItemsType.Subscribed.rawValue),
            SegmentModel(title: "Watch Later", searchStatus: SegmentItemsType.WatchLater.rawValue)
        ]
        
        var preset = MaterialPreset(backgroundColor: UIColor.init(white: 0, alpha: 0.4), tintColor: self.presentationData.theme.rootController.tabBar.selectedIconColor, normalColor: .white)
        preset.segmentItemAxis = .horizontal
        preset.segmentItemStyle.spacing = 0
        preset.spaceBetweenImageAndLabel = 0
        preset.segmentSelectedItemStyle.size = SelectedSegmentSize.height(8, position: .top)
        preset.segmentItemStyle.cornerRadius = segmentHeight / 2
        preset.segmentStyle.cornerRadius = segmentHeight / 2
        preset.segmentStyle.clipsToBounds = true
        preset.segmentSelectedItemStyle.backgroundColor = .clear
        
        segmentControl.configure(segmentItems: segmentItems, preset: preset)
        segmentControl.delegate = self
        segmentControl.layer.cornerRadius = segmentHeight / 2
        segmentControl.canCollectionViewIndexChange = false
        return segmentControl
    }()
    
    deinit {
    }
    
    func updatePresentationData(_ presentationData: PresentationData) {
        self.presentationData = presentationData
        self.presentationDataValue.set(.single(presentationData))
        self.backgroundColor = presentationData.theme.list.blocksBackgroundColor
    }
    
    
    
    func containerLayoutUpdated(_ layout: ContainerViewLayout, navigationBarHeight: CGFloat, transition: ContainedViewLayoutTransition) {
        let hadValidLayout = self.containerLayout != nil
        self.containerLayout = (layout, navigationBarHeight)
        
        if !hadValidLayout {
            self.dequeueTransitions(navigationBarHeight: navigationBarHeight, layout: layout)
        } else {
            //if there is an oriention update layout
            if self.currentLayout != layout.size {
                //self.updateConstriant(navigationBarHeight: navigationBarHeight)
            }
        }
        
        let segmentControlNode = ASDisplayNode { () -> UIView in
            return self.segmentControl
        }
        
        // 2. add node to view hierachy > then snapkit
        self.addSubnode(segmentControlNode)
        segmentControl.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(30)
            make.right.equalToSuperview().offset(-30)
            make.top.equalToSuperview().offset(navigationBarHeight / 2)
            make.height.equalTo(segmentHeight)
        }
        
        self.currentLayout = layout.size
    }
    
    private func dequeueTransitions(navigationBarHeight: CGFloat, layout: ContainerViewLayout) {
        guard let _ = self.containerLayout else {
            return
        }
        
        if !self.didSetReady {
            client = PostgrestClient(
                url: "\(supabaseUrl)/rest/v1",
                headers: ["apikey": supabaseKey],
                schema: "public")
            self.didSetReady = true
            self._ready.set(true)
            self.initView(navigationBarHeight: navigationBarHeight, layout: layout)
        }
    }

    func toggleEditing() {
        self.isEditingValue = !self.isEditingValue
    }
        
    private func initView(navigationBarHeight: CGFloat, layout: ContainerViewLayout) {
        
        //layout.intrinsicInsets.bottom
        let feedViewNode =  ASDisplayNode { () -> UIView in
            return self.feedView
        }
        self.addSubnode(feedViewNode)
        feedView.snp.makeConstraints { (make) in
            make.left.top.right.equalToSuperview()
            make.bottom.equalTo(self.view.snp_bottomMargin)
            //make.bottom.equalTo(self.view.snp.bottom).offset(-layout.intrinsicInsets.bottom)
        }
        
        configure()
    }
    
    private func configure() {
        feedView.register(ClipCell.self)
        feedManager.cellForRow = { collectionView, indexPath, clip in
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: ClipCell.reuseIdentifier,
                for: indexPath
            )
            
            let clipCell = cell as? ClipCell
            clipCell?.populate(with: clip, delegate: self, presentationData: self.presentationData)
            if self.currentCell == nil {
                self.currentCell = clipCell
                self.currentCellIndex = indexPath
            }
            return cell
        }
        
        willDisplayCellToken = feedManager.willDisplayCellPublisher
            .filter { $0.cell.frame != .zero }
            .compactMap { event -> (cell: ClipCell, indexPath: IndexPath)? in
                guard let clipCell = event.cell as? ClipCell else { return nil }
                return (clipCell, event.indexPath)
            }
            .sink { [weak self] event in
                //self?.currentCell = event.cell
                //event.cell.togglePlay(on: true)
                if self?.isPlayVideo == true {
                    event.cell.togglePlay(on: true, forceStop: nil)
                    self?.isPlayVideo = false
                }
                self?.cellActionToken = event.cell.actionPublisher
                    .sink { self?.handle($0) }
            }
        
        /*cellDisappearedToken = feedManager.cellDisappearedPublisher
            .filter { $0.cell.frame != .zero }
            .compactMap { event -> (cell: ClipCell, indexPath: IndexPath)? in
                guard let clipCell = event.cell as? ClipCell else { return nil }
                return (clipCell, event.indexPath)
            }
            .sink {
//                $0.cell.togglePlay(on: false)
                $0.cell.cleanPlayer()
            }*/
        
        focusPublisher = feedView.focusPublisher.sink(receiveValue: { [weak self] index in
            let indePath = IndexPath(item: index, section: 0)
            if let cell = self?.feedView.collectionView.cellForItem(at: indePath) as? ClipCell {
                self?.currentCell = cell
                self?.currentCellIndex = indePath
                
            }
            if index == 1 {
                if let cell = self?.feedView.collectionView.cellForItem(at: IndexPath(item: 0, section: 0)) as? ClipCell {
                    cell.togglePlay(on: false, forceStop: nil)
                }
            }
            //print(index)
        })
        
        feedView.bind(to: feedManager)
    }
    
    func scrollToTopWithTabBar() {
        guard let currentCellIndex = currentCellIndex else {
            return
        }

        if currentCellIndex.row != 0 {
            feedView.scrollToTop()
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .microseconds(400)) {
                self.selectedSegmentIndex(self.segmentControl, selectedIndex: self.segmentControl.selectedSegmentIndex)
            }
        } else {
            selectedSegmentIndex(segmentControl, selectedIndex: segmentControl.selectedSegmentIndex)
        }
    }

    private func handle(_ action: ClipCell.Action) {
        switch action {
        case .comment:
            print("comment")
            
        case .like(let video):
            let userId = self.context.account.peerId.id._internalGetInt64Value()
            let likeModel = ClipLikeVideo(userId: userId, videoId: video.id, type: video.type)
            doPerformLikeVideo(clipObj: likeModel)
            
        case .profile:
            print("profile")
            
        case .share(let video):
            shareButtonAction(video: video)
            
        case .sound:
            print("sound")
        }
    }
    
    private func shareButtonAction(video: Clip) {
        let code = "https://www.youtube.com/watch?v=\(video.videoURL)"
        let controller = ShareController(context: self.context, subject: .url(code), preferredAction: .default)
        self.controller.present(controller, in: .window(.root), blockInteraction: true)
    }
}
extension WEVFeedListControllerNode {
    
    func watchLaterRealTimeSync() {
        let rt = RealtimeClient(endPoint: "\(supabaseUrl)/realtime/v1", params: ["apikey": supabaseKey])
        
        rt.onOpen {
            print("Socket opened.")
            let allUsersUpdateChanges =  rt.channel(.table(LJConfig.SupabaseTablesName.watchLater, schema: "public"))
            
            allUsersUpdateChanges.on(.all) { message in
            }
            allUsersUpdateChanges.subscribe()
        }
        
        rt.onError{error in
            print("Socket error: ", error.localizedDescription)
        }
        
        rt.onClose {
            print("Socket closed")
        }
        
        rt.onMessage{message in
            switch message.event {
            case .insert, .update, .delete:
                self.doWatchLaterFetch()
            default:
                break
            }
        }
        rt.connect()
    }
    
    func doPerformLikeVideo(clipObj: ClipLikeVideo) {
        Task {
            await performLikeVideo(clipObj: clipObj)
        }
    }
    
    func performLikeVideo(clipObj: ClipLikeVideo) async {
        guard let client = self.client else {
            return
        }
        do {
            let insertedVideo = try await client.from(LJConfig.SupabaseTablesName.videoLikes)
                .insert(
                    values: clipObj,
                    returning: .representation
                )
                .execute()
            print(insertedVideo)
        } catch  {
            print(error.localizedDescription)
        }
    }
    
    func doPerformUnlikeVideo(id: Int64) {
        Task {
            await performUnlikeVideo(id: id)
        }
    }
    
    func performUnlikeVideo(id: Int64) async {
        guard let client = self.client else {
            return
        }
        do {
            try await client.from(LJConfig.SupabaseTablesName.videoLikes).delete().eq(column: "id", value: "\(id)").execute()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func doWatchLaterFetch() {
        Task {
            await fetchWatchLater()
        }
    }
    
    
    func fetchTiktokVideo(needToClear: Bool) {
        feedView.toggleRefreshControl(isShow: true)
        self.client?.from(LJConfig.SupabaseViews.feedLive).select().execute() { result in
            switch result {
            case let .success(response):
                do {
                    print("🌻 :",response)
                    let videos = try response.decoded(to: [TikTokVideo].self)
                    let clips = videos.map {
                        return Clip(tiktok: $0)
                    }
                    self.feedItems(clips, needToClearOldData: needToClear, videoType: .Popular)
                } catch {
                    debugPrint(error.localizedDescription)
                }
            case let .failure(error):
                debugPrint(error.localizedDescription)
            }
            self.feedView.toggleRefreshControl(isShow: false)
        }
    }
    
    func fetchYoutubVideo(needToClear: Bool) {
        
        let subscribes = fetchSubscribedList()
        var totalVideos = subscribes.count
        var arrSubVideo: [Item] = []
        let group = DispatchGroup()
        
        for index in 0..<subscribes.count where subscribes[index].videoType == 1 {
            if let channelId = subscribes[index].youTubeChannelId {
                feedView.toggleRefreshControl(isShow: true)
                group.enter()
                Alamofire.request("https://www.googleapis.com/youtube/v3/activities", method: .get, parameters: ["part":"snippet,id,contentDetails","channelId": channelId,"key": LJConfig.Youtube.apiKey]).responseJSON { response in
                    group.leave()
                    guard let data = response.data else { return }
                    do {
                        let decoder = JSONDecoder()
                        decoder.dateDecodingStrategy = .iso8601
                        let subscribeParsedData = try decoder.decode(WEVSubscribeActivity.self, from: data)
                        print(subscribeParsedData.items.count)
                        arrSubVideo.append(contentsOf: subscribeParsedData.items)
                        totalVideos -= 1
                        if totalVideos == 0 {
                            let videos = arrSubVideo.sorted(by: {$0.snippet.publishedAt.timeIntervalSince1970 < $1.snippet.publishedAt.timeIntervalSince1970})
                            let clips = videos.map {
                                return Clip(item: $0)
                            }
                            self.feedItems(clips, needToClearOldData: needToClear, videoType: .Subscribed)
                        }
                    } catch let error {
                        print(error)
                        totalVideos -= 1
                        if totalVideos == 0 {
                            let videos = arrSubVideo.sorted(by: {$0.snippet.publishedAt.timeIntervalSince1970 < $1.snippet.publishedAt.timeIntervalSince1970})
                            let clips = videos.map {
                                return Clip(item: $0)
                            }
                            self.feedItems(clips, needToClearOldData: needToClear, videoType: .Subscribed)
                        }
                    }
                }
            } else {
                totalVideos -= 1
                if totalVideos == 0 {
                    let videos = arrSubVideo.sorted(by: {$0.snippet.publishedAt.timeIntervalSince1970 < $1.snippet.publishedAt.timeIntervalSince1970})
                    let clips = videos.map {
                        return Clip(item: $0)
                    }
                    self.feedItems(clips, needToClearOldData: needToClear, videoType: .Subscribed)
                }
            }
        }
        
        group.notify(queue: .main) {
            self.feedView.toggleRefreshControl(isShow: false)
        }
    }
    
    func fetchWatchLater() async {
        guard let client = self.client else {
            return
        }
        
        var errMsg = ""
        // Get twitch videos
        do {
            let watchLater = try await client
                .from(LJConfig.SupabaseViews.watchLater)
                .select()
                .eq(column: "user_id", value: "\(context.account.peerId.id._internalGetInt64Value())")
                .execute()
                .decoded(to: [WatchLaterVideo].self)
            
            //assign watch later data to array
            self.arrWatchLater = watchLater
            //get watch later object
            for index in 0..<arrWatchLater.count where arrWatchLater[index].videoType == 1 {
                if let blob = arrWatchLater[index].blob, let data = blob.data(using: .utf8) {
                    do {
                        let video:YoutubeVideo = try JSONDecoder().decode(YoutubeVideo.self, from:data)
                        print("video:",video)
                        arrWatchLater[index].youTubeTitle = video.title
                        arrWatchLater[index].youTubeDescription = video.description
                        arrWatchLater[index].youTubeThumbnail = video.thumbnails[0]?.url ?? ""
                        arrWatchLater[index].youTubeViewCounts = video.viewCount
                    } catch {
                        print(error.localizedDescription)
                    }
                }
            }
            saveWatchList(arrWatchLater)
            
            let clips = arrWatchLater.map { Clip(watchLater: $0) }
            self.feedItems(clips, needToClearOldData: true, videoType: .WatchLater)
        
        } catch let DecodingError.dataCorrupted(context) {
            errMsg = "Decoding Error: " + context.debugDescription + "\n\( context.codingPath)"
            
        } catch let DecodingError.keyNotFound(key, context) {
            errMsg = "Key '\(key)' not found:" + context.debugDescription + "\n\( context.codingPath)"
        } catch let DecodingError.valueNotFound(value, context) {
            errMsg = "Value '\(value)' not found:" + context.debugDescription + "\n\( context.codingPath)"
            
        } catch let DecodingError.typeMismatch(type, context)  {
            errMsg = "Type '\(type)' mismatch:" + context.debugDescription + "\n\( context.codingPath)"
        } catch {
            errMsg = "error: " + error.localizedDescription
        }
        if !errMsg.isEmpty {
            print("<<<<<<<<",errMsg,">>>>>>")
        }
    }
    
    func feedItems(_ clips: [Clip], needToClearOldData: Bool, videoType: SegmentItemsType) {
        if currentSegmentType == videoType {
            self.feedManager.set(clips, needToClearOldData: needToClearOldData)
        }
    }
    
    func doPerformAddWatchLater(videoObj: NewWatchLaterVideo) {
        Task {
            await performAddWatchLater(videoObj: videoObj)
        }
    }
    
    func performAddWatchLater(videoObj: NewWatchLaterVideo) async {
        guard let client = self.client else {
            return
        }
        do {
            let insertedVideo = try await client.from(LJConfig.SupabaseTablesName.watchLater)
                .insert(
                    values: videoObj,
                    returning: .representation
                )
                .execute()
            print(insertedVideo)
        } catch  {
            print(error.localizedDescription)
        }
    }
    
    func doPerformRemoveWatchLater(id: Int64) {
        Task {
            await performRemoveWatchLater(id: id)
        }
    }
    
    func performRemoveWatchLater(id: Int64) async {
        guard let client = self.client else {
            return
        }
        do {
            try await client.from(LJConfig.SupabaseTablesName.watchLater).delete().eq(column: "id", value: "\(id)").execute()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func playVideo(video: WatchLaterVideo) {
        
        var videoTitle = ""
        var videoDescription = ""
        let websiteName = "YouTube"
        var url = ""
        let isLikedVideo = true
        switch video.videoType {
        case 1:
            guard let title = video.youTubeTitle, let ytId = video.youtubeId else  {
                return
            }
            videoTitle = title
            videoDescription = video.youTubeDescription ?? ""
            url = "https://www.youtube.com/watch?v=" + ytId
        case 2:
            guard let clipURL = video.clipEmbedUrl, let title = video.clipTitle else {
                return
            }
            url = clipURL + "&autoplay=true&parent=streamernews.example.com&parent=embed.example.com"
            videoTitle = title
        case 3:
            guard let clipURL = video.rumbleEmbedUrl, let title = video.rumbleTitle else {
                return
            }
            url = clipURL
            videoTitle = title
        default:
            return
        }
        
        let size = CGSize(width:1280,height:720)
        let updatedContent: TelegramMediaWebpageContent = .Loaded(TelegramMediaWebpageLoadedContent(url: url, displayUrl: url, hash: 0, type: nil, websiteName: websiteName, title: videoTitle, text: videoDescription, embedUrl: url, embedType: "iframe", embedSize: PixelDimensions(size), duration: nil, author: nil, image: nil, file: nil, attributes: [], instantPage: nil))
        
        let webPage = TelegramMediaWebpage(webpageId: MediaId(namespace: Namespaces.Media.CloudWebpage, id: 0), content: updatedContent)
        
        //let messageAttribute = MessageAttribute
        // attributes = ishdidden / type = Url / reactions
        let message = Message(stableId: 1, stableVersion: 1, id: MessageId(peerId: PeerId(0), namespace: 0, id: 0), globallyUniqueId: nil, groupingKey: nil, groupInfo: nil, threadId: nil, timestamp: 0, flags: [MessageFlags(rawValue: 64)], tags: [], globalTags: [], localTags: [], forwardInfo: nil, author: nil, text: url, attributes: [], media: [webPage], peers: SimpleDictionary(), associatedMessages: SimpleDictionary(), associatedMessageIds: [], associatedMedia: [:], associatedThreadInfo: nil)
        
        
        // Source is message?
        let source = GalleryControllerItemSource.standaloneMessage(message)
        let context = self.context
        
        let galleryVC = GalleryController(context: context, source: source , invertItemOrder: false, streamSingleVideo: true, fromPlayingVideo: false, landscape: false, timecode: nil, playbackRate: 1, synchronousLoad: false, isShowLike: true, isVideoLiked: isLikedVideo, replaceRootController: { controller, ready in
            print("👹  we're in replaceRootController....")
            if let baseNavigationController = self.navigationController {
                baseNavigationController.replaceTopController(controller, animated: false, ready: ready)
            }
        }, baseNavigationController: navigationController, actionInteraction: nil)
        galleryVC.temporaryDoNotWaitForReady = true
        galleryVC.temporaryDoNotWaitForReady = true
        galleryVC.useSimpleAnimation = true
        
        galleryVC.onLike = {
            print("user liked video")
            self.doPerformAddWatchLater(videoObj: NewWatchLaterVideo(videoType: video.videoType, userId: self.context.account.peerId.id._internalGetInt64Value(), twitchId: video.twitchId, youtubeId: video.youtubeId, rumbleId: video.rumbleId, tiktokId: video.tiktokId))
        }
        
        galleryVC.onDislike = {
            print("user unliked video")
            self.doPerformRemoveWatchLater(id: video.id)
        }
        
        self.controller.present(galleryVC, in: .window(.root))
    }
    
}

extension WEVFeedListControllerNode: ClipCellDelegate {
    func videoError(message: String) {
        showTootlipPopUp(message: message)
    }
    
    func showTootlipPopUp(message: String) {
        let toolTipcontroller = UndoOverlayController(presentationData: self.presentationData, content: .info(title: nil, text: message), elevatedLayout: false, animateInAsReplacement: false, action: { action in
            if action == .info {
                print("Action pressed")
                return true
            }
            return false
        })
        self.controller?.present(toolTipcontroller, in: .window(.root), with: nil)
    }
}


extension WEVFeedListControllerNode: RESegmentedControlDelegate {
    public func selectedSegmentIndex(_ segmentedControl: RESegmentedControl, selectedIndex: Int) {
        self.feedView.scrollToTop(animated: false)
        if self.currentCell == nil {
            if let cell = self.feedView.collectionView.cellForItem(at: IndexPath(item: 0, section: 0)) as? ClipCell {
                cell.cleanPlayer()
            }
        } else {
            self.currentCell?.cleanPlayer()
        }
        self.currentCell = nil
        
        if let searchStatus = segmentedControl.segmentItems[selectedIndex].searchStatus, let status = SegmentItemsType(rawValue: searchStatus) {
            self.currentSegmentType = status
            switch status {
            case .Popular:
                fetchTiktokVideo(needToClear: true)
                
            case .Subscribed:
                fetchYoutubVideo(needToClear: true)

            case .WatchLater:
                self.arrWatchLater = fetchWatchList()
                let clips = arrWatchLater.map { Clip(watchLater: $0) }
                self.feedItems(clips, needToClearOldData: true, videoType: .WatchLater)
            }
        }
    }
    
    func segmentItemsIndexChanged(_ segmentedControl: RESegmentedControl, updatedItems: [SegmentModel]) { }
}
