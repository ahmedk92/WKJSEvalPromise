//
//  WKJSEvalPromise.swift
//  WKJSEvalPromise
//
//  Created by Ahmed Khalaf on 12/24/18.
//  Copyright © 2018 Ahmed Khalaf. All rights reserved.
//

import WebKit

enum WKJSEvalPromiseError: Error {
    case noJSEvaluator
}

class WKJSEvalPromiseBase {
    typealias FirstCallback = () -> String
    typealias EvalCallback = (Any) -> ()
    typealias EvalCallbackWithJSString = (Any) -> String
    typealias CatchCallback = (Error) -> ()
    
    private enum State {
        case pending
        case fulfilled(Any)
        case rejected(Error)
    }
    
    private var state: State {
        if let result = result {
            return .fulfilled(result)
        } else if let error = error {
            return .rejected(error)
        }
        
        return .pending
    }
    
    fileprivate weak var jsEvaluator: JSEvaluator?
    fileprivate var nextFuture: WKJSEvalPromise?
    fileprivate var action: (() -> ())?
    fileprivate var result: Any?
    fileprivate var error: Error?
    fileprivate var finalCallback: EvalCallback?
    fileprivate var emptyFinalCallback: (() -> ())?
    fileprivate var catchCallback: CatchCallback?
    
    fileprivate init() {}
    
    fileprivate func resume() {
        switch state {
        case .fulfilled(let result):
            nextFuture?.action?()
            nextFuture?.action = nil
            
            finalCallback?(result)
        case .rejected(let error):
            catchCallback?(error)
            
            nextFuture?.action?()
            nextFuture?.action = nil
            
            emptyFinalCallback?()
        case .pending:
            break
        }
    }
    
    class func firstly(jsEvaluator: JSEvaluator, callback: @escaping FirstCallback) -> WKJSEvalPromise {
        let promise = WKJSEvalPromise.makePromise(jsEvaluator: jsEvaluator, js: callback())
        promise.action?()
        promise.action = nil
        
        return promise
    }
    
    func then(_ callback: @escaping FirstCallback) -> WKJSEvalPromise {
        let promise: WKJSEvalPromise = .makePromise(jsEvaluator: jsEvaluator, js: callback())
        
        nextFuture = promise
        resume() // If needed
        
        return promise
    }
    
    func finally(_ callback: @escaping () -> ()) {
        emptyFinalCallback = callback
        resume()
    }
}

class WKJSEvalPromise: WKJSEvalPromiseBase {
    
    func then(_ callback: @escaping EvalCallbackWithJSString) -> WKJSEvalPromise {
        let promise: WKJSEvalPromise = .makePromise(jsEvaluator: jsEvaluator, js: callback(self.result!))
        
        nextFuture = promise
        resume() // If needed
        
        return promise
    }
    
    func `catch`(_ callback: @escaping CatchCallback) -> WKJSEvalPromiseBase {
        
        catchCallback = callback
        resume()
        
        return self
    }
    
    fileprivate class func makePromise(jsEvaluator: JSEvaluator?, js: @escaping @autoclosure () -> String) -> WKJSEvalPromise {
        let promise = WKJSEvalPromise()
        promise.jsEvaluator = jsEvaluator
        promise.action = {
            guard let jsEvaluator = jsEvaluator else {
                promise.error = WKJSEvalPromiseError.noJSEvaluator
                promise.resume()
                return
            }
            jsEvaluator.evaluateJavaScript(js(), completionHandler: { (result, error) in
                promise.result = result
                promise.error = error
                promise.resume()
            })
        }
        
        return promise
    }
    
    @available(*, unavailable, message:"Child can't doThat")
    override func finally(_ callback: @escaping () -> ()) {
        super.finally(callback)
    }
    
    func finally(_ callback: @escaping EvalCallback) {
        finalCallback = callback
        resume()
    }
}

protocol JSEvaluator: class {
    func evaluateJavaScript(_ javaScriptString: String, completionHandler: ((Any?, Error?) -> Void)?)
}

extension WKWebView: JSEvaluator {}
