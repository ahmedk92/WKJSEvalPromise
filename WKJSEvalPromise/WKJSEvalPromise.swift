//
//  WKJSEvalPromise.swift
//  WKJSEvalPromise
//
//  Created by Ahmed Khalaf on 12/24/18.
//  Copyright © 2018 Ahmed Khalaf. All rights reserved.
//

import WebKit

class WKJSEvalPromise {
    typealias EvalCallback = (Any?, Error?) -> ()
    typealias EvalCallbackWithJSString = (Any?, Error?) -> String
    typealias FirstCallback = () -> String
    
    private weak var webView: WKWebView!
    private var action: () -> () = {}
    private var nextFuture: WKJSEvalPromise?
    private var result: Any?
    private var error: Error?
    private var finalCallback: EvalCallback?
    
    private init() {}
    
    class func firstly(webView: WKWebView, callback: @escaping FirstCallback) -> WKJSEvalPromise {
        let promise = makePromise(webView: webView, js: callback())
        promise.action()
        
        return promise
    }
    
    func then(_ callback: @escaping EvalCallbackWithJSString) -> WKJSEvalPromise {
        let promise: WKJSEvalPromise = .makePromise(webView: webView, js: callback(self.result, self.error))
        
        nextFuture = promise
        
        return promise
    }
    
    private class func makePromise(webView: WKWebView, js: @escaping @autoclosure () -> String) -> WKJSEvalPromise {
        let promise = WKJSEvalPromise()
        promise.webView = webView
        promise.action = {
            webView.evaluateJavaScript(js(), completionHandler: { (result, error) in
                promise.result = result
                promise.error = error
                promise.nextFuture?.action()
                promise.finalCallback?(result, error)
            })
        }
        
        return promise
    }
    
    func finally(_ callback: @escaping EvalCallback) {
        finalCallback = callback
    }
}
