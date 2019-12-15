import UIKit

let kVerticalCarouselDebugEnable: String = "-VCDebugEnabled"

public func printLog(log: CustomDebugStringConvertible?) {

	if ProcessInfo.processInfo.arguments.contains(kVerticalCarouselDebugEnable) {
		let formatter = DateFormatter()
		formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS "
		print(formatter.string(from: NSDate() as Date), terminator: "")
		if log == nil {
			print("nil")
		} else {
			print(log!)
		}
	}
}

/**
 The VerticalCarousel is a subclass of `UIView` that has a `VerticalCarouselView` embedded.
 
 To use this, you need to implement the `VerticalCarouselDatasource`.
 
 If you want to handle actions like cards being swiped away, implement the `VerticalCarouselDelegate`.
 */
public class VerticalCarousel: UIView {

    public var currentCardIndex: Int {
        return self.flowLayout.currentPage()
    }

    /// The collectionView where all the magic happens.
    public var verticalCarouselView: VerticalCarouselView!

    /// The inset (spacing) at the top for the cards. Default is 40.
    @IBInspectable public var topInset: CGFloat = 40 {
        didSet {
            setCardSwiperInsets()
        }
    }
    /// The inset (spacing) at each side of the cards. Default is 20.
    @IBInspectable public var sideInset: CGFloat = 20 {
        didSet {
            setCardSwiperInsets()
        }
    }
    /// Sets how much of the next card should be visible. Default is 50.
    @IBInspectable public var visibleNextCardHeight: CGFloat = 50 {
        didSet {
            setCardSwiperInsets()
        }
    }
    /// Vertical spacing between CardCells. Default is 40.
    @IBInspectable public var cardSpacing: CGFloat = 40 {
        willSet {
            flowLayout.minimumLineSpacing = newValue
        }
        didSet {
            setCardSwiperInsets()
        }
    }

    public weak var delegate: VerticalCarouselDelegate?
    public weak var datasource: VerticalCarouselDatasource?

    /// The flowlayout used in the collectionView.
    fileprivate lazy var flowLayout: VerticalCarouselFlowLayout = {
        let flowLayout = VerticalCarouselFlowLayout()
        flowLayout.minimumLineSpacing = cardSpacing
        return flowLayout
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    public func setLastCardAllowed(number: Int) {
		let yInsets = cardSpacing + topInset + visibleNextCardHeight
		let newHeight = verticalCarouselView.frame.size.height - yInsets
		self.resetHeights(count: number+1, defaultValue: HeightsPair(newHeight, newHeight))
        flowLayout.setLastCardAllowed(number: number)
    }

    /**
     Inserts new cards at the specified indexes.

     Call this method to insert one or more new cards into the cardSwiper.
     You might do this when your data source object receives data for new items or in response to user interactions with the cardSwiper.
     - parameter indexes: An array of integers at which to insert the new card. This parameter must not be nil.
     */
    public func insertCards(at indexes: [Int]) {
        performUpdates {
            self.verticalCarouselView.insertItems(at: indexes.map { (index) -> IndexPath in
                return convertIndexToIndexPath(for: index)
            })
        }
    }

    /**
     Deletes cards at the specified indexes.

     Call this method to delete one or more new cards from the cardSwiper.
     You might do this when you remove the items from your data source object or in response to user interactions with the cardSwiper.
     - parameter indexes: An array of integers at which to delete the card. This parameter must not be nil.
     */
    public func deleteCards(at indexes: [Int]) {
        performUpdates {
            self.verticalCarouselView.deleteItems(at: indexes.map { (index) -> IndexPath in
                return self.convertIndexToIndexPath(for: index)
            })
        }
    }

    /**
     Moves an item from one location to another in the collection view.

     Use this method to reorganize existing cards. You might do this when you rearrange the items within your data source object or in response to user interactions with the cardSwiper. The cardSwiper updates the layout as needed to account for the move, animating cards into position as needed.

     - parameter atIndex: The index of the card you want to move. This parameter must not be nil.
     - parameter toIndex: The index of the card’s new location. This parameter must not be nil.
     */
    public func moveCard(at atIndex: Int, to toIndex: Int) {
        self.verticalCarouselView.moveItem(at: convertIndexToIndexPath(for: atIndex), to: convertIndexToIndexPath(for: toIndex))
    }

    private func commonInit() {
        setupVerticalCarouselView()
        setupConstraints()
        setCardSwiperInsets()
    }

    private func performUpdates(updateClosure: () -> Void) {
        UIView.performWithoutAnimation {
            self.verticalCarouselView.performBatchUpdates({
                updateClosure()
            }, completion: { [weak self] _ in
                self?.verticalCarouselView.collectionViewLayout.invalidateLayout()
            })
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        flowLayout.setFrameHeight(height: self.frame.height)
    }
}

extension VerticalCarousel: UICollectionViewDelegate, UICollectionViewDataSource {

    public func reloadData() {
        verticalCarouselView.reloadData()
    }

    public func scrollToCard(at index: Int, animated: Bool) {

        guard index >= 0 && index < verticalCarouselView.numberOfItems(inSection: 0) else { return }

        let y = self.flowLayout.getOffsetForPage(page: index)
        printLog(log: "=== Setting card=\(index) y=\(y) ")

        let point = CGPoint(x: verticalCarouselView.contentOffset.x, y: y)
        verticalCarouselView.setContentOffset(point, animated: animated)
        flowLayout.lastProposedY = y
    }

    public func register(_ cellClass: AnyClass?, forCellWithReuseIdentifier identifier: String) {
        self.verticalCarouselView.register(cellClass, forCellWithReuseIdentifier: identifier)
    }

    public func register(nib: UINib?, forCellWithReuseIdentifier identifier: String) {
        self.verticalCarouselView.register(nib, forCellWithReuseIdentifier: identifier)
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return datasource?.numberOfCards(VerticalCarouselView: verticalCarouselView) ?? 0
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let result = datasource?.cardForItemAt(VerticalCarouselView: verticalCarouselView, cardForItemAt: indexPath.item) ?? VerticalCardCell()

        result.onHeightUpdated = { height in
            self.updateCellHeight(height: height, atIndex: indexPath.item)
            self.flowLayout.invalidateLayout()
        }

        return result
    }

    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        cell.isHidden = false
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {

        let allowedY = self.flowLayout.getLimitingOffset()
        let deltaY = scrollView.contentOffset.y - allowedY
        if deltaY > 0 {
            let decayLimit: CGFloat = 3000
            let deltaYlimited = deltaY / (1.0 + deltaY / decayLimit)

            scrollView.contentOffset = CGPoint(x: scrollView.contentOffset.x, y: allowedY + deltaYlimited)
            printLog(log: "=== didScroll limits Y by lastCardAllowed to \(allowedY) delta=\(deltaY), \(deltaYlimited)")
        }
        self.delegate?.didScroll?(VerticalCarouselView: self.verticalCarouselView)
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            delegate?.didEndScroll?(VerticalCarouselView: verticalCarouselView)
        }
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        delegate?.didEndScroll?(VerticalCarouselView: verticalCarouselView)
    }

    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        delegate?.didEndScroll?(VerticalCarouselView: verticalCarouselView)
    }

    fileprivate func setupVerticalCarouselView() {
        verticalCarouselView = VerticalCarouselView(frame: self.frame, collectionViewLayout: flowLayout)
       // VerticalCarouselView.decelerationRate = UIScrollView.decelerationRate.fast
        verticalCarouselView.backgroundColor = UIColor.clear
        verticalCarouselView.showsVerticalScrollIndicator = false
        verticalCarouselView.delegate = self
        //verticalCarouselView.dataSource = self
        self.addSubview(verticalCarouselView)
    }

    fileprivate func setupConstraints() {
        verticalCarouselView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.verticalCarouselView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.verticalCarouselView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            self.verticalCarouselView.topAnchor.constraint(equalTo: self.topAnchor),
            self.verticalCarouselView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
            ])
    }

    fileprivate func setCardSwiperInsets() {
        let bottomInset = visibleNextCardHeight + flowLayout.minimumLineSpacing
        verticalCarouselView.contentInset = UIEdgeInsets(top: topInset, left: sideInset, bottom: bottomInset, right: sideInset)
        flowLayout.topInset = topInset
        flowLayout.visibleNextCardHeight = visibleNextCardHeight
        flowLayout.cardSpacing = cardSpacing
    }
}

extension VerticalCarousel: UICollectionViewDelegateFlowLayout {

	public func resetHeights(count: Int, defaultValue: HeightsPair = VerticalCarouselDefaults.heights) {

        let dif = count - self.flowLayout.cellHeights.count
        if dif > 0 {
            self.flowLayout.cellHeights.append(contentsOf: Array(repeating: defaultValue, count: dif))
        }
    }

    public func updateCellHeight(height: HeightsPair, atIndex index: Int) {

        // set cellHeight in the custom flowlayout, we use this for paging calculations.
        //flowLayout.cellHeight = height
        printLog(log: "=== Card \(index) set new heights pair: actual=\(height.actual) max=\(height.max). Contraints will apply.")
        let yInsets = cardSpacing + topInset + visibleNextCardHeight
		let fixedHieght: HeightsPair = HeightsPair( height.actual, max(height.actual, height.max))
        let newHeight = max(fixedHieght.max, verticalCarouselView.frame.size.height - yInsets)
        let newActualHeight = fixedHieght.actual > 0 ?  min(newHeight, fixedHieght.actual) : newHeight

        let page = self.flowLayout.currentPage()
        let yBefore = self.flowLayout.getOffsetForPage(page: page )

        // store heights
        self.flowLayout.initDefaultHeights(index: index)

        let oldHeight = flowLayout.cellHeights[index].max
        flowLayout.cellHeights[index] = HeightsPair(actual: newActualHeight, max: newHeight)
        if abs(oldHeight - newHeight) > 1.0 {
            printLog(log: "=== Card \(index) set height from \(oldHeight) to \(newHeight). Current page is \(page) lastProposedY \(flowLayout.lastProposedY)")
        }
        let yAfter = self.flowLayout.getOffsetForPage(page: page)
        let delta = yAfter - yBefore

        if abs(delta) > 1.0 {
            printLog(log: "=== Update cell height at \(index): Shift current pos \(delta) pixels down ")
            //self.flowLayout.invalidateLayout()  //needed?
            let y = verticalCarouselView.contentOffset.y + delta
            let point = CGPoint(x: verticalCarouselView.contentOffset.x, y: y)
            verticalCarouselView.setContentOffset(point, animated: false)
            flowLayout.lastProposedY += delta
            printLog(log: "=== Position set to y=\(y) ")
            if delta < 0 {
                printLog(log: "=== Decreasing height at pos \(index) by \(-delta) pixels ")
            }
        //    self.flowLayout.invalidateLayout()  //needed?
        }
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        let index = indexPath.row

        let itemSize = calculateItemSize(for: index)

        //let actualHeight = calculateActualItemHeight(for: index)

        //self.updateCellHeight(height: HeightsPair(actual: actualHeight, max: itemSize.height), atIndex: index)

        return itemSize
    }

    fileprivate func calculateItemSize(for index: Int) -> CGSize {

        var cellWidth: CGFloat = 0
        var cellHeight: CGFloat = 0
        let xInsets = sideInset * 2
        let yInsets = cardSpacing + topInset + visibleNextCardHeight

        if  let customHeight = self.flowLayout.cellHeights[safe: index], customHeight.max > 0 {
            // set custom sizes and make sure sizes are not negative, if they are, don't subtract the insets.
            cellWidth = verticalCarouselView.frame.size.width - xInsets
            cellHeight = customHeight.max
        } else {
            cellWidth = verticalCarouselView.frame.size.width - xInsets
            cellHeight = verticalCarouselView.frame.size.height - yInsets
            //print ("Card \(index) default \(cellWidth)x\(cellWidth) ")
        }

        return CGSize(width: cellWidth, height: cellHeight)
    }

    fileprivate func calculateActualItemHeight(for index: Int) -> CGFloat {
        var cellHeight: CGFloat = 0
        if  let customHeight = self.flowLayout.cellHeights[safe: index], customHeight.actual > 0 {
            cellHeight = customHeight.actual
        } else {
            cellHeight = calculateItemSize(for: index).height
        }
        return cellHeight
    }

    public func scrollOneCellBackward() {
        let newIndex = self.currentCardIndex - 1
        let oldIndex = self.currentCardIndex
        if newIndex >= 0 {
            self.scrollToCard(at: newIndex, animated: true)
            self.verticalCarouselView.currentCardChanged?(oldIndex, newIndex)
        }
    }

    public func scrollOneCellForward() {
        let maxIndex = self.verticalCarouselView.numberOfItems(inSection: 0) - 1
        let newIndex = self.currentCardIndex + 1
        let oldIndex = self.currentCardIndex
        if newIndex <= maxIndex {
            self.scrollToCard(at: newIndex, animated: true)
            self.verticalCarouselView.currentCardChanged?(oldIndex, newIndex)
        }
    }

}

extension Collection {
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
