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


var membersCache = MembersCache()

open class MembersCache {
    
    
    // local cache to hold arbitrary json blocks, not snapped to disk
    
    var localmembers :   [String:AnyObject] = [:] // not jsondictionary
    
    
    class func isMemberFromCache(_ id:String)->Bool {
        if let mem = localmembers[id] {
            return true
        }
        
        return false
            
           // MembersMainServer.m_isMember(id)  // DOES NOT PLACE REMOTE CALL, JUST RETURNS CACHED VALUE, IF ANY
        
    }
    /// not called
    class func getTokenFromIDFromCache(id:String)-> String? {
        
        if let mem = localmembers[id],
            let token = mem["access_token"] {
            return token // this is the token
        }
       // let tok = MembersMainServer.m_getTokenFromID(id: id) // DOES NOT PLACE REMOTE CALL, JUST RETURNS CACHED VALUE, IF ANY
        return nil
    }
    
    /// only called by reportmaker
    class func getTokensFromIDFromCache(id:String)->(String?,String?){
        if    let mem =  localmembers[id] {
            let token = mem["access_token"] as? String
            let stoken = mem["smaxx-token"] as? String
            return (token,stoken)
        }
        return (nil,nil)
    }
    
    /// only called by reportmaker
    class func getMemberIDFromTokenFromCache(_ token:String)->String?  {
        let id = MembersMainServer.m_getMemberIDFromToken(token)
        return(id)
    }
    
    
    
    
    
    class func isMember(_ id:String,completion:@escaping (Bool)->()) {
       let b =  MembersMainServer.m_isMember(id)
        completion( b )
    
    }
    class func getTokenFromID(id:String,completion: @escaping(String?)->()) {
        let tok = MembersMainServer.m_getTokenFromID(id: id)
        completion( tok )
    }
    class func getTokensFromID(id:String, completion: @escaping ((String?,String?) ->())){
        let tok = MembersMainServer.m_getTokensFromID(id: id)
        completion (tok.0,tok.1)
    }
    class func getMemberIDFromToken(_ token:String, completion:@escaping ((String?) -> ())) {
        completion(nil)
        let id = MembersMainServer.m_getMemberIDFromToken(token)
        completion(id)
    }
}
