//
//  VideoView.swift
//  CrissCross
//
//  Created by Kyle Lee on 9/3/20.
//  Copyright © 2020 Kilo Loco. All rights reserved.
//

import AVKit
import UIKit
import AVFoundation
import SnapKit

protocol VideoViewDelegate {
    func videoPlayError(message: String)
}

class VideoView: UIView {
    
    var delegate: VideoViewDelegate?
    private var player: AVPlayer? {
        willSet {
            removePlayerObservers()
        }
        didSet {
            addPlayerObservers()
        }
    }

    private let playerLayer = AVPlayerLayer()

    private var loadingIndicator = PlayerLoadingIndicator()
    
    open fileprivate(set) var playerAsset : AVURLAsset?
    open fileprivate(set) var playerItem : AVPlayerItem? {
        willSet {
            playerItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status))
        }
        
        didSet {
            let options = NSKeyValueObservingOptions([.new, .initial])
            playerItem?.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: options, context: &playerItemContext)
            
        }
    }
    
    private var isPlaying: Bool {
        player?.rate != 0
    }
    
    fileprivate var needForceStopPlaying: Bool = false
    
    override var isUserInteractionEnabled: Bool {
        get { true }
        set {}
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSelf()
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    private func setupSelf() {
        backgroundColor = .black
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(didReceiveTap))
        addGestureRecognizer(tapRecognizer)
        
        playerLayer.videoGravity = .resizeAspect
        layer.addSublayer(playerLayer)
        
        loadingIndicator.lineWidth = 3.0
        addSubview(loadingIndicator)
        
        loadingIndicator.snp.makeConstraints { [weak self] (make) in
            guard let strongSelf = self else { return }
            make.center.equalTo(strongSelf)
            make.height.equalTo(30)
            make.width.equalTo(30)
        }
    }
    
    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        
        playerLayer.frame = layer.bounds
    }
    
    func prepareVideo(at path: String, video: Clip) {
        guard let url = URL(string: path) else {
            return
        }
        prepareVideo(at: url, video: video)
        
        //show start animating for rumble and tiktok
        loadingIndicator.isHidden = false
        loadingIndicator.startAnimating()

    }
    
    func prepareVideo(at url: URL, video: Clip) {
        playerAsset = AVURLAsset(url: url, options: .none)
        player?.replaceCurrentItem(with: nil)
        playerItem = AVPlayerItem(asset: playerAsset!)
        
        player = AVPlayer(playerItem: playerItem)
        playerLayer.player = player
        switch video.type {
        case .rumble:
            playerLayer.videoGravity = .resizeAspect
        default:
            playerLayer.videoGravity = .resizeAspectFill
        }
        print("Play URL: \(url)")
    }
    
    @objc
    private func didReceiveTap() {
        togglePlay(on: !isPlaying, forceStop: nil)
    }
    
    func cleanPlayer() {
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        player = nil
        playerLayer.player = nil
        playerAsset?.cancelLoading()
        playerAsset = nil
        playerItem?.cancelPendingSeeks()
        playerItem = nil
    }
    
    func togglePlay(on: Bool? = nil, forceStop: Bool?) {
        if let forceStop = forceStop {
            needForceStopPlaying = forceStop
        }
        
        if needForceStopPlaying {
            player?.pause()
            return
        }
        
        if let player = player {
            if let on = on {
                if on {
                    player.play()
                } else {
                    player.pause()
                }
            } else if isPlaying {
                player.pause()
            } else {
                cleanPlayer()
            }
        } else {
            cleanPlayer()
        }
    }
}

private var playerItemContext = 0
private var playerContext = 0
extension VideoView {
    
    internal func addPlayerObservers() {
        let options = NSKeyValueObservingOptions([.new, .initial])
        player?.addObserver(self, forKeyPath: #keyPath(AVPlayer.timeControlStatus), options: options, context: &playerContext)
    }
    
    internal func removePlayerObservers() {
        player?.removeObserver(self, forKeyPath: #keyPath(AVPlayer.timeControlStatus))
    }
}

extension VideoView {
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if (context == &playerItemContext), keyPath == #keyPath(AVPlayerItem.status) {
            if let playerItem = self.playerItem,  playerItem.status == .failed {
                self.loadingIndicator.isHidden = true
                self.loadingIndicator.stopAnimating()
                delegate?.videoPlayError(message: playerItem.error?.localizedDescription ?? "Video Not play. Please try again")
            } else {
                let status: AVPlayerItem.Status
                if let statusNumber = change?[.newKey] as? NSNumber {
                    status = AVPlayerItem.Status(rawValue: statusNumber.intValue)!
                } else {
                    status = .unknown
                }
                
                switch status {
                case .failed:
                    self.loadingIndicator.isHidden = true
                    self.loadingIndicator.stopAnimating()
                    delegate?.videoPlayError(message: playerItem?.error?.localizedDescription ?? "Video Not play. Please try again")
                    
                case .readyToPlay:
                    if needForceStopPlaying {
                        self.player?.pause()
                    }
                default:
                    break
                }
            }
        } else if (context == &playerContext), keyPath == #keyPath(AVPlayer.timeControlStatus) {
            if let status  =  player?.timeControlStatus {
                switch status {
                case .playing, .paused:
                    self.loadingIndicator.isHidden = true
                    self.loadingIndicator.stopAnimating()
                    
                default:
                    self.loadingIndicator.isHidden = false
                    self.loadingIndicator.startAnimating()
                    break
                }
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
}
