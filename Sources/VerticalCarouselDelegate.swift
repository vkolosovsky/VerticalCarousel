import UIKit

@objc public protocol VerticalCarouselDelegate: class {
    @objc optional func didScroll(VerticalCarouselView: VerticalCarouselView)
    @objc optional func didEndScroll(VerticalCarouselView: VerticalCarouselView)
}
