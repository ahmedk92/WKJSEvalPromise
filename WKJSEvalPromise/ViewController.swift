//
//  ViewController.swift
//  WKJSEvalPromise
//
//  Created by Ahmed Khalaf on 12/24/18.
//  Copyright © 2018 Ahmed Khalaf. All rights reserved.
//

import UIKit
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

class ViewController: UIViewController {
    
    @IBOutlet private weak var webView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        webView.navigationDelegate = self
        webView.loadHTMLString(html, baseURL: nil)
    }


}

extension ViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        WKJSEvalPromise.firstly(jsEvaluator: webView) {
            return "f1()"
        }
        .then { (result) -> String in
            print(result)
            return "null()"
        }
        .catch { (error) in
            print(error)
        }
        .then {
            return "f3()"
        }
        .finally { (result) in
            print(result)
        }
    }
}

