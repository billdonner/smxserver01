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



// MARK: - disk Pipeline


/* - Disk Pipeline Starts Here
 
 reloads everything from Disk in Background
 
 updates UI as if data is received from IG over the network
 
 */

// MARK: - Step 000 - Disk Startup
class DiskStartupOp: NsOp {
    // presumably we've already go it in self.igp so just run all the UI callbacks here
    override func codeWithApiRequestsInBackground() throws {
        
        delegate?.didProcessRelationshipStatus(self.igp,loggedInUser:true)
        if let _  = self.igp.pd.ouUserInfo {
            delegate?.didProcessUserInfo ( self.igp )
            delegate?.didProcessAllFollowers(self.igp)
            delegate?.didProcessAllPosts(self.igp)
            
            if  let nextOp = self.finalWrapUpOp {
                nextOp.needsSaving = false
                onward(nextOp)
                return
            }
        }
        
        fatalError("**could not reload from disk for id " + self.igp.pd.ouUserInfo.id)
    }
}

