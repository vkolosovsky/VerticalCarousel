import UIKit
import VerticalCarousel

class ContentCardCell: VerticalCardCell {

    internal var web = MarkdownView()
    internal weak var parent: UICollectionView?

    internal var heightContraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: CGRect.zero)
        self.web.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(web)
        setupLayout()
        web.isUserInteractionEnabled = true

        web.onRendered = { [weak self] height in
            guard let strongSelf = self else { return }
            print("will update height to \(height)")
            strongSelf.onHeightUpdated?((actual: height, max: height)) //max(height, strongSelf.web.frame.height)

            if strongSelf.heightContraint == nil {
                strongSelf.heightContraint = strongSelf.web.heightAnchor.constraint(equalToConstant: height)
                strongSelf.heightContraint?.isActive = true
            } else {
                strongSelf.heightContraint?.constant = height
            }

        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    internal final func setupLayout() {

        self.translatesAutoresizingMaskIntoConstraints = false
        web.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0).isActive = true

        web.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 0).isActive = true
        web.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 0).isActive = true

    }

    var markdownString: String?
    internal func setupWithModel(markdown: String) {
        if markdownString == nil {
            markdownString = markdown
            self.web.load(markdown: markdown)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.web.webView?.stopLoading()
        markdownString =  nil
    }

}
