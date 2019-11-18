import UIKit
import WebKit

/**
 Markdown View for iOS.
 
 - Note: [How to get height of entire document with javascript](https://stackoverflow.com/questions/1145850/how-to-get-height-of-entire-document-with-javascript)
 */
open class MarkdownView: UIView {

  open var webView: WKWebView?

  fileprivate var intrinsicContentHeight: CGFloat? {
    didSet {
      self.invalidateIntrinsicContentSize()
    }
  }

  public var isScrollEnabled: Bool = true {

    didSet {
      webView?.scrollView.isScrollEnabled = isScrollEnabled
    }

  }

  public var onTouchLink: ((URLRequest) -> Bool)?

  public var onRendered: ((CGFloat) -> Void)?

  public convenience init() {
    self.init(frame: CGRect.zero)
  }

  override init (frame: CGRect) {
    super.init(frame: frame)
  }

  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  open override var intrinsicContentSize: CGSize {
    if let height = self.intrinsicContentHeight {
        return CGSize(width: UIView.noIntrinsicMetric, height: height)
    } else {
      return CGSize.zero
    }
  }

    var applyDirtyHack = true
    public func load(markdown: String?, applyDirtyHack: Bool = true, enableImage: Bool = true) {
    guard let markdown = markdown else { return }
    self.applyDirtyHack = applyDirtyHack
    self.webView?.stopLoading()
    self.webView?.removeFromSuperview()
    self.webView = nil

    let bundle = Bundle(for: MarkdownView.self)

    let htmlURL: URL? =
      bundle.url(forResource: "index",
                 withExtension: "html") ??
      bundle.url(forResource: "index",
                 withExtension: "html",
                 subdirectory: "MarkdownView.bundle")

    DispatchQueue.delayOnMain(0.1) {
        if let url = htmlURL {
            let templateRequest = URLRequest(url: url)
            let escapedMarkdown = self.escape(markdown: markdown) ?? ""
            let imageOption = enableImage ? "true" : "false"
            let script = "window.showMarkdown('\(escapedMarkdown)', \(imageOption));"
            let userScript = WKUserScript(source: script, injectionTime: .atDocumentEnd, forMainFrameOnly: true)

            let controller = WKUserContentController()
            controller.addUserScript(userScript)

            let configuration = WKWebViewConfiguration()
            configuration.userContentController = controller
            let rect = applyDirtyHack ? CGRect(x: 0, y: 0, width: self.bounds.width, height: 100) : self.bounds
            let wv = WKWebView(frame: rect, configuration: configuration)
            wv.scrollView.isScrollEnabled = self.isScrollEnabled
            wv.scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            wv.translatesAutoresizingMaskIntoConstraints = false
            wv.navigationDelegate = self
            self.addSubview(wv)

            if !applyDirtyHack {
                wv.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
                wv.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
                wv.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
                wv.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
            }
            wv.backgroundColor = self.backgroundColor

            self.webView = wv

            wv.load(templateRequest)
        }
    }
  }

  private func escape(markdown: String) -> String? {
    return markdown.addingPercentEncoding(withAllowedCharacters: CharacterSet.alphanumerics)
  }

}

extension MarkdownView: WKNavigationDelegate {

  public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {

    guard self.webView == webView else { return }
    let script = "document.body.scrollHeight;"
    webView.evaluateJavaScript(script) { [weak self] result, error in
      if error != nil { return }
      guard let strongSelf = self else { return }
      if strongSelf.applyDirtyHack && webView.superview == strongSelf {
            webView.topAnchor.constraint(equalTo: strongSelf.topAnchor).isActive = true
            webView.bottomAnchor.constraint(equalTo: strongSelf.bottomAnchor).isActive = true
            webView.leadingAnchor.constraint(equalTo: strongSelf.leadingAnchor).isActive = true
            webView.trailingAnchor.constraint(equalTo: strongSelf.trailingAnchor).isActive = true
      }
      if let height = result as? CGFloat {
        self?.onRendered?(height)
        self?.intrinsicContentHeight = height
      }
    }
  }

  public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

    switch navigationAction.navigationType {
    case .linkActivated:
      if let onTouchLink = onTouchLink, onTouchLink(navigationAction.request) {
        decisionHandler(.allow)
      } else {
        decisionHandler(.cancel)
      }
    default:
      decisionHandler(.allow)
    }

  }

}

public extension DispatchQueue {
    fileprivate static var _onceTracker = [String]()

    /**
     Executes a block of code, associated with a unique token, only once.  The code is thread safe and will
     only execute the code once even in the presence of multithreaded calls.

     - parameter token: A unique reverse DNS style name such as com.vectorform.<name> or a GUID
     - parameter block: Block to execute once
     */
    class func once(token: String, block:() -> Void) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        if _onceTracker.contains(token) {
            return
        }

        _onceTracker.append(token)
        block()
    }

    class func once(_ file: String = #file, function: String = #function, line: Int = #line, block:() -> Void) {
        let token = file + ":" + function + ":" + String(line)
        once(token: token, block: block)
    }

    class func delayOnMain(_ delay: Double, closure:@escaping () -> Void) {
        let when = DispatchTime.now() + delay
        DispatchQueue.main.asyncAfter(deadline: when, execute: closure)
    }

    class func delayOnGlobal(_ delay: Double, closure:@escaping () -> Void) {
        let when = DispatchTime.now() + delay
        DispatchQueue.global().asyncAfter(deadline: when) {
            DispatchQueue.main.sync(execute: closure)
        }
    }
}
