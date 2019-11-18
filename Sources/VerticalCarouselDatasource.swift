import UIKit

public protocol VerticalCarouselDatasource: class {

    func numberOfCards(VerticalCarouselView: VerticalCarouselView) -> Int
    func cardForItemAt(VerticalCarouselView: VerticalCarouselView, cardForItemAt index: Int) -> VerticalCardCell
}
