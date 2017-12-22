//
//  PlayerPanelViewController.swift
//  MusicPlayer
//
//  Created by Zhang Qin, EG-CN-70 on 8/2/17.
//  Copyright © 2017 qinchevy. All rights reserved.
//

import UIKit
import AVFoundation

class PlayerPanelViewController: UICollectionViewController {
    
    fileprivate let reuseIdentifier = "SongCell"
    fileprivate let maxItemsPerRow: CGFloat = 5
    fileprivate let sectionInsets = UIEdgeInsets(top: 50.0, left: 20.0, bottom: 50.0, right: 20.0)
    fileprivate let syncApi: SyncApiProtocol = LocalSyncApi()
    fileprivate var songs: [Song] = []
    fileprivate var currentSongIndex: Int = 0
    
    var player: AVAudioPlayer?
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // load local songs
        syncApi.sync() { results, error in
            if let error = error {
                // 2
                print("Error Loading : \(error)")
                return
            }
            
            if let results = results {
                // 3
                print("Loaded \(results.count) songs")
                self.songs.removeAll()
                self.songs = results
                
                // 4
                self.collectionView?.reloadData()
            }
        }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.stopPlayer),
            name: .UIApplicationDidEnterBackground,
            object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        if player?.isPlaying == true {
            player?.stop()
        }
        player = nil
    }

    @IBAction func syncFromServer(_ sender: UIBarButtonItem) {
//        syncApi.sync() { results, error in
//            if let error = error {
//                // 2
//                print("Error syncing : \(error)")
//                return
//            }
//            
//            if let results = results {
//                // 3
//                print("Synced \(results.count) songs")
//                self.songs.removeAll()
//                self.songs = results
//                
//                // 4
//                self.collectionView?.reloadData()
//            }
//        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */
}

// MARK: UICollectionViewDataSource
extension PlayerPanelViewController {

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return songs.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! SongCell
    
        cell.backgroundColor = UIColor.white
        cell.imageView.image = UIImage(contentsOfFile: songs[(indexPath as IndexPath).row].image_uri)
    
        return cell
    }
}

// MARK: UICollectionViewDelegate
extension PlayerPanelViewController {
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let url = URL(string: songs[(indexPath as IndexPath).row].song_uri) else { return }
        
        var needToPlay = true
        
        if player?.isPlaying == true {
            if player?.url == url {
                needToPlay = false
            }
            self.stopPlayer()
        }
        
        if needToPlay {
            playTrack(url)
            currentSongIndex = (indexPath as IndexPath).row
        }
    }
    
    func playTrack(_ url: URL) {
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.play()
            player?.delegate = self
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    @objc public func stopPlayer() {
        if player?.isPlaying == true {
            player?.stop()
        }
        player = nil
    }
}

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */

extension PlayerPanelViewController : UICollectionViewDelegateFlowLayout {
    
    // This method is responsible for telling the layout the size of a given cell
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        /* Here, you work out the total amount of space taken up by padding.There will be n + 1 evenly sized spaces, 
         where n is the number of items in the row. The space size can be taken from the left section inset. 
         Subtracting this from the view’s width and dividing by the number of items in a row gives you the width for each item. 
         You then return the size as a square */
        let paddingSpace = sectionInsets.left * (maxItemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / maxItemsPerRow
        
        return CGSize(width: widthPerItem, height: widthPerItem)
    }
    
    // This method returns the spacing between the cells, headers, and footers. A constant is used to store the value.
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    

    // This method controls the spacing between each line in the layout. You want this to match the padding at the left and right.
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
}

extension PlayerPanelViewController : AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if let url = nextTrack() {
            self.playTrack(url)
        }
    }
    
    func nextTrack() -> URL? {
        if (currentSongIndex < songs.count - 1) {
            currentSongIndex += 1
            return URL(string: songs[currentSongIndex].song_uri)
        }
        
        return nil
    }
}
