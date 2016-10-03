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

final class AssetCollectionDataSource : NSObject, SelectableDataSource {
    fileprivate var assetCollection: PHAssetCollection
    var selections: [PHObject] = []
    
    var delegate: SelectableDataDelegate?
    var allowsMultipleSelection: Bool = false
    var maxNumberOfSelections: Int = 1
    
    var selectedIndexPaths: [IndexPath] {
        get {
            if selections.count > 0 {
                return [IndexPath(item: 0, section: 0)]
            } else {
                return []
            }
        }
    }
    
    required init(assetCollection: PHAssetCollection) {
        self.assetCollection = assetCollection
        
        super.init()
    }
    
    // MARK: SelectableDataSource
    var sections: Int {
        get {
            return 1
        }
    }
    
    func numberOfObjectsInSection(_ section: Int) -> Int {
        return 1
    }
    
    func objectAtIndexPath(_ indexPath: IndexPath) -> PHObject {
        assert((indexPath as NSIndexPath).section < 1 && (indexPath as NSIndexPath).row < 1, "AssetCollectionDataSource can only contain 1 section and row")
        return assetCollection
    }
    
    func selectObjectAtIndexPath(_ indexPath: IndexPath) {
        assert((indexPath as NSIndexPath).section < 1 && (indexPath as NSIndexPath).row < 1, "AssetCollectionDataSource can only contain 1 section and row")
        selections = [assetCollection]
    }
    
    func deselectObjectAtIndexPath(_ indexPath: IndexPath) {
        assert((indexPath as NSIndexPath).section < 1 && (indexPath as NSIndexPath).row < 1, "AssetCollectionDataSource can only contain 1 section and row")
        selections = []
    }
    
    func isObjectAtIndexPathSelected(_ indexPath: IndexPath) -> Bool {
        assert((indexPath as NSIndexPath).section < 1 && (indexPath as NSIndexPath).row < 1, "AssetCollectionDataSource can only contain 1 section and row")
        return selections.count > 0
    }
}
