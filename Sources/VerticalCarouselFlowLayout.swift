import UIKit

public typealias HeightsPair = (actual: CGFloat, max: CGFloat)

public enum VerticalCarouselDefaults {
    static public var heights = HeightsPair(400.0, 400.0)
}

/// Custom `UICollectionViewFlowLayout` that provides the flowlayout information like paging and `VerticalCardCell` movements.
internal class VerticalCarouselFlowLayout: UICollectionViewFlowLayout {

    internal var cellHeights = [HeightsPair(0, 0)]
    internal var lastCardAllowed: Int = 0
    internal var frameHeight: CGFloat = 0
    internal var lastProposedY: CGFloat = 0
    internal var topInset: CGFloat = 0
    internal var cardSpacing: CGFloat = 0
    internal var visibleNextCardHeight: CGFloat = 20
    internal var pagingLimitHeight: CGFloat = 120

    internal override func prepare() {
        super.prepare()

        assert(collectionView?.numberOfSections == 1, "Number of sections should always be 1.")
        assert(collectionView?.isPagingEnabled == false, "Paging on the collectionview itself should never be enabled. To enable cell paging, use the isPagingEnabled property of the VerticalCarouselFlowLayout instead.")
    }

    public func setLastCardAllowed(number: Int) {
        lastCardAllowed = number
    }

    public func setFrameHeight(height: CGFloat) {
        frameHeight = height
    }

    public func getRefHeight() -> CGFloat {
        return frameHeight - topInset - visibleNextCardHeight - cardSpacing
    }

    internal override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {

        let items = NSArray(array: super.layoutAttributesForElements(in: rect)!, copyItems: true)

        for object in items {
            if let attributes = object as? UICollectionViewLayoutAttributes {
                self.updateCellAttributes(attributes)
            }
        }
        return items as? [UICollectionViewLayoutAttributes]
    }

    internal override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {

        if self.collectionView?.numberOfItems(inSection: 0) == 0 { return nil }

        if let attr = super.layoutAttributesForItem(at: indexPath)?.copy() as? UICollectionViewLayoutAttributes {
            self.updateCellAttributes(attr)
            return attr
        }
        return nil
    }

    internal override func finalLayoutAttributesForDisappearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        // attributes for swiping card away
        return self.layoutAttributesForItem(at: itemIndexPath)
    }

    internal override func initialLayoutAttributesForAppearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        // attributes for adding card
        return self.layoutAttributesForItem(at: itemIndexPath)
    }

    // We invalidate the layout when a "bounds change" happens, for example when we scale the top cell. This forces a layout update on the flowlayout.
    internal override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }

    // Cell paging
    public func getPageFromOffset(offset: CGFloat) -> Int {
        var remainHeight = offset + topInset
        var page = 0
        while page < cellHeights.count {
            remainHeight -= max(1.0, cellHeights[page].max)
            remainHeight -= self.minimumLineSpacing
            if remainHeight < -0.01 {
                break
            }
            page += 1
        }
        return page
    }

    public func getOffsetForPage(page: Int) -> CGFloat {
        let num = page < cellHeights.count ? page: cellHeights.count
        let trimHeights = cellHeights[..<num]
        let offset = trimHeights.map {$0.max}.reduce(0, +)
        return offset + CGFloat(num) * self.minimumLineSpacing - topInset
    }

    public func getLimitingOffsetForPage(page: Int) -> CGFloat {
        let nextPage = 1 + page
        let num = nextPage < cellHeights.count ? nextPage: cellHeights.count
        let trimHeights = cellHeights[..<num]
        let bottomPoint = trimHeights.map {$0.max}.reduce(0, +) + CGFloat(num) * self.minimumLineSpacing + visibleNextCardHeight
        var topPoint = bottomPoint - frameHeight
        if topPoint < 0 {
            topPoint = 0
        }
        return topPoint
    }

    public func getLimitingOffsetForLastPage(page: Int) -> CGFloat {
        let nextPage = 1 + page
        let num = nextPage < cellHeights.count ? nextPage: cellHeights.count
        let trimHeights = cellHeights[..<num]
        let bottomPoint = trimHeights.map {$0.max}.reduce(0, +) + CGFloat(num) * self.minimumLineSpacing
        var topPoint = bottomPoint - frameHeight
        if topPoint < 0 {
            topPoint = 0
        }
        return topPoint
    }

    public func getLimitingOffset() -> CGFloat {
        // For last card we call getLimitingOffsetForLastPage, it leaves no extra space.
        // This may break scrolling to next card if cellHeights not initialized in advance
        // return lastCardAllowed >= cellHeights.count - 1 ?  getLimitingOffsetForLastPage(page: cellHeights.count - 1): getLimitingOffsetForPage(page: lastCardAllowed)
        // This always leaves space for next card even if it never existed
        return getLimitingOffsetForPage(page: min(lastCardAllowed, cellHeights.count - 1))
    }

    internal override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {

        let proposedOffset = proposedContentOffset
        guard self.collectionView != nil else {
            return proposedOffset
        }

        let currentPage = getPageFromOffset(offset: lastProposedY)

        var proposedY: CGFloat = proposedOffset.y  + 0.4 * velocity.y
        let proposedYnoV: CGFloat = proposedOffset.y
        printLog(log: "=== ProposedContentOffset \(proposedY)")

        var proposedPage = getPageFromOffset(offset: proposedY)
        printLog(log: "=== PAGING proposed page \(proposedPage) from \(currentPage), y \(proposedY) from \(lastProposedY)")
        printLog(log: "=== Cells are \(cellHeights) ")

        applyCoarsePagingRestrictions(currentPage: currentPage, proposedPage: &proposedPage, proposedY: &proposedY)

        applyFinePagingRestrictions(proposedPage: proposedPage, currentPage: currentPage, proposedYnoV: proposedYnoV, velocity: velocity, proposedY: &proposedY)

//        let maxY = getLimitingOffset()

//        if proposedY > maxY {
//            proposedY = maxY
//            printLog(log: "=== Limiting Y by lastCardAllowed to \(maxY) for page \(lastCardAllowed)")
//        } else {
//            printLog(log: "=== Limiting Y by lastCardAllowed is not applied; while it is \(maxY) for page \(lastCardAllowed)")
//        }

        proposedPage = getPageFromOffset(offset: proposedY)
        printLog(log: "=== Final page will be \(proposedPage) at \(proposedY)")

        if proposedPage != currentPage {
            let cardSwiper = self.collectionView as? VerticalCarouselView
            cardSwiper?.currentCardChanged?(currentPage, proposedPage)
            printLog(log: "=== Changing page from \(currentPage) to \(proposedPage)")
        }
        lastProposedY = proposedY
        printLog(log: "=== TargetContentOffset \(proposedY)")
        return CGPoint(x: proposedContentOffset.x, y: proposedY)
    }

    private func applyFinePagingRestrictions(proposedPage: Int, currentPage: Int, proposedYnoV: CGFloat, velocity: CGPoint, proposedY: inout CGFloat) {
        let nextProposedPageOffset = getOffsetForPage(page: proposedPage + 1)

        if proposedPage < currentPage {
            let pageLimit = getOffsetForPage(page: currentPage)
            printLog(log: "=== UP pageLimit=\(pageLimit), proposedY=\(proposedY)")
            if proposedY > pageLimit  - pagingLimitHeight {
                proposedY = nextProposedPageOffset //no scroll up
                printLog(log: "=== Proposal changed to y=\(proposedY) [no scroll up]")
            } else {
                let proposedPageOffset = getLimitingOffsetForPage(page: proposedPage)
                proposedY = min(proposedY, proposedPageOffset)
                printLog(log: "=== Proposal changed to y=\(proposedY) [previous page]")
            }
        } else {
            let pageLimit = getLimitingOffsetForPage(page: currentPage)
            if currentPage < cellHeights.count - 1 {
                printLog(log: "=== DOWN pageLimit=\(pageLimit), proposedY=\(proposedY)")
                let proposedYl = min(proposedY, proposedYnoV)
                if currentPage <= proposedPage, pageLimit + pagingLimitHeight < proposedYl {

                    let nextCardWasVisible = pageLimit - visibleNextCardHeight - cardSpacing < lastProposedY
                    if  nextCardWasVisible || abs(velocity.y) < 0.1 { //start from near the end of page
                        proposedY = getOffsetForPage(page: currentPage + 1) //current page ended, go to next page
                        printLog(log: "=== Proposal changed to y=\(proposedY) [next page]")
                        printLog(log: "=== v=\(velocity.y)")
                    } else {
                        proposedY = pageLimit //end of current page
                        printLog(log: "=== Proposal changed to y=\(proposedY) [no next page because start not from end; limit=\(pageLimit) newY=\(proposedYl) lastY=\(lastProposedY)]")
                    }
                } else if currentPage == proposedPage, pageLimit < proposedY {
                    proposedY = pageLimit
                    printLog(log: "=== Proposal changed to y=\(proposedY) [no scroll down, stay on current page]")
                }
            }
        }
    }

    private func applyCoarsePagingRestrictions(currentPage: Int, proposedPage: inout Int, proposedY: inout CGFloat) {
        if proposedPage < currentPage - 1 {// we go back too far
            proposedPage = currentPage - 1
            proposedY = getOffsetForPage(page: proposedPage)
            printLog(log: "=== Proposal changed to page=\(proposedPage), y=\(proposedY) ")
        }

        if proposedPage > currentPage {// we go down too far //was + 1 for more free scrolling
            printLog(log: "=== We go too far down page \(proposedPage) from \(currentPage) (\(lastProposedY)) to (\(proposedY)) ")
            proposedPage = min (currentPage + 1, cellHeights.count - 1)
            proposedY = getOffsetForPage(page: proposedPage)
            //proposedY = max (proposedY, proposedY + cellHeights[proposedPage] - frameHeight - 1) //go to end of card
            //proposedY = max (proposedY, getLimitingOffsetForPage(page: proposedPage) - 1) //go to end of card and make next show up
            printLog(log: "=== Proposal changed to page=\(proposedPage), y=\(proposedY) ")
        }
    }

    func currentPage() -> Int {
        let currentPage = getPageFromOffset(offset: lastProposedY)
        return currentPage
    }

    /**
     Updates the attributes.
     Here manipulate positions of the cards here, calculate the positions and do the animations.

     - parameter attributes: The attributes we're updating.
     */
    fileprivate func updateCellAttributes(_ attributes: UICollectionViewLayoutAttributes) {

        guard let collectionView = collectionView else { return }

        let cvMinY = collectionView.bounds.minY
        let cardMinY = attributes.frame.minY
        let origin = attributes.frame.origin
        let cardHeight = attributes.frame.height
        printLog(log: "I== index=\(attributes.indexPath.item) cvMinY=\(cvMinY) cardMinY=\(cardMinY) cardHeight=\(cardHeight) origin=\(origin)" )
        printLog(log: "F== frame=\(attributes.frame) bounds=\(attributes.bounds) size=\(attributes.size) isHidden=\(attributes.isHidden)")

        if let cell = collectionView.cellForItem(at: attributes.indexPath) {
            printLog(log: "V== isHidden=\(cell.isHidden) index=\(attributes.indexPath.item), \(collectionView.indexPathsForVisibleItems)")
        }

        let offsetFromTop = cardMinY - cvMinY
        let relativeOffsetFromTop = offsetFromTop / (frameHeight > 40.0 ? frameHeight : 40.0) // avoid divide by 0

        let relativeLimit: CGFloat = 0.5 // Relative position on screen on screen where scale of bottom card starts
        let realtiveDecreaseFactor: CGFloat = 0.2 //(0..1) the greater it is the more the card is squashed
        let goUpDescaleParam: CGFloat = 0.2 //(0 .. 1) The greater this is the stronger card going up is descaled

        let rotationPointParam: CGFloat = 0.8

        attributes.zIndex = attributes.indexPath.item

        if relativeOffsetFromTop > relativeLimit {
            let t = calculateTransformForCardAppearingFromBottom(relativeOffsetFromTop: relativeOffsetFromTop,
                    relativeLimit: relativeLimit,
                    realtiveDecreaseFactor: realtiveDecreaseFactor,
                    cardHeight: cardHeight, attributes: attributes)
            attributes.transform = t
        } else {
            let bottomYDelta = cardMinY + cardHeight - cvMinY - frameHeight // Shows how much card bottom is elevated
            let delta = max(offsetFromTop, bottomYDelta)
            let actualCardHeight = cellHeights[attributes.indexPath.item].actual
            printLog(log: "Q== index=\(attributes.indexPath.item) ach=\(actualCardHeight) delta=\(delta) ")
            if delta < 0.0 {
                let t = calculateTransformForCardDisappearingToTop(actualCardHeight: actualCardHeight,
                        delta: delta,
                        cardHeight: cardHeight,
                        rotationPointParam: rotationPointParam,
                        goUpDescaleParam: goUpDescaleParam,
                        attributes: attributes)
                attributes.transform = t
            }
        }
    }

    private func calculateTransformForCardDisappearingToTop(actualCardHeight: CGFloat, delta: CGFloat, cardHeight: CGFloat, rotationPointParam: CGFloat, goUpDescaleParam: CGFloat, attributes: UICollectionViewLayoutAttributes) -> CGAffineTransform { // card goes up and away from screen
        var smallCardShift: CGFloat = 0
        var smalCardComp: CGFloat = 0
        let frameHeightRef = frameHeight - visibleNextCardHeight - cardSpacing // getRefHeight()

        if frameHeightRef > actualCardHeight {
            if -delta < (frameHeightRef - actualCardHeight) {
                smallCardShift = -delta
                //printLog(log: "Q== 1111 index=\(attributes.indexPath.item) fh=\(frameHeightRef) ach=\(actualCardHeight)")
            } else {
                smallCardShift = frameHeightRef - actualCardHeight
                smalCardComp = (frameHeightRef - actualCardHeight) + delta
                //printLog(log: "Q== 2222 index=\(attributes.indexPath.item) fh=\(frameHeightRef) ach=\(actualCardHeight)")
            }
        } else {
            //printLog(log: "Q== 3333 index=\(attributes.indexPath.item) fh=\(frameHeightRef) ach=\(actualCardHeight)")
        }

        let heightForCalc = min (frameHeight, cardHeight)
        let relativeOffset = delta / (heightForCalc > 40.0 ? heightForCalc : 40.0) // avoid divide by 0
        let ratio2 = min(1.0, max(0.0, -relativeOffset - rotationPointParam) / (1.0 - rotationPointParam))
        let scale = max(0.4, 1.0 - relativeOffset * relativeOffset * goUpDescaleParam)

        let deltaY = max(0.0, smallCardShift + cardHeight * (1.0-scale)/2.0 - 2.0 * cardSpacing * ratio2)
        var t = CGAffineTransform.identity
        t = t.scaledBy(x: scale, y: scale) // scale
        t = t.translatedBy(x: 0, y: deltaY)
        printLog(log: "Q== Calcs index=\(attributes.indexPath.item) delta=\(delta) comp=\(smalCardComp) ro=\(relativeOffset) r2=\(ratio2)")
        printLog(log: "Q== Final index=\(attributes.indexPath.item) fh=\(frameHeightRef) ach=\(actualCardHeight) scale=\(scale) deltaY=\(deltaY)")
        return t
    }

    private func calculateTransformForCardAppearingFromBottom(relativeOffsetFromTop: CGFloat, relativeLimit: CGFloat, realtiveDecreaseFactor: CGFloat, cardHeight: CGFloat, attributes: UICollectionViewLayoutAttributes) -> CGAffineTransform { // This scales down card coming from below
        let level = (relativeOffsetFromTop - relativeLimit)/(1.0 - relativeLimit) // 0 if no transform, 1 if maximum transform
        let scale = max(0.4, 1.0 - level * level * realtiveDecreaseFactor)
        var t = CGAffineTransform.identity
        t = t.scaledBy(x: scale, y: scale) // scale
        t = t.translatedBy(x: 0.0, y: cardHeight * (scale - 1.0)/2.0 ) // shift up so that top position is not affected by scale
        printLog(log: "B== index=\(attributes.indexPath.item) h=\(cardHeight) scale=\(scale)")
        return t
    }
}
