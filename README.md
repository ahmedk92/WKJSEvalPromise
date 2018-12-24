# WKJSEvalPromise
Serialized evaluateJavaScript for WKWebView

## Usage
Instead of:
```swift
webView.evaluateJavaScript("f1()") { (result, error) in
        webView.evaluateJavaScript("f2()", completionHandler: { (result, error) in
            webView.evaluateJavaScript("f3()", completionHandler: { (result, error) in
        })
    })
}
```

What about?:

```swift
WKJSEvalPromise.firstly(jsEvaluator: webView) { () -> String in
    return "f1()"
}
.then({ (result, error) -> String in
    return "f2()"
})
.then({ (result, error) -> String in
    return "f3()"
})
.finally { (result, error) in
}
```

## Installation

Just drag `WKJSEvalPromise.swift` to your project.
