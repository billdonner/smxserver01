///  provenance - SocialMaxx Server
///  builds on DEVELOPMENT-SNAPSHOT-2016-05-03-a on OS X 10.11.4  Xcode Version 7.3.1 (7D1014)
///  26 May 2016
///



//
//  IGPipelineUpdateOps.swift
//  xig
//
//  Created by bill donner on 3/25/16.
//  Copyright © 2016 billdonner. All rights reserved.
//

import Foundation
/* - update Pipeline Starts Here
 
 use the current context
 
 get new posts - using current maxid
 
 for each post:
 get comments for post
 get likes for post
 
 Do as much of this as possible:
 
 for old posts -
 get comments for post and merge
 get likes for post and merge
 
 user info
 get followers
 get following
 
 */
class UpdatePipelineStartupOp: NsOp {
    // presumably we've already go it in self.igp so just run all the UI callbacks here
    override func codeWithApiRequestsInBackground() throws {
        let nextOp = OldMediaPostsOp() // AllMediaPostsOp() NewMediaPostsOp()//
        return self.onward(nextOp)
    }
}