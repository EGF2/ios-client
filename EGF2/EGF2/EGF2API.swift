//
//  EGF2API.swift
//  EGF2
//
//  Created by LuzanovRoman on 02.11.16.
//  Copyright © 2016 EigenGraph. All rights reserved.
//

import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case put = "PUT"
    case post = "POST"
    case delete = "DELETE"
}

class EGF2API {
    var authorization: String?
    var serverURL: URL? {
        didSet {
            if let string = serverURL?.absoluteString, string.characters.count > 1, string.characters.last != "/" {
                serverURL = serverURL?.appendingPathComponent("/")
            }
        }
    }
    
    fileprivate lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = nil
        configuration.httpCookieStorage = nil
        return URLSession(configuration: configuration)
    }()
    
    fileprivate func string(byParameters parameters: [String: Any]) -> String {
        return parameters
            .map{"\($0)=\($1)&"}
            .joined(separator: "")
            .withoutLastCharacter()
    }
    
    func execute(withLocalURL localURL: String, method: HTTPMethod, parameters: [String: Any]?, completion: Completion?) {
        
        guard let url = serverURL, let urlComponents = NSURLComponents(string: url.absoluteString + localURL) else {
            print("Error in EGF2API. serverURL must be set.")
            completion?(false, nil)
            return
        }
        if let params = parameters {
            if method == .get {
                urlComponents.query = string(byParameters: params)
            }
        }
        guard let fullURL = urlComponents.url else {
            print("EGF2API error. Can't configure full URL for request \(localURL)")
            completion?(false, nil)
            return
        }
        let request = NSMutableURLRequest(url: fullURL)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let value = authorization {
            request.setValue(value, forHTTPHeaderField: "Authorization")
        }
        if method != .get {
            if let jsonObject = parameters, let data = Data(jsonObject: jsonObject) {
                request.setValue("\(data.count)", forHTTPHeaderField: "Content-Length")
                request.httpBody = data
            }
        }
        execute(withRequest: request as URLRequest, completion: completion)
    }
    
    func execute(withRequest request: URLRequest, completion: Completion?) {
        
        session.dataTask(with: request) { (aData, aResponse, aError) in
            var result: [String: Any]? = nil
            var error: NSError? = nil
            
            if let value = aError {
                error = value as NSError?
            }
            else if let response = aResponse as? HTTPURLResponse, let data = aData {
                if response.statusCode == 200 || response.statusCode == 204 {
                    result = data.jsonObject() as? [String: Any]
                }
                else {
                    var userInfo: [String: Any] = ["status_code": response.statusCode]
                    
                    if let dictionary = data.jsonObject() as? [String: Any], let message = dictionary["message"] as? String {
                        userInfo[NSLocalizedFailureReasonErrorKey] = message
                    }
                    else {
                        userInfo[NSLocalizedFailureReasonErrorKey] = "Unknown error"
                    }
                    error = EGF2Error(code: .serverError, userInfo: userInfo)
                }
            }
            if let block = completion {
                DispatchQueue.main.async {
                    block(result, error)
                }
            }
        }.resume()
    }
}
