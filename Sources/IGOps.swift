///  provenance - SocialMaxx Server
///  builds on DEVELOPMENT-SNAPSHOT-2016-05-03-a on OS X 10.11.4  Xcode Version 7.3.1 (7D1014)
///  26 May 2016
///

//
//  IGOps.swift
//  SocialMaxx
//
//  Created by bill donner on 1/18/16.
//  Copyright © 2016 SocialMax. All rights reserved.
//
import LoggerAPI
import Foundation

/// Upper level interface to Instagram API Operations

struct IGOps {
    /// this is good for a one shot get to anywhere
    static func perform_get_request(_ url_to_request: String,  completion:@escaping (Int,Data?)->())
    {
        
        let session = URLSession.shared // doesnt work with Sm.axx.session ??
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
    }
    /// this is good for a one shot post to anywhere
    static func perform_post_request(_ url_to_request: String, paramString: String, completion:@escaping (Int,Data?)->())
    {
        let session = URLSession.shared // doesnt work with Sm.axx.session ??
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
    
    
    
    static func get_token_for_member(_ targetID:String) throws -> String  {
        
        ///
        /// TODO: migrate to remote procedure call to Membership server
        ///
        if    let mem = Membership.shared.members[targetID],
            let token = mem["access_token"] as? String {
            return token
        }
        throw  SMaxxError.noAccessTokenForUser(id: targetID)
    }
    static func getUserstuff (_ targetID:String,
                              completion:@escaping IntPlusOptDictCompletionFunc)
        throws { //-> IGOps.Router  {
            // member must have access token for instagram api access
            let token = try get_token_for_member(targetID)
            let request = IGOps.Router.userInfo(targetID,token)
            try IGOps.plainCall(request.URLRequest.url!,
                                completion: completion)
           // return request
            
    }
    static func getRelationshipstuff (_ targetID:String,
                                      completion:@escaping IntPlusOptDictCompletionFunc)
        throws { //-> IGOps.Router {
            // member must have access token for instagram api access
            let token = try get_token_for_member(targetID)
            let request = IGOps.Router.relationship(targetID,token)
            try IGOps.plainCall(request.URLRequest.url!,
                                completion: completion)
           // return request
            
    }
    
    static func getmediaPosts(_ targetID:String,
                              each:@escaping BOMCompletionFunc,
                              completion:@escaping IntCompletionFunc)
        throws { // -> IGOps.Router {
            // member must have access token for instagram api access
            let token = try get_token_for_member(targetID)
            let request =
                IGOps.Router.mediaRecent (targetID,token)
            print ("getting posts via --- \((request.URLRequest.url!))")
            try IGOps.paginatedCall(request.URLRequest.url!,
                                    each: each,
                                    completion: completion)
            //return request
            
    }
    static func getmediaPostsInRange(_ targetID:String,
                                     minid:String,
                                     maxid:String,
                                     each:@escaping BOMCompletionFunc,
                                     completion:@escaping IntCompletionFunc)
        throws {// -> IGOps.Router {
            // member must have access token for instagram api access
            let token = try get_token_for_member(targetID)
            let request =
                IGOps.Router.mediaRecentInRange(targetID,token,minid,maxid)
            print ("getting posts in range via --- \((request.URLRequest.url!))")
            try IGOps.paginatedCall(request.URLRequest.url!,
                                    each: each,
                                    completion: completion)
           // return request
            
    }
    static func getmediaPostsAboveMin(_ targetID:String,
                                     minid:String,
                                     each:@escaping BOMCompletionFunc,
                                     completion:@escaping IntCompletionFunc)
        throws {// -> IGOps.Router {
            // member must have access token for instagram api access
            let token = try get_token_for_member(targetID)
            let request =
                IGOps.Router.mediaRecentAboveMin(targetID,token,minid )
            print ("getmediaPostsAboveMin --- \((request.URLRequest.url!))")
            try IGOps.paginatedCall(request.URLRequest.url!,
                                    each: each,
                                    completion: completion)
            //return request
            
    }
    static func getmediaPostsBelowMax(_ targetID:String,
                                      maxid:String,
                                      each:@escaping BOMCompletionFunc,
                                      completion:@escaping IntCompletionFunc)
        throws  { //-> IGOps.Router {
            // member must have access token for instagram api access
            let token = try get_token_for_member(targetID)
            let request =
                IGOps.Router.mediaRecentBelowMax(targetID,token, maxid)
            print ("getmediaPostsBelowMax --- \((request.URLRequest.url!))")
            try IGOps.paginatedCall(request.URLRequest.url!,
                                    each: each,
                                    completion: completion)
            //return request
            
    }
 
    static func getAllFollowers(_ targetID:String,
                                each:@escaping BOPCompletionFunc,
                                completion:@escaping IntCompletionFunc)
        throws {// -> IGOps.Router  {
            // member must have access token for instagram api access
            let token = try get_token_for_member(targetID)
            let request = IGOps.Router.followedBy(targetID,token)
            try IGOps.paginatedCall(request.URLRequest.url!,
                                    each: each,
                                    completion: completion)
           // return request
            
    }
    static func getAllFollowing(_ targetID:String,
                                each:@escaping BOPCompletionFunc,
                                completion:@escaping IntCompletionFunc)
        throws {//-> IGOps.Router  {
            // member must have access token for instagram api access
            
            let token = try get_token_for_member(targetID)
            let request = IGOps.Router.following(targetID,token)
            try IGOps.paginatedCall(request.URLRequest.url!,each: each,completion: completion)
           // return request
    }
    static func getLikersForMedia(_ targetID:String,
                                  _ mediablock:IGMediaBlock,
                                  each:@escaping BOMCompletionFunc,
                                  completion:@escaping IntCompletionFunc)
        throws{//  -> IGOps.Router {
            // member must have access token for instagram api access
            
            let token = try get_token_for_member(targetID)
            let id = mediablock["id"] as? String
            let request = IGOps.Router.mediaLikes(id!,token)
            try IGOps.paginatedCall(request.URLRequest.url!,each: each,completion: completion)
            //return request
    }
    
    static func getCommentersForMedia(_ targetID:String,
                                      _ mediablock:IGMediaBlock,
                                      each:@escaping BOMCompletionFunc,
                                      completion:@escaping IntCompletionFunc)
        throws {//-> IGOps.Router {
            let id = mediablock["id"] as? String
            
            // member must have access token for instagram api access
            let token = try get_token_for_member(targetID)
            
            let request = IGOps.Router.mediaComments(id!,token)
            try IGOps.paginatedCall(request.URLRequest.url!,each: each,completion: completion)
           // return request
    }
    
    
    fileprivate static func plainCall(_ url:URL,
                                  completion:@escaping IntPlusOptDictCompletionFunc)
        throws {
            try RemoteNetOps.nwGetJSON(url) { status, jsonObject in
                Sm.axx.igApiCallCount += 1
                defer {
                }
                if status != 200 {
                    completion(status,[:])
                    return // DONT PARSE IF STATUS ISNT RIGHT
                    
                }
                IGJSON.parseIgJSONDict(jsonObject!) { code,dict in
                    completion(code,dict)
                }
            }
    }
    
    fileprivate static   func paginatedCall(_ url:URL,
                                        each:@escaping BOMCompletionFunc,
                                        completion:@escaping IntCompletionFunc) throws {
        
        try  RemoteNetOps.nwGetJSON(url) { status, jsonObject in
            Sm.axx.igApiCallCount += 1
            defer {
            }
            if status == 200 {
                // DONT PARSE IF STATUS IS NOT RIGHT
                IGJSON.parseIgJSONIgMedia(jsonObject!) {
                    url, resData in
                    for every in resData {
                        each(every)
                    }
                    if url != nil  {
                        let  nextURL = url! // Request = NSURLRequest(URL: url!)
                        do {
                            try paginatedCall(nextURL,each:each,completion:completion)
                        }
                        catch {
                            print ("error in recursive paginatedCall")
                        }
                    } else {
                        // no more so run completion
                        completion(200)
                    }
                }
            }// status == 200
            else {
                completion(status) // signal up
            }
        }
    }
    
} // end of IGOps

extension IGOps { // functions that remap instagram data blocks
    
    static func convertRelationshipFrom(_ relationship:IGAnyBlock) ->  RelationshipData {
        let ob =  RelationshipData()
        ob.incoming = relationship["incoming_status"] as! String
        ob.outgoing = relationship["outgoing_status"] as! String
        ob.privacy  = relationship["target_user_is_private"] as! Bool
        return ob
    }
    static   func convertPersonFrom(_ person:IGUserBlock) ->  UserData {
        let ob  =  UserData()
        if let id  = person ["id"] as? String {ob.id = id }
        if let fn = person ["full_name"] as? String {ob.fullname = fn}
        if let un = person ["username"] as? String {ob.username = un}
        if let un = person ["profile_picture"] as? String {ob.pic = un}
        if let un = person ["bio"] as? String {ob.bio = un}
        if let un = person ["website"] as? String {ob.website = un}
        if let p = person ["counts"] as? IGMediaBlock {
            if  let m = p["media"] as? Int {
                if let f = p["follows"] as? Int {
                    if let fb = p["followed_by"] as? Int {
                        ob.igCounts =   [m,f,fb]
                    }
                }
            }
        }
        return ob
    }
    static    func convertCommentFrom(_ comments:IGAnyBlock) -> CommentData {
        let ob  =  CommentData()
        if let id = comments ["id"] as? String {
            ob.commentID = id
            ob.timestamp = comments["created_time"] as! String
            //ob.comment = comments["text"] as! String
            if let igPerson = comments["from"] as? IGUserBlock {
                ob.commenter = convertPersonFrom(igPerson)
            }
        }
        return ob
    }
    
    static    func convertCommentsFrom(_ comments:[IGAnyBlock]) ->  BunchOfComments {
        var bunch:  BunchOfComments = []
        for comment in comments {
            if let id = comment ["id"] as? String {
                let ob  =  CommentData()
                ob.commentID = id
                ob.timestamp = comment["created_time"] as! String
                //ob.comment = comment["text"] as! String
                if let igPerson = comment["from"] as? IGUserBlock {
                    ob.commenter = convertPersonFrom(igPerson)
                    bunch.append(ob)
                }
            }
        }
        return bunch
    }
    static    func convertPeopleFrom(_ people:BunchOfIGPeople) ->  BunchOfPeople {
        return people.map { convertPersonFrom($0) }
    }
    static func convertPostFrom(_ media:IGMediaBlock, likers: BunchOfPeople, comments:  BunchOfComments) ->  MediaData{
        
        func convLikers (_ likers: BunchOfPeople) ->  PeopleDict {
            var pd =  PeopleDict()
            for liker in likers {
                pd[liker.id] = liker
            }
            return pd
        }
        
        func convComments (_ comments: BunchOfComments) ->  CommentsDict {
            var pd =  CommentsDict()
            for comment in comments {
                pd[comment.commentID] = comment
                
            }
            return pd
        }
        // this hugely shrinks the footprint of the app by not storing these large chunks
        let ob =  MediaData()
        if let id = media  ["id"] as? String {
            ob.id = id
            ob.likers = convLikers(likers)
            ob.comments = convComments(comments )
            ob.createdTime = media ["created_time"] as? String ?? ""
            if let cap = media["caption"] as? IGAnyBlock,
                let text = cap["text"] as? String {
                ob.caption = text
            }
            if let g = media["images"] ,
                let ii = g["thumbnail"] as? IGAnyBlock,
                let s = ii["url"] as? String {
                ob.thumbPic = s
            }
        }
        if let g = media["images"] ,
            let ii = g["standard_resolution"] as? IGAnyBlock,
            let s = ii["url"] as? String {
            ob.standardPic = s
        }
        if let tg = media["tags"] as? [String] {
            ob.tags = tg
        }
        if let tg = media["user_has_liked"] as?  Bool {
            ob.userHasLiked = tg
        }
        if let tg = media["likes"] as? IGMediaBlock{
            if let lc = tg["count"] as? Int {
                ob.igLikeCount = lc
            }
        }
        // docs may be incorrect here
        // perhaps we could say users_in_photo.username
        ob.taggedUsers = []
        if let users_in_photo = media["users_in_photo"] as? [AnyObject]{
            for tg in users_in_photo  {
                if let ttg = tg["user"] as? [String:AnyObject]{
                    if let og = ttg ["username"] as? String {
                        ob.taggedUsers.append(og)
                    }
                }
            }
        }
        if let tg = media["filter"] as? String {  ob.filters = [tg] }
        return ob
    }
}// end of class

extension IGOps { // networking
    
    
    enum Router {
        
        
        case mediaLikes(String,String)
        case mediaComments(String,String)
        case userInfo(String,String)
        case relationship(String,String)
        case mediaRecent(String,String)
        
        case mediaRecentAboveMin(String,String,String )//token,min_id,max_id
        case mediaRecentBelowMax(String,String,String )//token,min_id,max_id
        case mediaRecentInRange(String,String,String,String)//token,min_id,max_id
        
//        case SelfMediaLiked(String,String)
//        case SelfFollowing(String,String)
//        case SelfFollowedBy(String,String)
        case following(String,String) // deprecated by instagram ...soon
        case followedBy(String,String) // deprecated by instagram ...
        
        
        // MARK: apart from IG Oauth all the various IG api calls are vectored thru here
        
        var URLRequest: NSMutableURLRequest {
            let result: (path: String, parameters: URLParamsToEncode ) = {
                switch self {
                    
                    
                case .relationship (let userID, let accessToken):
                    let pathString = "/v1/users/" + userID + "/relationship"
                    return (pathString, ["access_token": accessToken as AnyObject ])
                    
                case .userInfo (let userID, let accessToken):
                  let pathString = "/v1/users/" + userID
                    return (pathString, ["access_token": accessToken as AnyObject ])
                    
                case .mediaLikes (let mediaID, let accessToken):
                 
                   let pathString = "/v1/media/" + mediaID + "/likes"
                    return (pathString, ["access_token": accessToken as AnyObject ])
                    
                case .mediaComments (let mediaID, let accessToken):
                
                 let pathString = "/v1/media/" + mediaID + "/comments"
                    return (pathString, ["access_token": accessToken as AnyObject ])
                    
                case .mediaRecent ( _ , let accessToken ):
                    let userID = "self"
                    let pathString = "/v1/users/" + userID + "/media/recent"
                    return (pathString, ["access_token": accessToken as AnyObject ])
                    
                case .mediaRecentAboveMin ( _ , let accessToken, let minID  ):
                   let userID = "self"
                   let pathString = "/v1/users/" + userID + "/media/recent"
                    return (pathString, ["access_token": accessToken as AnyObject,"min_id":minID as AnyObject  ])
                    
                case .mediaRecentBelowMax ( _ , let accessToken, let maxID ):
                   let userID = "self"
                   let pathString = "/v1/users/" + userID + "/media/recent"
                    return (pathString, ["access_token": accessToken as AnyObject, "max_id":maxID as AnyObject  ])
                    
                case .mediaRecentInRange ( _ , let accessToken, let minID, let maxID ):
                    let userID = "self"
                    let pathString = "/v1/users/" + userID + "/media/recent"
                    return (pathString, ["access_token": accessToken as AnyObject,"min_id":minID as AnyObject,"max_id":maxID as AnyObject  ])
                    
//                case .SelfMediaLiked (  _, let accessToken):
//                    let pathString = "/v1/users/self/media/liked"
//                    return (pathString, ["access_token": accessToken ])
                    
                case .following ( _  , let accessToken):
                   let userID = "self"
                   let pathString = "/v1/users/" + userID + "/follows"
                    return (pathString, ["access_token": accessToken as AnyObject ])
                    
                case .followedBy ( _ , let accessToken ):
                    let userID = "self"
                    let pathString = "/v1/users/" + userID + "/followed-by"
                    return (pathString, ["access_token": accessToken as AnyObject ])
                    
//                case .SelfFollowing ( _, let accessToken):
//                    let pathString = "/v1/users/" + "self" + "/follows"
//                    return (pathString, ["access_token": accessToken ])
//                    
//                case .SelfFollowedBy (  _, let accessToken):
//                    let pathString = "/v1/users/" + "self" + "/followed-by"
//                    return (pathString, ["access_token": accessToken ])
                    
                    
                    // default: break
                }
            }()
            
            let baseurl = URL(string: Sm.axx.baseURLString)!
            let fullurl = baseurl.appendingPathComponent(result.path)
            let encodedrequest = RemoteNetOps.encodedRequest(fullurl, params: result.parameters)
            return encodedrequest
        }
    }
}
