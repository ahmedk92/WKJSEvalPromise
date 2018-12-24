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
    
    private weak var jsEvaluator: JSEvaluator!
    private var action: () -> () = {}
    private var nextFuture: WKJSEvalPromise?
    private var result: Any?
    private var error: Error?
    private var finalCallback: EvalCallback?
    
    private init() {}
    
    class func firstly(jsEvaluator: JSEvaluator, callback: @escaping FirstCallback) -> WKJSEvalPromise {
        let promise = makePromise(jsEvaluator: jsEvaluator, js: callback())
        promise.action()
        
        return promise
    }
    
    func then(_ callback: @escaping EvalCallbackWithJSString) -> WKJSEvalPromise {
        let promise: WKJSEvalPromise = .makePromise(jsEvaluator: jsEvaluator, js: callback(self.result, self.error))
        
        nextFuture = promise
        
        return promise
    }
    
    private class func makePromise(jsEvaluator: JSEvaluator, js: @escaping @autoclosure () -> String) -> WKJSEvalPromise {
        let promise = WKJSEvalPromise()
        promise.jsEvaluator = jsEvaluator
        promise.action = {
            jsEvaluator.evaluateJavaScript(js(), completionHandler: { (result, error) in
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

protocol JSEvaluator: class {
    func evaluateJavaScript(_ javaScriptString: String, completionHandler: ((Any?, Error?) -> Void)?)
}

extension WKWebView: JSEvaluator {}
