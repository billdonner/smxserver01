/// provenance - SocialMaxx Server
/// builds on XCode 8.2 standard release on OSX 10.12
/// as of 2 Jan 2017
///

//
//  RemoteNetOps.swift
//  IGExplorer
//
//  Created by bill donner on 2/7/16.
//  Copyright © 2016 Bill Donner. All rights reserved.
//
import SwiftyJSON
import LoggerAPI
import Foundation

/// Communicating as API Client to SocialMaxx, Instagram and potentially other services

//typealias NetImgCompletionFunc = (status: Int, object: UIImage?) -> ()


struct RemoteNetOps {
    
    static  func encodedRequest(_ fullurl:URL, params:URLParamsToEncode?) -> NSMutableURLRequest {
        
        let parms = (params != nil) ? params! : [:]
        
        let encreq = NSMutableURLRequest(url:fullurl)
        RemoteNetOps.nwEncode(encreq, parameters: parms)
        
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
            RemoteNetOps.nwEncode(req, parameters: [:])
            
            NetClientOps.perform_get_request(schema: nsurl.scheme!, host:nsurl.host!, port:Int16(nsurl.port!), path:nsurl.path ) {statuscode , data in
                guard  let tdata = data else {
                    print("Api Failure  \(statuscode) in nwGetJSON \(nsurl)")
                    
                    completion(statuscode,[:]   as AnyObject)
                    return
                }
                
                completion(statuscode,tdata as AnyObject?)
                
            }
}
}
    
//   static  var xxsession: URLSession = URLSession(configuration: URLSessionConfiguration.default) // just one session
//    
//
//    fileprivate static func dataTask(_ request: NSMutableURLRequest, method: String, completion: @escaping NetCompletionFunc) {
//        request.httpMethod = method
//        xxsession.dataTask(with:request as URLRequest) { (data, response, error) -> Void in
//            
//            if let response = response as? HTTPURLResponse {
//                let responsecode = response.statusCode
//                
//               print("- dataTask \(responsecode) \(method) \(request.url!.path)")
//                if 200...299 ~= response.statusCode {
//               
//                    if let sdata = data {
//                       
//                        let json =  JSON(data: sdata)
//                        let dict = json.dictionaryObject
//                            completion(responsecode, dict as AnyObject?)
//                    }
//                } else {
//                    completion(responsecode, nil)
//                }
//            }
//            }.resume()
//    }
 
    
//    fileprivate  static func xpost(_ request: NSMutableURLRequest, completion:@escaping NetCompletionFunc) {
//        RemoteNetOps.dataTask(request, method: "POST", completion: completion)
//    }
    
//    fileprivate  static func xput(_ request: NSMutableURLRequest, completion:@escaping NetCompletionFunc) {
//        RemoteNetOps.dataTask(request, method: "PUT", completion: completion)
//    }
    
//    fileprivate  static func xget(_ request: NSMutableURLRequest, completion:@escaping NetCompletionFunc) {
//        RemoteNetOps.dataTask(request, method: "GET", completion: completion)
//    }
    

    
//    static  func xnwPost(_ nsurl:URL, params:  JSONDictionary,completion:@escaping NetCompletionFunc)
//        throws  { // -> NSMutableURLRequest  {
//            let req = NSMutableURLRequest(url:nsurl)
//            RemoteNetOps.nwEncode(req, parameters: params)
//            RemoteNetOps.post(req) {statuscode , data in
//                if data == nil {
//                    print("Api Failure  \(statuscode)   in nwPost \(nsurl)")
//                    
//                    completion(statuscode,[:]  as AnyObject)
//                }
//                else {
//                    completion(statuscode,data)
//                }
//            }
//           // return req // feed the beast that wants something returned
//    }
//    static  func xnwPostFromEncodedRequest(_ req:NSMutableURLRequest,
//                                          completion:@escaping NetCompletionFunc)
//        throws   { //-> NSMutableURLRequest  {
//            //print("nwPost pre-encoded req \(req)")
//            RemoteNetOps.post(req) {statuscode , data in
//                if data == nil {
//                    print("Api Failure  \(statuscode)   in nwPostFromEncodedRequest")
//                    
//                    completion(statuscode,[:]  as AnyObject)
//                }
//                else {
//                    completion(statuscode,data)
//                }
//            }
//           // return req // feed the beast that wants something returned
//    }
    
//    static func killAllTraffic () {
////        session.getAllTasks() { taks in
////            for task in taks {
////                task.cancel()
////            }
////        }
//    }


