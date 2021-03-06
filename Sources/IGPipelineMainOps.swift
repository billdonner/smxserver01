/// provenance - SocialMaxx Server
/// builds on XCode 8.2 standard release on OSX 10.12
/// as of 2 Jan 2017
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
                    self.igp.pd.ouRelationshipToEndUser  = IGOps.convertRelationshipFrom(statusData! as IGAnyBlock ) // copy to upstream NsOp variable
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
                    
                    self.igp.pd.ouUserInfo =     IGOps.convertPersonFrom(igPerson! as IGUserBlock)
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
        func isuniq(_ post:IGMediaBlock) -> DarwinBoolean {
            /// AWFUL SLOW
            let t =  post["id"] as? String
            for apost in self.igp.pd.ouMediaPosts {
                if apost.id  == t
                {
                    
                    print("Duplicate First Up  Media Posts Op \(t!)")
                    return false
                }
            }
            return true
        }
        /// on a brand new user we just ask generally
        try
            IGOps.getmediaPosts (igp.targetID,  each: { onePost in
                if isuniq(onePost).boolValue { posts.append(onePost) // accumulate min and max here
              self.handleMediaPostMinMax(onePost)
                }
            } ) { errcode in
                guard  errcode == 200 else  {
                    return self.bail(errcode,"- \(self)  api bail getmediaPosts")
                    
                } // end 1  guard
                // park the full vector upstairs
                
                self.igp.rawPosts =  posts
                // announce count
                print (" --- got \(self.igp.rawPosts.count) in first batch of posts ")
                return self.onward( AllMediaPostsHandler())
        }
    }
}
// MARK: - Step 005A - OldMediaPostsOp - asks for posts below the current min
class OldMediaPostsOp: NsOp {
    override func  codeWithApiRequestsInBackground() throws  {
        var posts : [IGMediaBlock] = []
        func isuniq(_ post:IGMediaBlock) -> DarwinBoolean {
            /// AWFUL SLOW
            let t =  post["id"] as? String
            for apost in self.igp.pd.ouMediaPosts {
                if apost.id  == t
                {
                    
                    print("Duplicate Old Media Posts Op \(t!)")
                    return false
                }
            }
            return true
        }
        print("Getting Old Media Posts")
        let maxt =  self.igp.pd.ouMinMediaPostID // ask for things below this id
        try
            IGOps.getmediaPostsBelowMax (igp.targetID, maxid: maxt , each: { onePost in
                if isuniq(onePost).boolValue { posts.append(onePost) // accumulate min and max here
                self.handleMediaPostMinMax(onePost)
                }
           
            } ) { errcode in
                guard  errcode == 200 else  {
                    return self.bail(errcode,"- \(self)  api bail getmediaPosts")
                    
                } // end 1  guard
                // park the full vector upstairs
                
                self.igp.rawPosts =  posts
                // announce count
                print (" --- got \(self.igp.rawPosts.count) old posts ")
                return self.onward( NewMediaPostsOp()) // now get new posts
        }
    }
}
// MARK: - Step 005B - NewMediaPostsOp - asks for posts above the current max
class NewMediaPostsOp: NsOp {
    override func  codeWithApiRequestsInBackground() throws  {
        var posts : [IGMediaBlock] = []
        func isuniq(_ post:IGMediaBlock) -> DarwinBoolean {
            /// AWFUL SLOW
            let t =  post["id"] as? String
            for apost in self.igp.pd.ouMediaPosts {
                if apost.id  == t
                {
                    print("Duplicate New Media Posts Op \(t!)")
                    return false
                }
            }
            return true
        }
        print("Getting New Media Posts")
        let maxt =  self.igp.pd.ouMaxMediaPostID // ask for things below this id
        try
            IGOps.getmediaPostsAboveMin (igp.targetID, minid: maxt , each: { onePost in
                 if isuniq(onePost).boolValue { posts.append(onePost) // accumulate min and max here
                self.handleMediaPostMinMax(onePost)
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
        self.igp.pd.ouAllFollowers = IGOps.convertPeopleFrom(self.igp.rawFollowers)
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
        self.igp.pd.ouAllFollowing = IGOps.convertPeopleFrom(self.igp.rawFollowing)
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
                
                self.igp.rawCommentsDict[self.mediaBlock["id"] as! String] = IGOps.convertCommentsFrom(commenters)
                
                return self.onward(OneMediaPostCommentsHandler())
        }
    }
}

// MARK: - Step 010 - OneMediaPostCommentsHandler
class OneMediaPostCommentsHandler: NsHandlerOp {
    override func codeHandlingApiResponses () {
        
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
                
                self.igp.rawLikesDict[self.mediaBlock["id"] as! String] = IGOps.convertPeopleFrom(likers)
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
                    let reformattedpost = IGOps.convertPostFrom(onepost, likers: tlikers , comments: commentz)
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
