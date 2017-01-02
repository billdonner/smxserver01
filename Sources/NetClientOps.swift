
///  provenance - SocialMaxx Server
/// builds on XCode 8.2 standard release on OSX 10.12
/// as of 2 Jan 2017
///

//
//  IGOps.swift
//  SocialMaxx
//
//  Created by bill donner on 1/18/16.
//  Copyright © 2016 SocialMax. All rights reserved.
//
import LoggerAPI
import KituraNet
import Foundation

/// Upper level interface to Instagram API Operations

let DataTaskGet = false  // set only on MAC OSX to use urlsessions
let DataTaskPut = false  // set only on MAC OSX to use urlsessions


struct NetClientOps {
    
    /// this is good for a one shot get to anywhere
    static func perform_get_request(schema: String, host:String, port:Int16, path:String,
                                    completion:@escaping (Int,Data?)->())
    {
        if DataTaskGet {
            let url_to_request = schema + "://" + host + ":" + "\(port)/\(path)"
            let session = URLSession.shared
            let url:URL = URL(string: url_to_request)!
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringCacheData
            
            let task = session.dataTask(with:request ) {
                ( data,   response,  error) in
                guard let data = data, error == nil else {
                    Log.error("perform_get_request completing with error \(error)")
                    completion((error! as NSError).code,nil)
                    return
                }
                completion(200,data)
                return
            }
            task.resume()
        } else {
            //not apple - use kitura synchronous method
            fetch(path, method: "GET", body: nil,schema:schema,host:host,port:port,completion:completion)
        }
    }
    /// this is good for a one shot post to anywhere
    static func perform_post_request(schema: String, host:String, port:Int16,  path:String, paramString: String, completion:@escaping (Int,Data?)->())
    {
        if DataTaskPut {
            let url_to_request = schema + "://" + host + ":" + "\(port)/\(path)"
            let session = URLSession.shared
            let url:URL = URL(string: url_to_request)!
            let request = NSMutableURLRequest(url: url)
            request.httpMethod = "POST"
            request.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringCacheData
            request.httpBody = paramString.data(using: String.Encoding.utf8)
            
            let task = session.dataTask(with:request as URLRequest) {
                ( data,   response,  error) in
                guard let data = data, error == nil else {
                    
                    Log.error("perform_post_request completing with error \(error)")
                    completion((error! as NSError).code,nil)
                    return
                }
                // Log.error("Good post response \(response)")
                completion(200,data)
                return
            }
            task.resume()
        }
        else {
            // not apple - use kitur synchronous method, including post parameters
            
            fetch(path, method: "POST", body: paramString.data(using: String.Encoding.utf8),
                  schema:schema,host:host,port:port,completion:completion)
            
            
        }
    }
    
    private static func fetch(_ path: String, method: String, body: Data?, schema: String, host:String, port:Int16,completion:@escaping (Int,Data?)->()) {
        var requestOptions: [ClientRequest.Options] = []
        
        requestOptions.append(.schema("\(schema)://"))
        requestOptions.append(.hostname(host))
        requestOptions.append(.port(port))
        requestOptions.append(.method(method))
        requestOptions.append(.path(path))
        
        let headers = ["Content-Type": "application/json"]
        requestOptions.append(.headers(headers))
        
        var responseBody = Data()
        print("kitura net fetch \(requestOptions)")
        let req = HTTP.request(requestOptions) { response in
            if let response = response {
                guard response.statusCode == .OK else { return }
                _ = try? response.readAllData(into: &responseBody)
                completion(200,responseBody)
            }
        }
        
        //        if let body = body {
        //            req.end(JSON(body))// this sends Data
        //        }
        //        else {
        req.end()
        // }
    }
    
}
