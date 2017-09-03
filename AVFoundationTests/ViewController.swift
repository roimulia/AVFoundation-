//
//  ViewController.swift
//  AVFoundationTests
//
//  Created by Roi Mulia on 9/3/17.
//  Copyright © 2017 Roi Mulia. All rights reserved.
//

import UIKit
import AVFoundation


class ViewController: UIViewController {

    var playerLayer : AVPlayerLayer!
    private static var playerItemContext = 0
    
    // #MARK : Trigger video load
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        // Load local asset
        guard let path = Bundle.main.path(forResource: "puppy", ofType:"mp4") else {
            debugPrint("Video not found")
            return
        }
        
        let asset = AVAsset(url: URL(fileURLWithPath: path))
        
        prepareToPlay(asset: asset)
        
    }
    
    func prepareToPlay(asset : AVAsset) {
        
        // #MARK : Fetch compositions to be used for playback
        let comps = self.getBaseComp(asset: asset)
        let composition = comps.0
        let videoCompoistion = comps.1
        
        
        let assetKeys = [
            "playable",
            "hasProtectedContent"
        ]
        
        
        // Create a new AVPlayerItem with the compoistion and an
        // array of asset keys to be automatically loaded
        let playerItem = AVPlayerItem(asset: composition,
                                      automaticallyLoadedAssetKeys: assetKeys)
        
        // #MARK : Apply videoCompoistion
        // playerItem.videoComposition = videoCompoistion
        
        // Register as an observer of the player item's status property
        playerItem.addObserver(self,
                               forKeyPath: #keyPath(AVPlayerItem.status),
                               options: [.old, .new],
                               context: &ViewController.playerItemContext)
        
        
        
        if playerLayer == nil { // First play, init once
            let player = AVPlayer(playerItem: playerItem)
            self.playerLayer = AVPlayerLayer(player: player)
            self.playerLayer.frame = UIScreen.main.bounds
            self.view.layer.addSublayer(self.playerLayer)
            self.playerLayer.needsDisplayOnBoundsChange = true
        }
        else { // Replace item
            
            guard let player = self.playerLayer.player else { print("No Player Found"); return }
            
            // Remove old observer from previous item, if exists
            if let previousItem  = player.currentItem {
                previousItem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status))
            }
            
            player.replaceCurrentItem(with: playerItem)
        }
        
        
        
    }
    
    // #MARK : Get Compistion and VideoComposition
    func getBaseComp(asset : AVAsset) ->  (AVMutableComposition,AVMutableVideoComposition){
        
        // First copy our asset. (Not sure if needed)
        let asset = asset.copy() as! AVAsset
        
        // Than specity our Time Range
        let timeRange =  CMTimeRangeMake(kCMTimeZero, asset.duration)
        
        // Init Main compoistion
        let composition = AVMutableComposition()
        
        // Init main Video and Audio compistion
        // Create the video composition track.
        let mutableCompositionVideoTrack: AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaTypeVideo, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        // Video asset track
        let videoAssetTrack = asset.tracks(withMediaType: AVMediaTypeVideo)[0]
        
        // Add to video compistion
        try? mutableCompositionVideoTrack.insertTimeRange(timeRange, of: videoAssetTrack, at: kCMTimeZero)
        
        
        let realSize = resolutionSizeForLocalVideo(track: videoAssetTrack)!
        //mutableCompositionVideoTrack.preferredTransform = videoAssetTrack.preferredTransform
        
        
        
        //let cropFilter = CIFilter(name: "CICrop")
        let videoCompistion = AVMutableVideoComposition(asset: composition, applyingCIFiltersWithHandler: { request in
            
            let source = request.sourceImage
            
            
            //cropFilter?.setValue(source, forKeyPath: "inputImage")
            //cropFilter?.setValue(CIVector(cgRect: CGRect(x: 0, y: 0, width: 352, height: 433)), forKeyPath: "inputRectangle")
            
            // Provide the filter output to the composition
            request.finish(with:source, context: nil)
        })
        videoCompistion.renderSize = realSize
        
        
        return (composition,videoCompistion)
        
    }
    
    // #MARK : Observers method
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        // Only handle observations for the playerItemContext
        guard context == &ViewController.playerItemContext else {
            super.observeValue(forKeyPath: keyPath,
                               of: object,
                               change: change,
                               context: context)
            return
        }
        
        if keyPath == #keyPath(AVPlayerItem.status) {
            let status: AVPlayerItemStatus
            
            // Get the status change from the change dictionary
            if let statusNumber = change?[.newKey] as? NSNumber {
                status = AVPlayerItemStatus(rawValue: statusNumber.intValue)!
            } else {
                status = .unknown
            }
            
            // Switch over the status
            switch status {
            case .readyToPlay:
                DispatchQueue.main.async {
                    self.playerLayer.player?.pause()
                    self.playerLayer.player?.seek(to: kCMTimeZero)
                    self.playerLayer.player?.play()
                }
                
            // Player item is ready to play.
            case .failed: break
            // Player item failed. See error.
            case .unknown: break
                // Player item is not yet ready.
            }
        }
    }
    
    // #MARK : Helper methods
    func resolutionSizeForLocalVideo(track : AVAssetTrack) -> CGSize? {
        let size = track.naturalSize.applying(track.preferredTransform)
        return CGSize(width: fabs(size.width), height: fabs(size.height))
    }
    
    

}

