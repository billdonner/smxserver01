
/// provenance - SocialMaxx Server
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

/// Upper level interface to Instagram and other Remote API Operations

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
        let req = HTTP.request(requestOptions) { response in
            if let response = response {
                guard response.statusCode == .OK else { return }
                _ = try? response.readAllData(into: &responseBody)
                completion(200,responseBody)
            }
        }
        req.end()
    }
    
    static  func encodedRequest(_ fullurl:URL, params:URLParamsToEncode?) -> NSMutableURLRequest {
        let parms = (params != nil) ? params! : [:]
        let encreq = NSMutableURLRequest(url:fullurl)
         nwEncode(encreq, parameters: parms)
        return encreq
    }
    // nwEncode alters the urlrequest passed in as first componenet
    private static func nwEncode(_ req:NSMutableURLRequest,parameters:  JSONDictionary){
        // extracted from Alamofire
        func escape(_ string: String) -> String {
            let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
            let subDelimitersToEncode = "!$&'()*+,;="
            var allowedCharacterSet = CharacterSet.urlQueryAllowed //as! NSMutableCharacterSet
            allowedCharacterSet.remove(charactersIn:  generalDelimitersToEncode + subDelimitersToEncode)
            return string.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet) ?? ""
        }
        func queryComponents(_ key: String, _ value: AnyObject) -> [(String, String)] {
            var components: [(String, String)] = []
            if let dictionary = value as? [String: AnyObject] {
                for (nestedKey, value) in dictionary {
                    components += queryComponents("\(key)[\(nestedKey)]",  value)
                }
            } else if let array = value as? [AnyObject] {
                for value in array {
                    components += queryComponents("\(key)[]", value)
                }
            } else {
                let kv = (escape(key), escape("\(value)"))
                components.append(kv)
            }
            
            return components
        }
        func query(_ parameters: [String: AnyObject]) -> String {
            var parc = Array(parameters.keys)
            parc.sort()
            var components: [(String, String)] = []
            for key in parc {
                let value = parameters[key]!
                components += queryComponents(key, value)
            }
            return (components.map { "\($0)=\($1)" } as [String]).joined(separator:"&")
        }
        
        if  let uRLComponents = URLComponents(url: req.url!, resolvingAgainstBaseURL: false){
            let percentEncodedQuery = (uRLComponents.percentEncodedQuery.map { $0 + "&" } ?? "") + query(parameters as [String : AnyObject])
            // print("percentEncodedQuery = \(percentEncodedQuery)")
            var nurlcomponents = uRLComponents
            nurlcomponents.percentEncodedQuery = percentEncodedQuery
            req.url = nurlcomponents.url
        }
        return
    }

    static  func nwGetJSON(_ nsurl:URL ,completion:@escaping NetCompletionFunc )
        throws  { //-> NSMutableURLRequest  {
            
            let req = NSMutableURLRequest(url: nsurl)
             nwEncode(req, parameters: [:])
             perform_get_request(schema: nsurl.scheme!, host:nsurl.host!, port:Int16(nsurl.port!), path:nsurl.path ) {statuscode , data in
                guard  let tdata = data else {
                    print("Api Failure  \(statuscode) in nwGetJSON \(nsurl)")
                    completion(statuscode,[:]   as AnyObject)
                    return
                }
                completion(statuscode,tdata as AnyObject?)
            }
    }
}
    
