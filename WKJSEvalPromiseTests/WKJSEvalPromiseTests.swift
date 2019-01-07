//
//  WKJSEvalPromiseTests.swift
//  WKJSEvalPromiseTests
//
//  Created by Ahmed Khalaf on 12/24/18.
//  Copyright © 2018 Ahmed Khalaf. All rights reserved.
//

import XCTest
@testable import WKJSEvalPromise

class JSEvaluatorMock: JSEvaluator {
    var queue = DispatchQueue(label: "JSEvaluatorMock")
    
    func evaluateJavaScript(_ javaScriptString: String, completionHandler: ((Any?, Error?) -> Void)?) {
        queue.async {
            sleep(UInt32.random(in: 0...5))
            completionHandler!(javaScriptString, nil)
        }
    }
}


class WKJSEvalPromiseTests: XCTestCase {
    
    private var jsEvaluator: JSEvaluatorMock!

    override func setUp() {
        jsEvaluator = JSEvaluatorMock()
    }

    override func tearDown() {
        jsEvaluator = nil
    }

    func testSerializingLongExecution() {
        var count = 3
        
        WKJSEvalPromise.firstly(jsEvaluator: jsEvaluator) { () -> String in
            return "f1()"
        }
        .then { (result, error) -> String in
            XCTAssertEqual(result as! String, "f1()")
            
            count -= 1
            XCTAssertEqual(count, 2)
            
            return "f2()"
        }
        .then { (result, error) -> String in
            XCTAssertEqual(result as! String, "f2()")
            
            count -= 1
            XCTAssertEqual(count, 1)
            
            return "f3()"
        }
        .finally { (result, error) in
            XCTAssertEqual(result as! String, "f3()")
            
            count -= 1
        }
        
        // Wait for every async call; not just one.
        jsEvaluator.queue.sync {}
        jsEvaluator.queue.sync {}
        jsEvaluator.queue.sync {}
        
        XCTAssertEqual(count, 0)
    }
}
