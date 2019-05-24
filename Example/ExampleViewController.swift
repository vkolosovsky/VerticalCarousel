import UIKit
import VerticalCarousel

class ExampleViewController: UIViewController, VerticalCarouselDelegate, VerticalCarouselDatasource {

    @IBOutlet private var cardSwiper: VerticalCarousel!

    private var lastNumAllowed: Int = 0

    private var markdowns: [String] = [
    """
    CARD -1
    ============
    * this one
    * that one
    * the other one
    """,
    """
    CARD 0
    ============

    Paragraphs are separated by a blank line.

    2nd paragraph. *Italic*, **bold**, and `monospace`. Itemized lists
    look like:

    * this one
    * that one
    * the other one

    Note that --- not considering the asterisk --- the actual text
    content starts at 4-columns in.

    > Block quotes are
    > written like so.
    >
    > They can span multiple paragraphs,
    > if you like.

    Use 3 dashes for an em-dash. Use 2 dashes for ranges (ex., "it's all
    in chapters 12--14"). Three dots ... will be converted to an ellipsis.
    Unicode is supported. ☺
     this
     is
     some
     long
     long
     text
    """
    ,
    """
    CARD 1 Video
    ------------
    <video width="320" height="240" controls>
    <source src="https://www.w3schools.com/html/mov_bbb.mp4" type="video/mp4">
    Your browser does not support the video tag.
    </video>
    """,
    """
    player
    """,
    """
    CARD 1B Audio
    ------------
    <audio controls>
    <source src="https://sample-videos.com/audio/mp3/crowd-cheering.mp3" type="audio/mpeg">
    Your browser does not support the audio element.
    </audio>
    """,
    """
    CARD2
    Note again how the actual text starts at 4 columns in (4 characters
    from the left side). Here's a code sample:

        # Let me re-iterate ...
        for i in 1 .. 10 { do-something(i) }

    As you probably guessed, indented 4 spaces. By the way, instead of
    indenting the block, you can use delimited blocks, if you like:

    ~~~
    define foobar() {
        print "Welcome to flavor country!";
    }
    ~~~

    (which makes copying & pasting easier). You can optionally mark the
    delimited block for Pandoc to syntax highlight it:

    ~~~python
    import time
    # Quick, count to ten!
    for i in range(10):
        # (but not *too* quick)
        time.sleep(0.5)
        print(i)
    ~~~
    """,
    """
    CARD 3

    Now a nested list:

     1. First, get these ingredients:

          * carrots
          * celery
          * lentils

     2. Boil some water.

     3. Dump everything in the pot and follow
        this algorithm:

            find wooden spoon
            uncover pot
            stir
            cover pot
            balance wooden spoon precariously on pot handle
            wait 10 minutes
            goto first step (or shut off burner when done)

        Do not bump wooden spoon or it will fall.
    """,
    """
    CARD 4
    Notice again how text always lines up on 4-space indents (including
    that last line which continues item 3 above).

    Here's a link to [a website](http://foo.bar), to a [local
    doc](local-doc.html), and to a [section heading in the current
    doc](#an-h2-header). Here's a footnote [^1].

    [^1]: Some footnote text.

    Tables can look like this:

    Name           Size  Material      Color
    ------------- -----  ------------  ------------
    All Business      9  leather       brown
    Roundabout       10  hemp canvas   natural
    Cinderella       11  glass         transparent
    """,
    """
    CARD 5
        and images can be specified like so:

        ![example image](example-image.jpg "An exemplary image")
    0
    1
    2
    3
    4
    5
    6
    """,
    """
    CARD 6
      Short Card
    0
    1
    2
    """,
    """
    CARD 7
      A bit longer card
    0
    1
    2
    3
    4
    5
    6
    """
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        cardSwiper.delegate = self
        cardSwiper.datasource = self
        cardSwiper.register(ContentCardCell.self, forCellWithReuseIdentifier: "ContentCardCell")
    }

    @IBAction func pressRemoveCards(_ sender: UIBarButtonItem) {
        if lastNumAllowed > 0 {
            lastNumAllowed -= 1
            cardSwiper.setLastCardAllowed(number: lastNumAllowed)
        }
    }

    @IBAction func pressAddCards(_ sender: UIBarButtonItem) {
        lastNumAllowed += 1
        cardSwiper.setLastCardAllowed(number: lastNumAllowed)
    }

    @IBAction func pressScrollUp(_ sender: UIBarButtonItem) {
        let currentIndex = cardSwiper.currentCardIndex
        cardSwiper.scrollToCard(at: currentIndex - 1, animated: true)
    }

    @IBAction func pressScrollDown(_ sender: UIBarButtonItem) {
        let currentIndex = cardSwiper.currentCardIndex
        cardSwiper.scrollToCard(at: currentIndex + 1, animated: true)
    }

    func cardForItemAt(VerticalCarouselView: VerticalCarouselView, cardForItemAt index: Int) -> VerticalCardCell {

        if let cardCell = VerticalCarouselView
            .dequeueReusableCell(withReuseIdentifier: "ContentCardCell", for: index) as? ContentCardCell {
            cardCell.parent = VerticalCarouselView
            let markdown = markdowns[index]

            cardCell.setupWithModel(markdown: markdown)
            return cardCell
        }
        return VerticalCardCell()
    }

    func numberOfCards(VerticalCarouselView: VerticalCarouselView) -> Int {
        return markdowns.count
    }
    
}
