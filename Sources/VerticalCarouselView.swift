import Foundation
import UIKit

public class VerticalCarouselView: UICollectionView {

    /// A `Bool` that indicates if the `UICollectionView` is currently scrolling.
    public var isScrolling: Bool {
        return (self.isDragging || self.isTracking || self.isDecelerating)
    }

    public func dequeueReusableCell(withReuseIdentifier identifier: String, for index: Int) -> UICollectionViewCell {
        return self.dequeueReusableCell(withReuseIdentifier: identifier, for: IndexPath(row: index, section: 0))
    }

    public var currentCardChanged:((_ fromIndex: Int, _ toIndex: Int) -> Void)?

}
