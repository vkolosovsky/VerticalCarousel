import Foundation
import UIKit

extension VerticalCarousel {
    /// Takes an index as Int and converts it to an IndexPath with row: index and section: 0.
    internal func convertIndexToIndexPath(for index: Int) -> IndexPath {
        return IndexPath(row: index, section: 0)
    }
}
