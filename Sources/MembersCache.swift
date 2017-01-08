/// provenance - SocialMaxx Server
/// builds on XCode 8.2 standard release on OSX 10.12
/// as of 2 Jan 2017
///

//
//  Membership
//  SMaxxServer
//
//  Created by william donner on 5/3/16.
//
//

import Kitura
import KituraNet
//import KituraSys
import LoggerAPI
import SwiftyJSON
import Foundation


//// all varieties of server include these functions to access a remote Membership server in a highly performant manner


open class MembersCache {
    
    
    // local cache to hold arbitrary json blocks, not snapped to disk
    
    var localmembers :   [String:AnyObject] = [:] // not jsondictionary
    
    
    class func isMemberFromCache(_ id:String)->Bool {
        if let mem = localmembers[id] {
            return true
        }
        
        return false
    }
 
 
    /// remote call to membership server for member info, tokens, etc, only called internally
    
    private class func isMember_Remote(_ id:String,completion:@escaping (JsonDictionary)->()) {
        
        /// buld http get to return all in an id block
        let ret = [:]
        completion(ret)
        }

    
  /// coming to here means try the cache and if not found, do the full call
    
    class func isMember(_ id:String,completion:@escaping (Bool)->()) {
        if let mem = localmembers[id] {
            completion(true)
            return
        }
        //nothing, so get details via a remote webservice call to the assigned members server
        
        isMember_Remote(id,completion:completion)
    }

    
    private class func getTokensFromID_Remote(id:String, completion: @escaping ((String?,String?) ->())){
        
        /// buld http get to return all in an id block

        let ret = (nil, nil)
        completion (ret.0,ret.1)
    }
    
     class func getTokensFromID(id:String, completion: @escaping ((String?,String?) ->())){
        if let tok = localmembers[id] {
            completion (tok.0,tok.1)
            return
        }
        
        completion (nil, nil)
    }
    
    
}
