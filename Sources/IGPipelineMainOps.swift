///  provenance - SocialMaxx Server
///  builds on DEVELOPMENT-SNAPSHOT-2016-05-03-a on OS X 10.11.4  Xcode Version 7.3.1 (7D1014)
///  26 May 2016
///


//
//  IGPipelineOps.swift
//  xig
//
//  Created by bill donner on 3/25/16.
//  Copyright © 2016 billdonner. All rights reserved.
//

import Foundation

/* - main Pipeline Starts Here - gets everything
 relationship info
 user info
 get posts
 get followers
 get following
 for each post:
 get comments for post
 get likes for post
 
 */

// MARK: - Step 001 - RelationshipStatusOp
class RelationshipStatusOp: NsOp {
    override func  codeWithApiRequestsInBackground() throws  {
        try
            IGOps.getRelationshipstuff(igp.targetID) { errcode, statusData in
                guard  errcode == 200 else  {
                    return  self.bail(errcode, "- \(self)  api bail getRelationshipstuff")
                    
                } // end 1  guard
                if statusData != nil  {
                    self.igp.pd.ouRelationshipToEndUser  = IGOps.convertRelationshipFrom(relationship:statusData! ) // copy to upstream NsOp variable
                    return self.onward(RelationshipStatusHandler())
                }
                else {
                    fatalError("no status data")
                }
        }
    }
}

// MARK: - Step 002 - RelationshipStatusHandler
class RelationshipStatusHandler: NsHandlerOp {
    override func codeHandlingApiResponses () {
        self.delegate?.didProcessRelationshipStatus(self.igp ,loggedInUser:false)
        return self.onward(UserCredentialsOp())
    }
}

// MARK: - Step 003 - UserCredentialsOp
class UserCredentialsOp: NsOp {
    override func  codeWithApiRequestsInBackground() throws  {
        try
            IGOps.getUserstuff (igp.targetID) { errcode, igPerson in
                guard  errcode == 200 else  {
                    return self.bail(errcode,"- \(self)  api bail getUserstuff")
                    
                } // end 1  guard
                if igPerson  != nil  {
                    
                    self.igp.pd.ouUserInfo =     IGOps.convertPersonFrom(person:igPerson!)
                    //print("Converted from \(igPerson!)")
                    // copy to upstream NsOp variable
                    return self.onward(UserCredentialsHandler())
                }
                else {
                    fatalError("no status data")
                }
        }
    }
}

// MARK: - Step 004 - UserCredentialsHandler
class UserCredentialsHandler: NsHandlerOp {
    override func codeHandlingApiResponses () {
        // BackOp.aprint("run UserCredentialsHandler here in the background")
        self.delegate?.didProcessUserInfo (self.igp )
        return self.onward(AllMediaPostsOp())
    }
}

// MARK: - Step 005 - AllMediaPostsOp
class AllMediaPostsOp: NsOp {
    override func  codeWithApiRequestsInBackground() throws  {
        var posts : [IGMediaBlock] = []
        try
            IGOps.getmediaPosts (igp.targetID, minid: self.igp.pd.ouMinMediaPostID, each: { onePost in
                posts.append(onePost) // accumulate min and max here
                if let postid = onePost["id"] as? String  {
                    self.igp.pd.ouMinMediaPostID = postid
                    if  self.igp.pd.ouMaxMediaPostID == ""
                    {  self.igp.pd.ouMaxMediaPostID = postid
                    }
                }
            } ) { errcode in
                guard  errcode == 200 else  {
                    return self.bail(errcode,"- \(self)  api bail getmediaPosts")
                    
                } // end 1  guard
                // park the full vector upstairs
                
                self.igp.rawPosts =  posts
                // announce count
                print (" --- got \(self.igp.rawPosts.count) new posts ")
                return self.onward( AllMediaPostsHandler())
        }
    }
}

// MARK: - Step 006 - AllMediaPostsHandler
class AllMediaPostsHandler: NsHandlerOp {
    override func codeHandlingApiResponses () {
        //BackOp.aprint("run AllMediaPostsHandler here on \( self.igp.rawPosts.count) in the background")
        // this doesnt do much of anything
        self.delegate?.didProcessAllPosts(self.igp )
        return self.onward( AllFollowersOp( ) )
    }
}

// MARK: - Step 007 - AllFollowersOp
class AllFollowersOp: NsOp {
    override func codeWithApiRequestsInBackground() throws {
        //BackOp.aprint("run AllFollowersOp api call here in the background")
        var followers : [IGUserBlock] = []
        try
            IGOps.getAllFollowers (igp.targetID, each: { oneFollowr in
                followers.append(oneFollowr) // accumulate
                
                //print("",terminator:"F")
            }) { errcode in
                guard  errcode == 200 else  {
                    return self.bail(errcode,"- \(self)  api bail getAllFollowers")
                    
                } // end 1  guard
                // park the full vector upstairs
                
                self.igp.rawFollowers = followers
                
                return self.onward(AllFollowersHandler() )
        }
    }
}

// MARK: - Step 008 - AllFollowersHandler
class AllFollowersHandler: NsHandlerOp {
    override func codeHandlingApiResponses () {
        self.igp.rawFollowers.sort{ // sort by id order in case of subsequent merge
            ($0["id"] as! String) < ($1["id"] as! String)
        }
        self.igp.pd.ouAllFollowers = IGOps.convertPeopleFrom(people:self.igp.rawFollowers)
        self.igp.rawFollowers = [] // reclaim
        
        return self.onward(AllFollowingOp() )
        
    }
}
// MARK: - Step 007AAA - AllFollowersOp
class AllFollowingOp: NsOp {
    override func codeWithApiRequestsInBackground() throws {
        //BackOp.aprint("run AllFollowersOp api call here in the background")
        var followings : [IGUserBlock] = []
        try
            IGOps.getAllFollowing(igp.targetID, each: { oneFollowr in
                followings.append(oneFollowr) // accumulate
                
                // print("",terminator:"G")
            }) { errcode in
                guard  errcode == 200 else  {
                    return self.bail(errcode,("- \(self)  api bail getAllFollowing"))
                    
                } // end 1  guard
                // park the full vector upstairs
                
                self.igp.rawFollowing = followings
                
                return self.onward(AllFollowingHandler() )
        }
    }
}

// MARK: - Step 008AAA - AllFollowersHandler
class AllFollowingHandler: NsHandlerOp {
    override func codeHandlingApiResponses () {
        self.igp.rawFollowers.sort{ // sort by id order in case of subsequent merge
            ($0["id"] as! String) < ($1["id"] as! String)
        }
        self.igp.pd.ouAllFollowing = IGOps.convertPeopleFrom(people:self.igp.rawFollowing)
        self.igp.rawFollowing = [] // reclaim
        self.delegate?.didProcessAllFollowers(self.igp )
        // keep going until we exhaust the posts
        self.igp.rawPostIndex += 1
        if  self.igp.rawPostIndex < self.igp.rawPosts.count {
            let nextOp = OneMediaPostCommentsOp()
            nextOp.mediaBlock = self.igp.rawPosts[self.igp.rawPostIndex]
            self.onward(nextOp)
            
        } else {
            if let nextOp = self.finalWrapUpOp{
                nextOp.needsSaving = true
                self.onward(nextOp)
            }
            
        }
    }
}
// MARK: - Step 009 - OneMediaPostCommentsOp
class OneMediaPostCommentsOp: NsOp {
    var mediaBlock: IGMediaBlock!
    override func codeWithApiRequestsInBackground() throws {
        // BackOp.aprint("run OneMediaPostCommentsOp api call here in the background")
        var commenters : [IGUserBlock] = []
        
        // print("",terminator:"C")
        try
            IGOps.getCommentersForMedia(igp.targetID,   mediaBlock, each: { commenteur in
                // convert format and stuff in Dict
                commenters.append(commenteur) // accumulate
            }) { errcode in
                guard  errcode == 200 else  {
                    return   self.bail(errcode, "- \(self)  api bail OneMediaPostCommentsOp")
                    
                } // end 1  guard
                
                self.igp.rawCommentsDict[self.mediaBlock["id"] as! String] = IGOps.convertCommentsFrom(comments:commenters)
                
                return self.onward(OneMediaPostCommentsHandler())
        }
    }
}

// MARK: - Step 010 - OneMediaPostCommentsHandler
class OneMediaPostCommentsHandler: NsHandlerOp {
    override func codeHandlingApiResponses () {
        // BackOp.aprint("run OneMediaPostCommentsHandler here in the background  \(opname)"
        
        let nextOp = OneMediaPostLikesOp()
        nextOp.mediaBlock = self.igp.rawPosts[self.igp.rawPostIndex]
        self.onward(nextOp)
        
    }
}

// MARK: - Step 011 - OneMediaPostLikesOp
class OneMediaPostLikesOp: NsOp {
    var mediaBlock: IGMediaBlock!
    override func codeWithApiRequestsInBackground() throws {
        //BackOp.aprint("run OneMediaPostCommentsOp api call here in the background")
        var likers : [IGUserBlock] = []
        
        // print("",terminator:"L")
        try
            IGOps.getLikersForMedia( igp.targetID,mediaBlock,
                                     each: { oneFollowr in likers.append(oneFollowr) } )
            { errcode in  // accumulate
                guard  errcode == 200 else  {
                    return self.bail(errcode,"- \(self)  api bail OneMediaPostLikersOp")
                    
                } // end 1  guard
                // park the full vector upstairs
                
                self.igp.rawLikesDict[self.mediaBlock["id"] as! String] = IGOps.convertPeopleFrom(people:likers)
                return self.onward(OneMediaPostLikesHandler() )
        }
    }
}

// MARK: - Step 012 - OneMediaPostLikesHandler
class OneMediaPostLikesHandler: NsHandlerOp {
    override func codeHandlingApiResponses () {
        func processRawPosts() ->  BunchOfMedia {
            var posts :  BunchOfMedia = []
            for onepost in self.igp.rawPosts  {
                if  let theid = onepost["id"] as? String,
                    let tlikers = self.igp.rawLikesDict[theid],
                    let commentz = self.igp.rawCommentsDict[theid] {
                    let reformattedpost = IGOps.convertPostFrom(media:onepost, likers: tlikers , comments: commentz)
                    posts.append( reformattedpost)
                }
            }
            return posts
        }
        
        self.igp.rawPostIndex += 1
        if  self.igp.rawPostIndex < self.igp.rawPosts.count {
            let nextOp = OneMediaPostCommentsOp()
            nextOp.mediaBlock = self.igp.rawPosts[self.igp.rawPostIndex]
            self.onward(nextOp)
            
        } else {
            // if we are here then we have never been to disk so do a bit of extra work here before caling for a file wrap
            self.igp.pd.ouMediaPosts =  self.igp.pd.ouMediaPosts  + processRawPosts()
            if  let nextOp = self.finalWrapUpOp {
                nextOp.needsSaving = true
                self.onward(nextOp)
            }
        }
    }
}