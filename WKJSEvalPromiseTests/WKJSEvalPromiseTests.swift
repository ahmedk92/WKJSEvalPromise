//
//  WKJSEvalPromiseTests.swift
//  WKJSEvalPromiseTests
//
//  Created by Ahmed Khalaf on 12/24/18.
//  Copyright © 2018 Ahmed Khalaf. All rights reserved.
//

import XCTest
@testable import WKJSEvalPromise
import WebKit

let html = """
    <html>
        <head>
            <script>
                function f1() {
                    for (var i = 0; i < 1000000000; i++) {}
                    return "f1";
                }
                function f2() {
                    for (var i = 0; i < 1000000000; i++) {}
                    return "f2";
                }
                function f3() {
                    for (var i = 0; i < 1000000000; i++) {}
                    return "f3";
                }
            </script>
        </head>
        <body>
        </body>
    </html>
"""

class WKJSEvalPromiseTests: XCTestCase {
    
    private var webView: WKWebView!

    override func setUp() {
        webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
    }

    override func tearDown() {
        webView = nil
    }

    func testSerializingLongExecution() {
        webView.loadHTMLString(html, baseURL: nil)
        
        let expectation_ = expectation(description: "Serialized Callbacks")

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            WKJSEvalPromise.firstly(webView: self.webView) { () -> String in
                return "f1()"
                }
                .then({ (result, error) -> String in
                    XCTAssertEqual(result as! String, "f1")
                    return "f2()"
                })
                .then({ (result, error) -> String in
                    XCTAssertEqual(result as! String, "f2")
                    return "f3()"
                })
                .finally { (result, error) in
                    XCTAssertEqual(result as! String, "f3")
                    
                    expectation_.fulfill()
            }

        }
        
        waitForExpectations(timeout: 20) { (error) in
            if let error = error {
                print(error)
            }
        }
    }
}
