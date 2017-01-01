///  provenance - SocialMaxx Server
///  builds on DEVELOPMENT-SNAPSHOT-2016-05-03-a on OS X 10.11.4  Xcode Version 7.3.1 (7D1014)
///  26 May 2016
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
    static func decodeData(_ sdata:Data) -> JSON {
        
            let jsonBody = JSON(data: sdata)
            return jsonBody

    }
    
    fileprivate static func dataTask(_ request: NSMutableURLRequest, method: String, completion: @escaping NetCompletionFunc) {
        request.httpMethod = method
        Sm.axx.session.dataTask(with:request as URLRequest) { (data, response, error) -> Void in
            
            if let response = response as? HTTPURLResponse {
                let responsecode = response.statusCode
                
               print("- dataTask \(responsecode) \(method) \(request.url!.path)")
                if 200...299 ~= response.statusCode {
               
                    if let sdata = data {
                       
                        let json =  decodeData(sdata)
                            let dict = json.dictionaryObject
                            completion(responsecode, dict as AnyObject?)
                    }
                } else {
                    completion(responsecode, nil)
                }
            }
            }.resume()
    }
    
    //not currently used
//    private static func imageTask(request: NSMutableURLRequest, method: String, completion:NetImgCompletionFunc) {
//        request.HTTPMethod = method
//        
//        session.dataTaskWithRequest(request) { (data, response, error) -> Void in
//            if
//                let response = response as? NSHTTPURLResponse {
//                let responsecode = response.statusCode
//                
//                print("- imageTask \(responsecode) \(method) \(request.URL!.path!)")
//                if 200...299 ~= response.statusCode {
//                    if let data = data, let image = UIImage(data:data){
//                        completion(status: responsecode, object: image)
//                    }
//                } else {
//                    completion(status:responsecode, object: nil)
//                }
//                
//            }
//            }.resume()
//    }
    
    fileprivate  static func post(_ request: NSMutableURLRequest, completion:@escaping NetCompletionFunc) {
        RemoteNetOps.dataTask(request, method: "POST", completion: completion)
    }
    
    fileprivate  static func put(_ request: NSMutableURLRequest, completion:@escaping NetCompletionFunc) {
        RemoteNetOps.dataTask(request, method: "PUT", completion: completion)
    }
    
    fileprivate  static func get(_ request: NSMutableURLRequest, completion:@escaping NetCompletionFunc) {
        RemoteNetOps.dataTask(request, method: "GET", completion: completion)
    }
    //not currently used
//    private  static func getImg(request: NSMutableURLRequest, completion:NetImgCompletionFunc) {
//        RemoteNetOps.imageTask(request, method: "GET", completion: completion)
//    }
  //not currently used
//    private  static  func nwGetImage(nsurl:NSURL ,completion:NetImgCompletionFunc )
//        throws -> NSMutableURLRequest  {
//            let req = NSMutableURLRequest(URL: nsurl)
//            
//            IGOps.nwEncode(req, parameters: [:])
//            RemoteNetOps.getImg(req) {statuscode , image in
//                if image == nil {
//                    print("Api Failure \(statuscode) in nwGetImage \(nsurl)")
//                    
//                    completion(status:statuscode,object:nil )
//                }
//                else {
//                    completion(status:statuscode,object:image)
//                }
//            }
//            return req // feed the beast that wants something returned
//    }
    
    static  func nwGetJSON(_ nsurl:URL ,completion:@escaping NetCompletionFunc )
        throws  { //-> NSMutableURLRequest  {
            
            let req = NSMutableURLRequest(url: nsurl)
            RemoteNetOps.nwEncode(req, parameters: [:])
            
            RemoteNetOps.get(req) {statuscode , data in
                if data == nil {
                    print("Api Failure  \(statuscode) in nwGetJSON \(nsurl)")
                    
                    completion(statuscode,[:]   as AnyObject)
                }
                else {
                    completion(statuscode,data)
                }
            }
            //return req // feed the beast that wants something returned
    }
    
    static  func nwPost(_ nsurl:URL, params:  JSONDictionary,completion:@escaping NetCompletionFunc)
        throws  { // -> NSMutableURLRequest  {
            let req = NSMutableURLRequest(url:nsurl)
            RemoteNetOps.nwEncode(req, parameters: params)
            RemoteNetOps.post(req) {statuscode , data in
                if data == nil {
                    print("Api Failure  \(statuscode)   in nwPost \(nsurl)")
                    
                    completion(statuscode,[:]  as AnyObject)
                }
                else {
                    completion(statuscode,data)
                }
            }
           // return req // feed the beast that wants something returned
    }
    static  func nwPostFromEncodedRequest(_ req:NSMutableURLRequest,
                                          completion:@escaping NetCompletionFunc)
        throws   { //-> NSMutableURLRequest  {
            //print("nwPost pre-encoded req \(req)")
            RemoteNetOps.post(req) {statuscode , data in
                if data == nil {
                    print("Api Failure  \(statuscode)   in nwPostFromEncodedRequest")
                    
                    completion(statuscode,[:]  as AnyObject)
                }
                else {
                    completion(statuscode,data)
                }
            }
           // return req // feed the beast that wants something returned
    }
    
    static func killAllTraffic () {
//        session.getAllTasks() { taks in
//            for task in taks {
//                task.cancel()
//            }
//        }
    }
    
    static  func encodedRequest(_ fullurl:URL, params:URLParamsToEncode?) -> NSMutableURLRequest {
        
        let parms = (params != nil) ? params! : [:]
        
        let encreq = NSMutableURLRequest(url:fullurl)
        RemoteNetOps.nwEncode(encreq, parameters: parms!)
        
        return encreq
    }
    static func nwEncode(_ req:NSMutableURLRequest,parameters:  JSONDictionary){
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
    
    
    
}
func inNotIn(_ a:StringAnalysisBlock,_ b:AnalysisBlock) -> StringAnalysisBlock {
    var ret : StringAnalysisBlock = [:]
    for (key,val) in a {  if (b[key] != nil) { } else { ret[key] = val }}
    return ret
}
func inNotIn(_ a:AnalysisBlock,_ b:StringAnalysisBlock) -> AnalysisBlock {
    var ret : AnalysisBlock = [:]
    for (key,val) in a {  if (b[key] != nil) { } else { ret[key] = val }}
    return ret
}
func inNotIn(_ a:AnalysisBlock,_ b:AnalysisBlock) -> AnalysisBlock {
    var ret : AnalysisBlock = [:]
    for (key,val) in a {  if (b[key] != nil) { } else { ret[key] = val }}
    return ret
}


func inAndIn(_ a:AnalysisBlock,_ b:AnalysisBlock) -> AnalysisBlock {
    var ret : AnalysisBlock = [:]
    for (key,val) in a {  if (b[key] == nil) { } else { ret[key] = val }}
    return ret
}

// MARK: Support funcs
 func removeDuplicates(_ array:BunchOfIGPeople) -> BunchOfIGPeople {
    var encountered = Set<String>()
    var result: BunchOfIGPeople = []
    for value in array {
        if let id = value["id"] as? String {
            if !encountered.contains(id) {
                // Do not add a duplicate element.
                // Add id to the set.
                encountered.insert(id)
                // ... Append the value.
                result.append(value)
            }
        }
    }
    return result
}

 func reverseFrequencyOrder (_ aa: BunchOfPeople,
                                   by: BunchOfPeople) ->  BunchOfPeople {
    // reorders the users in aa
    // according to the frequency of references in block by
    // both are assumed to be in sort order, aa must be unique
    var aaidx = 0
    var byidx = 0
    var result: BunchOfPeople = []
    var frequencies :[FreqCount] = []
    let aacount = aa.count
    let bycount = by.count
    for idx in 0..<aacount {
        frequencies.append(FreqCount(idx: idx,frequency: 0))
    }
    while aaidx < aacount && byidx < bycount {
        // depends on short circuit evaluation by &&
        while aaidx < aacount  && (aa[aaidx].id) < (by[byidx].id){
            aaidx = aaidx + 1
        }
        
        while aaidx < aacount  && byidx < bycount && (aa[aaidx].id) >=  (by[byidx].id) {
            if (aa[aaidx].id) ==  (by[byidx].id) {
                
                frequencies[aaidx].frequency = frequencies[aaidx].frequency + 1
            }
            byidx = byidx + 1
        }
    }
    // rearrange results
    frequencies.sort  { $0.frequency>$1.frequency }
    for freq in frequencies {
        result.append(aa[freq.idx])
    }
    return result
}
 func intersect(_ array1:  BunchOfPeople,
                      _ array2: BunchOfPeople) ->  BunchOfPeople {
    var encountered = Set<String>()
    var result:  BunchOfPeople = []
    for value in array1 {
        if !encountered.contains(value.id ) {
            // Do not add a duplicate element.
            // Add value to the set.
            encountered.insert(value.id )
        }
    }
    for value in array2 {
        if encountered.contains(value.id) {
            // Its in both
            
            // ... Append the value.
            result.append(value)
        }
    }
    return result
}

