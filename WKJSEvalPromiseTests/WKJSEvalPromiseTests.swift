//
//  WKJSEvalPromiseTests.swift
//  WKJSEvalPromiseTests
//
//  Created by Ahmed Khalaf on 12/24/18.
//  Copyright © 2018 Ahmed Khalaf. All rights reserved.
//

import XCTest
@testable import WKJSEvalPromise

enum MockError: Error {
    case mock
}

class JSEvaluatorMockErrorThrower: JSEvaluator {
    func evaluateJavaScript(_ javaScriptString: String, completionHandler: ((Any?, Error?) -> Void)?) {
        completionHandler!(nil, MockError.mock)
    }
}

class JSEvaluatorMockSlow: JSEvaluator {
    var queue = DispatchQueue(label: "JSEvaluatorMock")
    
    func evaluateJavaScript(_ javaScriptString: String, completionHandler: ((Any?, Error?) -> Void)?) {
        queue.async {
            sleep(UInt32.random(in: 0...5))
            completionHandler!(javaScriptString, nil)
        }
    }
}

class JSEvaluatorMockFast: JSEvaluator {
    
    func evaluateJavaScript(_ javaScriptString: String, completionHandler: ((Any?, Error?) -> Void)?) {
        completionHandler!(javaScriptString, nil)
    }
}



class WKJSEvalPromiseTests: XCTestCase {

    func testSerializingLongExecution() {
        
        let jsEvaluator = JSEvaluatorMockSlow()
        
        var count = 3
        
        WKJSEvalPromise.firstly(jsEvaluator: jsEvaluator) { () -> String in
            return "f1()"
        }
        .then { (result) -> String in
            XCTAssertEqual(result as! String, "f1()")
            
            count -= 1
            XCTAssertEqual(count, 2)
            
            return "f2()"
        }
        .then { (result) -> String in
            XCTAssertEqual(result as! String, "f2()")
            
            count -= 1
            XCTAssertEqual(count, 1)
            
            return "f3()"
        }
        .finally { (result) in
            XCTAssertEqual(result as! String, "f3()")
            
            count -= 1
        }
        
        // Wait for every async call; not just one.
        jsEvaluator.queue.sync {}
        jsEvaluator.queue.sync {}
        jsEvaluator.queue.sync {}
        
        XCTAssertEqual(count, 0)
    }
    
    func testSerializingQuickExecution() {
        
        let jsEvaluator = JSEvaluatorMockFast()
        
        var count = 3
        
        WKJSEvalPromise.firstly(jsEvaluator: jsEvaluator) { () -> String in
            return "f1()"
        }
        .then { (result) -> String in
            XCTAssertEqual(result as! String, "f1()")
                
            count -= 1
            XCTAssertEqual(count, 2)
                
            return "f2()"
        }
        .then { (result) -> String in
            XCTAssertEqual(result as! String, "f2()")
                
            count -= 1
            XCTAssertEqual(count, 1)
                
            return "f3()"
        }
        .finally { (result) in
            XCTAssertEqual(result as! String, "f3()")
                
            count -= 1
        }
        
        XCTAssertEqual(count, 0)
    }
    
    func testCatchAtEnd() {
        
        let jsEvaluator = JSEvaluatorMockErrorThrower()
        
        var expectedError: Error? = nil
        
        WKJSEvalPromise.firstly(jsEvaluator: jsEvaluator) { () -> String in
            return "f1()"
        }
        .catch { (error) in
            expectedError = error
        }.finally {
                
        }
        
        XCTAssertNotNil(expectedError)
        XCTAssert(expectedError is MockError)
    }
}
