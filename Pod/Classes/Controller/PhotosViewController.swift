// The MIT License (MIT)
//
// Copyright (c) 2015 Joakim Gyllström
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import UIKit
import Photos
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}


final class PhotosViewController : UICollectionViewController, UIPopoverPresentationControllerDelegate, UITableViewDelegate, UINavigationControllerDelegate, SelectableDataDelegate {
    var selectionClosure: ((PHAsset) -> Void)?
    var deselectionClosure: ((PHAsset) -> Void)?
    var cancelClosure: (([PHAsset]) -> Void)?
    var finishClosure: (([PHAsset]) -> Void)?
    
    var doneBarButton: UIBarButtonItem?
    var cancelBarButton: UIBarButtonItem?
    var albumTitleView: AlbumTitleView?
    
    fileprivate let expandAnimator = ZoomAnimator()
    fileprivate let shrinkAnimator = ZoomAnimator()
    
    fileprivate var photosDataSource: CollectionViewDataSource?
    fileprivate var albumsDataSource: TableViewDataSource
    
    fileprivate let photoCellFactory = PhotoCellFactory()
    fileprivate let albumCellFactory = AlbumCellFactory()
    
    fileprivate let settings: BSImagePickerSettings
    
    fileprivate var doneBarButtonTitle: String?
    
    fileprivate lazy var albumsViewController: AlbumsViewController? = {
        let storyboard = UIStoryboard(name: "Albums", bundle: BSImagePickerViewController.bundle)
        
        let vc = storyboard.instantiateInitialViewController() as? AlbumsViewController
        vc?.modalPresentationStyle = .popover
        vc?.preferredContentSize = CGSize(width: 320, height: 300)
        vc?.tableView.dataSource = self.albumsDataSource
        vc?.tableView.delegate = self
        
        return vc
    }()
    
    fileprivate lazy var previewViewContoller: PreviewViewController? = {
        return PreviewViewController(nibName: nil, bundle: nil)
    }()
    
    required init(dataSource: SelectableDataSource, settings aSettings: BSImagePickerSettings, selections: [PHAsset] = []) {
        albumsDataSource = TableViewDataSource(dataSource: dataSource, cellFactory: albumCellFactory)
        settings = aSettings
        
        super.init(collectionViewLayout: UICollectionViewFlowLayout())
        
        albumsDataSource.data.delegate = self
        
        // Default is to have first album selected
        albumsDataSource.data.selectObjectAtIndexPath(IndexPath(row: 0, section: 0))
        
        if let album = albumsDataSource.data.selections.first as? PHAssetCollection {
            initializePhotosDataSource(album)
            photosDataSource?.data.selections = selections
        }
    }

    required init?(coder aDecoder: NSCoder) {

        albumsDataSource = TableViewDataSource(dataSource: FetchResultsDataSource(fetchResults: []), cellFactory: albumCellFactory)

        albumsDataSource.data.allowsMultipleSelection = false

        settings = Settings()

        

        super.init(coder: aDecoder)

    }

    

    override func loadView() {

        super.loadView()

        

        // Setup collection view

        // TODO: Settings

        collectionView?.backgroundColor = UIColor.white

        photoCellFactory.registerCellIdentifiersForCollectionView(collectionView)

        

        // Set an empty title to get < back button

        title = " "

        

        // Set button actions and add them to navigation item

        doneBarButton?.target = self

        doneBarButton?.action = #selector(PhotosViewController.doneButtonPressed(_:))

        cancelBarButton?.target = self

        cancelBarButton?.action = #selector(PhotosViewController.cancelButtonPressed(_:))

        albumTitleView?.albumButton.addTarget(self, action: #selector(PhotosViewController.albumButtonPressed(_:)), for: .touchUpInside)

        navigationItem.leftBarButtonItem = cancelBarButton

        navigationItem.rightBarButtonItem = doneBarButton

        navigationItem.titleView = albumTitleView



        if let album = albumsDataSource.data.selections.first as? PHAssetCollection {

            updateAlbumTitle(album)

            synchronizeCollectionView()

        }

        

        // Add long press recognizer

        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(PhotosViewController.collectionViewLongPressed(_:)))

        longPressRecognizer.minimumPressDuration = 0.5

        collectionView?.addGestureRecognizer(longPressRecognizer)

        

        // Set navigation controller delegate

        navigationController?.delegate = self

    }

    

    // MARK: Appear/Disappear

    override func viewWillAppear(_ animated: Bool) {

        super.viewWillAppear(animated)

        

        updateDoneButton()

    }

    

    // MARK: Button actions

    @objc func cancelButtonPressed(_ sender: UIBarButtonItem) {

        if let closure = cancelClosure, let assets = photosDataSource?.data.selections as? [PHAsset] {
            DispatchQueue.global(qos: .background).async(execute: { () -> Void in

                closure(assets)

            })

        }

        

        dismiss(animated: true, completion: nil)

    }

    

    @objc func doneButtonPressed(_ sender: UIBarButtonItem) {

        if let closure = finishClosure, let assets = photosDataSource?.data.selections as? [PHAsset] {

            DispatchQueue.global(qos: .background).async(execute: { () -> Void in

                closure(assets)

            })

        }

        

        dismiss(animated: true, completion: nil)

    }

    

    @objc func albumButtonPressed(_ sender: UIButton) {

        if let albumsViewController = albumsViewController, let popVC = albumsViewController.popoverPresentationController {

            popVC.permittedArrowDirections = .up

            popVC.sourceView = sender

            let senderRect = sender.convert(sender.frame, from: sender.superview)

            let sourceRect = CGRect(x: senderRect.origin.x, y: senderRect.origin.y + (sender.frame.size.height / 2), width: senderRect.size.width, height: senderRect.size.height)

            popVC.sourceRect = sourceRect

            popVC.delegate = self

            albumsViewController.tableView.reloadData()

            

            present(albumsViewController, animated: true, completion: nil)

        }

    }

    

    @objc func collectionViewLongPressed(_ sender: UIGestureRecognizer) {

        if sender.state == .began {

            // Disable recognizer while we are figuring out location and pushing preview

            sender.isEnabled = false

            collectionView?.isUserInteractionEnabled = false

            

            // Calculate which index path long press came from

            let location = sender.location(in: collectionView)

            let indexPath = collectionView?.indexPathForItem(at: location)

            

            if let vc = previewViewContoller, let indexPath = indexPath, let cell = collectionView?.cellForItem(at: indexPath) as? PhotoCell, let asset = cell.asset {

                // Setup fetch options to be synchronous

                let options = PHImageRequestOptions()

                options.isSynchronous = true

                

                // Load image for preview

                if let imageView = vc.imageView {

                    PHCachingImageManager.default().requestImage(for: asset, targetSize:imageView.frame.size, contentMode: .aspectFit, options: options) { (result, _) in

                        imageView.image = result

                    }

                }

                

                // Setup animation

                expandAnimator.sourceImageView = cell.imageView

                expandAnimator.destinationImageView = vc.imageView

                shrinkAnimator.sourceImageView = vc.imageView

                shrinkAnimator.destinationImageView = cell.imageView

                

                navigationController?.pushViewController(vc, animated: true)

            }

            

            // Re-enable recognizer

            sender.isEnabled = true

            collectionView?.isUserInteractionEnabled = true

        }

    }

    

    // MARK: Traits

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?)
    {
        super.traitCollectionDidChange(previousTraitCollection)

        if let
            collectionViewFlowLayout = collectionViewLayout as? UICollectionViewFlowLayout,
            let collectionViewWidth = collectionView?.bounds.size.width
        {
            let itemSpacing: CGFloat = 1.0
            let cellsPerRow = settings.cellsPerRow(traitCollection.verticalSizeClass, traitCollection.horizontalSizeClass)

            collectionViewFlowLayout.minimumInteritemSpacing = itemSpacing
            collectionViewFlowLayout.minimumLineSpacing = itemSpacing

            let width = (collectionViewWidth / CGFloat(cellsPerRow)) - itemSpacing
            let itemSize =  CGSize(width: width, height: width)
            
            collectionViewFlowLayout.itemSize = itemSize
            photoCellFactory.imageSize = itemSize
        }
    }

    

    // MARK: UIPopoverPresentationControllerDelegate

    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {

        return .none

    }

    

    func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool {

        return true

    }

    

    // MARK: UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        // Update selected album

        albumsDataSource.data.selectObjectAtIndexPath(indexPath)

        

        // Notify photos data source

        if let album = albumsDataSource.data.selections.first as? PHAssetCollection {

            initializePhotosDataSource(album)

            updateAlbumTitle(album)

            synchronizeCollectionView()

        }

        

        // Dismiss album selection

        albumsViewController?.dismiss(animated: true, completion: nil)

    }

    

    // MARK: UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {

        return photosDataSource?.data.selections.count < settings.maxNumberOfSelections

    }

    

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        // Select asset)

        photosDataSource?.data.selectObjectAtIndexPath(indexPath)

        

        // Set selection number

        if let cell = collectionView.cellForItem(at: indexPath) as? PhotoCell, let count = photosDataSource?.data.selections.count {

            if let selectionCharacter = settings.selectionCharacter {

                cell.selectionString = String(selectionCharacter)

            } else {

                cell.selectionString = String(count)

            }

        }

        

        // Update done button

        updateDoneButton()

        

        // Call selection closure

        if let closure = selectionClosure, let asset = photosDataSource?.data.objectAtIndexPath(indexPath) as? PHAsset {

            DispatchQueue.global(qos: .background).async(execute: { () -> Void in

                closure(asset)

            })

        }

    }

    

    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {

        // Deselect asset

        photosDataSource?.data.deselectObjectAtIndexPath(indexPath)

        

        // Update done button

        updateDoneButton()

        

        // Reload selected cells to update their selection number

        if let photosDataSource = photosDataSource {

            UIView.setAnimationsEnabled(false)

            collectionView.reloadItems(at: photosDataSource.data.selectedIndexPaths as [IndexPath])

            syncSelectionInDataSource(photosDataSource.data, withCollectionView: collectionView)

            UIView.setAnimationsEnabled(true)

        }

        

        // Call deselection closure

        if let closure = deselectionClosure, let asset = photosDataSource?.data.objectAtIndexPath(indexPath) as? PHAsset {

            DispatchQueue.global(qos: .background).async(execute: { () -> Void in

                closure(asset)

            })

        }

    }

    

    // MARK: Selectable data delegate

    func didUpdateData(_ sender: SelectableDataSource, incrementalChange: Bool, insertions insert: [IndexPath], deletions delete: [IndexPath], changes change: [IndexPath]) {

        // May come on a background thread, so dispatch to main

        DispatchQueue.main.async(execute: { () -> Void in

            // Reload table view or collection view?

            if sender.isEqual(self.photosDataSource?.data)  {

                if let collectionView = self.collectionView {

                    if incrementalChange {

                        // Update

                        collectionView.deleteItems(at: delete)

                        collectionView.insertItems(at: insert)

                        collectionView.reloadItems(at: change)

                    } else {

                        // Reload & scroll to top if significant change

                        collectionView.reloadData()

                        collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: UICollectionView.ScrollPosition(), animated: false)

                    }

                    

                    // Sync selection

                    if let photosDataSource = self.photosDataSource {

                        self.syncSelectionInDataSource(photosDataSource.data, withCollectionView: collectionView)

                    }

                }

            } else if sender.isEqual(self.albumsDataSource.data) {

                if incrementalChange {

                    // Update

                    self.albumsViewController?.tableView?.deleteRows(at: delete, with: .automatic)

                    self.albumsViewController?.tableView?.insertRows(at: insert, with: .automatic)

                    self.albumsViewController?.tableView?.reloadRows(at: change, with: .automatic)

                } else {

                    // Reload

                    self.albumsViewController?.tableView?.reloadData()

                }

            }

        })

    }

    

    // MARK: Private helper methods

    func updateDoneButton() {

        // Get selection count

        if let numberOfSelectedAssets = photosDataSource?.data.selections.count {

            // Find right button

            if let subViews = navigationController?.navigationBar.subviews {

                for view in subViews {

                    if let btn = view as? UIButton , checkIfRightButtonItem(btn) {

                        // Store original title if we havn't got it

                        if doneBarButtonTitle == nil {

                            doneBarButtonTitle = btn.title(for: UIControl.State())

                        }

                        

                        // Update title

                        if numberOfSelectedAssets > 0 {

                            btn.bs_setTitleWithoutAnimation("\(doneBarButtonTitle!) (\(numberOfSelectedAssets))", forState: UIControl.State())

                        } else {

                            btn.bs_setTitleWithoutAnimation(doneBarButtonTitle!, forState: UIControl.State())

                        }

                        

                        // Stop loop

                        break

                    }

                }

            }

            

            // Enabled

            if numberOfSelectedAssets > 0 {

                doneBarButton?.isEnabled = true

            } else {

                doneBarButton?.isEnabled = false

            }

        }

    }

    

    // Check if a give UIButton is the right UIBarButtonItem in the navigation bar

    // Somewhere along the road, our UIBarButtonItem gets transformed to an UINavigationButton

    func checkIfRightButtonItem(_ btn: UIButton) -> Bool {

        var isRightButton = false

        

        if let rightButton = navigationItem.rightBarButtonItem {

            // Store previous values

            let wasRightEnabled = rightButton.isEnabled

            let wasButtonEnabled = btn.isEnabled
            
            // Set a known state for both buttons
            rightButton.isEnabled = false
            btn.isEnabled = false
            
            // Change one and see if other also changes
            rightButton.isEnabled = true
            isRightButton = btn.isEnabled
            
            // Reset
            rightButton.isEnabled = wasRightEnabled
            btn.isEnabled = wasButtonEnabled
        }
        
        return isRightButton
    }
    
    func syncSelectionInDataSource(_ dataSource: SelectableDataSource, withCollectionView collectionView: UICollectionView) {
        // Get indexpaths of selected assets
        let indexPaths = dataSource.selectedIndexPaths
        
        // Loop through them and set them as selected in the collection view
        for indexPath in indexPaths {
            collectionView.selectItem(at: indexPath as IndexPath, animated: false, scrollPosition: UICollectionView.ScrollPosition())
        }
    }
    
    fileprivate func updateAlbumTitle(_ album: PHAssetCollection) {
        // Update album title
        albumTitleView?.albumTitle = album.localizedTitle!
    }
    
    fileprivate func initializePhotosDataSource(_ album: PHAssetCollection) {
        // Set up a photo data source with album
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [
            NSSortDescriptor(key: "creationDate", ascending: false)
        ]
        fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
        let dataSource = FetchResultsDataSource(fetchResult: PHAsset.fetchAssets(in: album, options: fetchOptions) as! PHFetchResult<PHObject>)
        let newDataSource = CollectionViewDataSource(dataSource: dataSource, cellFactory: photoCellFactory)
        
        // Keep selection
        if let photosDataSource = photosDataSource {
            newDataSource.data.selections = photosDataSource.data.selections
        }
        
        photosDataSource = newDataSource
    }
    
    func synchronizeCollectionView() {
        // Hook up data source
        collectionView?.dataSource = photosDataSource
        collectionView?.delegate = self
        photosDataSource?.data.delegate = self
        
        // Enable multiple selection
        photosDataSource?.data.allowsMultipleSelection = true
        collectionView?.allowsMultipleSelection = true
        
        // Reload and sync selections
        collectionView?.reloadData()
        syncSelectionInDataSource(photosDataSource!.data, withCollectionView: collectionView!)
    }
    
    // MARK: UINavigationControllerDelegate
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if operation == .push {
            return expandAnimator
        } else {
            return shrinkAnimator
        }
    }
}
