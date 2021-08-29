//
//  Networking.swift
//  NetworkingFramework
//
//  Created by Golan Shoval Gil on 28/08/2021.
//

import Foundation

public class Networking: NSObject, URLSessionTaskDelegate {
    
    var request: URLRequest?
    var redirectLimit: Int? = nil
    var redirectReached = 0
    var response: [String: Any]?
    var session: URLSession?
    var multiRequestsDispatchGroup = DispatchGroup()
    
    public init(redirectLimit: Int?) {
        self.redirectLimit = redirectLimit
    }
    
    public func sendRequests(urls: String..., completionHandler: @escaping () -> Void) {
        for string in urls {
            if let url = URL(string: string) {
                multiRequestsDispatchGroup.enter()
                sendRequest(url: url) { response, error , statusCode in
                    self.multiRequestsDispatchGroup.leave()
                }
            }
        }
        
        multiRequestsDispatchGroup.notify(queue: DispatchQueue.main) {
            completionHandler()
        }
    }
    
    public func sendRequest(url: URL, completionHandler: @escaping (_ response: [String: Any]?, _ error: Error?, _ statusCode: Int?) -> Void) {
        
        request = URLRequest(url: url)
        self.session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)

        let task = session?.dataTask(with: request!) { (data, response, error) in
                        
            if error != nil {
                completionHandler(nil, error, nil)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                completionHandler(nil, error, httpResponse.statusCode)
                return
            }
            
            if let json = try? JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any] {
                self.response = json
                
                print(json)
                completionHandler(json, nil, nil)
                return
            }
        }
        
        task?.resume()
    }

    
    public func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
                
        if let redirectLimit = redirectLimit, redirectReached >= redirectLimit {
            completionHandler(nil)
        } else {
            completionHandler(request)
        }
        
        if redirectLimit != nil {
            redirectReached += 1
        }
    }
}
