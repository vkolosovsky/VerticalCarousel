import UIKit

@objc open class VerticalCardCell: UICollectionViewCell {

    open var onHeightUpdated: ((HeightsPair) -> Void)?

    open override func layoutSubviews() {

        self.layer.shouldRasterize = true
        self.layer.rasterizationScale = UIScreen.main.scale

        super.layoutSubviews()
    }

    open override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)

        self.layer.zPosition = CGFloat(layoutAttributes.zIndex)
    }

    override open var isHidden: Bool{
        get { return super.isHidden}
        set(v) {
            super.isHidden = v
            self.layer.isHidden = v
        }
    }
}
