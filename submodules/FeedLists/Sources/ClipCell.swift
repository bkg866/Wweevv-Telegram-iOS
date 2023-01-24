//
//  ClipCell.swift
//  CrissCross
//
//  Created by Kyle Lee on 9/3/20.
//  Copyright © 2020 Kilo Loco. All rights reserved.
//

//import Amplify
import Combine
import UIKit
import YoutubeKit
import SnapKit
import WevConfig
import TelegramPresentationData

protocol ClipCellDelegate {
    func videoError(message: String)
}

final class ClipCell: UICollectionViewCell {
    
    let actionPublisher = PassthroughSubject<Action, Never>()
    var delegate: ClipCellDelegate?
    private var downloadVideoToken: AnyCancellable?
    
    private lazy var videoView = VideoView.create {
        $0.frame = contentView.bounds
        $0.delegate = self
        $0.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private lazy var playerContainer = UIView.create {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.backgroundColor = .black
    }
    
    private lazy var playerView: YTSwiftyPlayer = {
        let playerView = YTSwiftyPlayer(
            frame: .zero)
        playerView.delegate = self
        playerView.translatesAutoresizingMaskIntoConstraints = false
        return playerView
    }()
    
    private lazy var captionLabel = UILabel.create {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.textColor = .white
        $0.adjustsFontForContentSizeCategory = true
        $0.font = .preferredFont(forTextStyle: .body)
        $0.numberOfLines = 3
    }
    
    private lazy var detailsStackView = UIStackView.create {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.axis = .vertical
        $0.distribution = .equalSpacing
        $0.alignment = .leading
        $0.spacing = 8
    }
    
    private lazy var actionStackView = UIStackView.create {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.axis = .vertical
        $0.distribution = .fillEqually
        $0.alignment = .center
        $0.spacing = 8
    }
    
    private lazy var shareStackView = UIStackView.create {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.axis = .vertical
        $0.distribution = .equalSpacing
        $0.alignment = .center
        $0.spacing = 3
    }
    
    private var shareButton = UIButton.create {
        $0.titleLabel?.font = LJFont.medium(14)
        $0.backgroundColor = UIColor.black.withMultipliedAlpha(0.4)
        $0.layer.cornerRadius = 24
        $0.setImage(UIImage(named: "shareVideo"), for: .normal)
    }
    
    private var shareCountLabel = UILabel.create {
        $0.font = LJFont.medium(12)
        $0.textColor = UIColor.white
        $0.textAlignment = .center
        $0.text = "Share"
    }
    
    private lazy var likeStackView = UIStackView.create {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.axis = .vertical
        $0.distribution = .equalSpacing
        $0.alignment = .center
        $0.spacing = 0
    }
    
    private var likeButton = UIButton.create {
        $0.titleLabel?.font = LJFont.medium(14)
        $0.backgroundColor = UIColor.black.withMultipliedAlpha(0.4)
        $0.layer.cornerRadius = 24
        $0.setImage(UIImage(named: "tabbar_feed_unselect"), for: .normal)
        $0.setImage(UIImage(named: "tabbar_feed_selected"), for: .selected)
    }
    
    private var likeCountLabel = UILabel.create {
        $0.font = LJFont.medium(12)
        $0.textColor = UIColor.white
        $0.textAlignment = .center
        $0.text = "Like"
    }
    
    private var clip: Clip?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSelf()
        setupSubviews()
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    private func setupSelf() {
        backgroundColor = .black
    }
    
    private func setupSubviews() {
        detailsStackView.addArrangedSubviews(
            captionLabel
        )
        
        playerContainer.addSubviews(
            playerView
        )
        
        addSubviews(
            playerContainer,
            videoView,
            detailsStackView,
            actionStackView
        )
        
        actionStackView.addArrangedSubviews(shareStackView, likeStackView)
        actionStackView.snp.makeConstraints { (make) in
            make.bottom.equalTo(detailsStackView.snp.bottom)
            make.leading.equalTo(detailsStackView.snp.trailing).offset(10)
            make.trailing.equalToSuperview().offset(-16)
            make.width.equalTo(40)
        }
        
        shareButton.addTarget(self, action: #selector(didTapButton(_:)), for: .touchUpInside)
        shareStackView.addArrangedSubviews(shareButton, shareCountLabel)
        shareStackView.snp.makeConstraints { make in
            make.height.equalTo(55)
        }
        shareButton.snp.makeConstraints { make in
            make.height.width.equalTo(40)
        }
        
        likeButton.addTarget(self, action: #selector(didTapButton(_:)), for: .touchUpInside)
        likeStackView.addArrangedSubviews(likeButton, likeCountLabel)
        likeStackView.snp.makeConstraints { make in
            make.height.equalTo(55)
        }
        likeButton.snp.makeConstraints { make in
            make.height.width.equalTo(40)
        }
        
        let bottomPadding: CGFloat = -5
        playerContainer.snp.makeConstraints { make in
            make.top.bottom.left.right.equalToSuperview()
        }
        let widthToHeightRatio: CGFloat = 9.0 / 16.0
        let height = LJScreen.width * widthToHeightRatio
        
        playerView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.equalTo(LJScreen.width)
            make.height.equalTo(height)
        }
        
        videoView.snp.makeConstraints { make in
            make.top.bottom.left.right.equalToSuperview()
        }
        
        captionLabel.snp.makeConstraints { make in
            make.leading.equalTo(detailsStackView.snp.leading)
            make.trailing.equalTo(detailsStackView.snp.trailing)
        }
        
        detailsStackView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(-(bottomPadding))
            make.bottom.equalToSuperview().offset(bottomPadding)
        }
    }
    
    func populate(with clip: Clip, delegate: ClipCellDelegate, presentationData: PresentationData) {
        self.delegate = delegate
        self.clip = clip
        self.reloadVideo()
        self.shareStackView.isHidden = clip.type != .youtube
        if clip.likeCount == 0 {
            self.likeCountLabel.text = "Like"
        } else {
            self.likeCountLabel.text = "\(clip.likeCount)"
        }
    }
    
    func reloadVideo() {
        guard let clip = self.clip else {
            return
        }
        
        captionLabel.text = clip.caption
        switch clip.type {
        case .tiktok, .rumble:
            self.videoView.isHidden = false
            self.videoView.prepareVideo(at: clip.videoURL, video: clip)
        case .youtube:
            self.videoView.isHidden = true
            self.loadPlayerWithVideoId(clip.videoURL)
        case .twitch:
            fatalError("Not implemented at")
        }
    }
    
    func togglePlay(on: Bool, forceStop: Bool?) {
        guard let clip = self.clip else {
            return
        }
        switch clip.type {
        case .tiktok, .rumble:
            videoView.togglePlay(on: on, forceStop: forceStop)
        case .youtube:
            toggleYoutubePlay(on: on)
        case .twitch:
            fatalError("Not implemented at")
        }
    }
    
    func cleanPlayer() {
        guard let clip = self.clip else {
            return
        }
        
        switch clip.type {
        case .tiktok, .rumble:
            videoView.cleanPlayer()
        case .youtube:
            playerView.pauseVideo()
            playerView.clearVideo()
        case .twitch:
            fatalError("Not implemented at")
        }
    }
    
    func toggleYoutubePlay(on: Bool? = nil) {
        if let on = on {
            on ? playerView.playVideo() : playerView.pauseVideo()
        }
    }
    
    func loadPlayerWithVideoId(_ videoId: String) {
        playerView.setPlayerParameters([
            .playsInline(true),
            .videoID(videoId),
            .showControls(.hidden),
            .showModestbranding(true),
            .showLoadPolicy(true),
            .progressBarColor(.white),
            .showRelatedVideo(false),
            .showFullScreenButton(false),
            .showInfo(false),
        ])

        if self.playerView.playerState == .unstarted {
            playerView.loadDefaultPlayer()
        } /*else {
            playerView.playVideo()
        }*/
    }
    
    
    @objc
    func didTapButton(_ sender: UIButton) {
        guard let clip = self.clip else { return }
         
         let action: Action
         
         switch sender {
//         case profileButton: action = .profile(clip)
         case likeButton:
             sender.isSelected = !sender.isSelected
             action = .like(clip)
//         case commentButton: action = .comment(clip)
         case shareButton: action = .share(clip)
//         case soundButton: action = .sound(clip)
         default: return
         }
         
         print("Tapped")
         
         actionPublisher.send(action)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        togglePlay(on: false, forceStop: nil)
        
    }
    
    deinit {
        self.cleanPlayer()
    }
}

extension ClipCell: VideoViewDelegate {
    func videoPlayError(message: String) {
        delegate?.videoError(message: message)
    }
}

extension ClipCell: Reusable {}

extension ClipCell {
    private static let buttonDimension: CGFloat = 50
    
    enum Action {
        case comment(Clip)
        case like(Clip)
        case profile(Clip)
        case share(Clip)
        case sound(Clip)
    }
}

extension ClipCell: YTSwiftyPlayerDelegate {
    func playerReady(_ player: YTSwiftyPlayer) {
        player.playVideo()
    }
    
    func player(_ player: YTSwiftyPlayer, didReceiveError error: YTSwiftyPlayerError) {
        switch error {
        case .invalidURLRequest:
            delegate?.videoError(message: "Invalid URL Request")
        case .html5PlayerError:
            delegate?.videoError(message: "Player Error")
        case .videoNotFound:
            delegate?.videoError(message: "Video Not Found")
        case .videoNotPermited:
            delegate?.videoError(message: "Video Not Permited")
        case .videoLicenseError:
            delegate?.videoError(message: "Video License Error")
        }
    }
}
