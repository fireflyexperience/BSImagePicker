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

import Photos

/**
Class wrapping fetch results as an selectable data source.
It will register itself as an change observer. So be sure to set yourself as delegate to get notified about updates.
*/
final class FetchResultsDataSource : NSObject, SelectableDataSource, PHPhotoLibraryChangeObserver {
    fileprivate var fetchResults: [PHFetchResult<PHObject>]
    var selections: [PHObject] = []
    
    var delegate: SelectableDataDelegate?
    var allowsMultipleSelection: Bool = false
    var maxNumberOfSelections: Int = Int.max
    
    var selectedIndexPaths: [IndexPath] {
        get {
            var indexPaths: [IndexPath] = []
            
            for object in selections {
                for (resultIndex, fetchResult) in fetchResults.enumerated() {
                    let index = fetchResult.index(of: object)

                    if index != NSNotFound {
                        let indexPath = IndexPath(item: index, section: resultIndex)
                        indexPaths.append(indexPath)
                    }
                }
            }

            return indexPaths
        }
    }

    convenience init(fetchResult: PHFetchResult<PHObject>) {
        self.init(fetchResults: [fetchResult])
    }

    required init(fetchResults: [PHFetchResult<PHObject>]) {
        self.fetchResults = fetchResults

        super.init()

        PHPhotoLibrary.shared().register(self)
    }

    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }

    // MARK: SelectableDataSource

    var sections: Int {
        get {
            return fetchResults.count
        }
    }

    func numberOfObjectsInSection(_ section: Int) -> Int {
        return fetchResults[section].count
    }

    func objectAtIndexPath(_ indexPath: IndexPath) -> PHObject
    {
        return fetchResults[(indexPath as NSIndexPath).section][(indexPath as NSIndexPath).row]
    }

    

    func selectObjectAtIndexPath(_ indexPath: IndexPath) {

        if isObjectAtIndexPathSelected(indexPath) == false && selections.count < maxNumberOfSelections {

            if allowsMultipleSelection == false {

                selections.removeAll(keepingCapacity: true)

            }

            

            selections.append(objectAtIndexPath(indexPath))

        }

    }

    

    func deselectObjectAtIndexPath(_ indexPath: IndexPath) {

        let object = objectAtIndexPath(indexPath)

        if let index = selections.firstIndex(of: object) {

            selections.remove(at: index)

        }

    }

    

    func isObjectAtIndexPathSelected(_ indexPath: IndexPath) -> Bool {

        let object = objectAtIndexPath(indexPath)

        

        return selections.contains(object)

    }

    

    // MARK: PHPhotoLibraryChangeObserver

    func photoLibraryDidChange(_ changeInstance: PHChange) {

        for (index, fetchResult) in fetchResults.enumerated() {
            // Check if there are changes to our fetch result
            if let collectionChanges = changeInstance.changeDetails(for: fetchResult ) {
                // Get the new fetch result
                let newResult = collectionChanges.fetchResultAfterChanges as PHFetchResult
                
                // Replace old result
                fetchResults[index] = newResult
                
                // Sometimes the properties on PHFetchResultChangeDetail are nil
                // Work around it for now
                let incrementalChange = collectionChanges.hasIncrementalChanges && collectionChanges.removedIndexes != nil && collectionChanges.insertedIndexes != nil && collectionChanges.changedIndexes != nil
                
                let removedIndexPaths: [IndexPath]
                let insertedIndexPaths: [IndexPath]
                let changedIndexPaths: [IndexPath]
                
                if incrementalChange {
                    // Incremental change, tell delegate what has been deleted, inserted and changed
                    removedIndexPaths = indexPathsFromIndexSet(collectionChanges.removedIndexes!, inSection: index)
                    insertedIndexPaths = indexPathsFromIndexSet(collectionChanges.insertedIndexes!, inSection: index)
                    changedIndexPaths = indexPathsFromIndexSet(collectionChanges.changedIndexes!, inSection: index)
                } else {
                    // No incremental change. Set empty arrays
                    removedIndexPaths = []
                    insertedIndexPaths = []
                    changedIndexPaths = []
                }
                
                // Notify delegate
                delegate?.didUpdateData(self, incrementalChange: incrementalChange, insertions: insertedIndexPaths, deletions: removedIndexPaths, changes: changedIndexPaths)
            }
        }
    }
    
    fileprivate func indexPathsFromIndexSet(_ indexSet: IndexSet, inSection section: Int) -> [IndexPath] {
        return (indexSet as NSIndexSet).enumerated().map {
            IndexPath(item: $0.0, section: section)
        }
    }
}
