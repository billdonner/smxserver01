///  provenance - SocialMaxx Server
///  builds on DEVELOPMENT-SNAPSHOT-2016-05-03-a on OS X 10.11.4  Xcode Version 7.3.1 (7D1014)
///  26 May 2016
///


//
//  IGDataEngine.swift
//  SocialMaxx
//
//  Created by bill donner on 1/13/16.
//

import Foundation

protocol IGDataEngineDelegate {
    func didProcessRelationshipStatus(_ igp: SocialDataProcessor,loggedInUser:Bool)
    func didProcessAllFollowers(_ igp:SocialDataProcessor)
    func didProcessAllPosts(_ igp:SocialDataProcessor)
    func didProcessUserInfo (_ igp :SocialDataProcessor)
    func didFinalize (_ igp :SocialDataProcessor)
    func tellUserAboutError(_ errcode:Int,msg:String,prompt:String,title:String)
}
extension IGDataEngineDelegate {
    func didProcessRelationshipStatus(_ igp: SocialDataProcessor,loggedInUser:Bool) {}
    func didProcessAllFollowers(_ igp:SocialDataProcessor) {}
    func didProcessAllPosts(_ igp:SocialDataProcessor) {}
    func didProcessUserInfo (_ igp :SocialDataProcessor) {}
    func didFinalize (_ igp :SocialDataProcessor) {}
    func tellUserAboutError(_ errcode:Int,msg:String,prompt:String,title:String) {}
}

// MARK: - The Pipeline is a Long Running Sequence of Specialty NSOperations
private class IGBackgroundLoadingPipeline {
    private var callingVC: IGDataEngineDelegate?
    private var notifKey: String?
    private var finalWrapUpOp : FinalWrapUpOp?
    
    //    func pipelineDidFinish(igp: OU) {
    //
    //        // write it all to disk, traverses down
    //        do {
    //            try igp.pd.savePd(igp.userID)
    //            print ("did save context for \(igp.userID)")
    //
    //        } catch {
    //            print("coldnt write ig Plist in pipelineDidFinish")
    //        }
    //    }
    private func startLoadingPipeline(pipelineNamed named:String , notifKey:String? ,igp: SocialDataProcessor) -> (StartingPipelineOp?,FinalWrapUpOp? ){
        // no concurrency for now, each pipeline is a single threaded sequence of api calls
        self.notifKey = notifKey
        // make this now and return it to caller
        self.finalWrapUpOp = FinalWrapUpOp( )
        if let finalWrapUpOp = self.finalWrapUpOp {
            finalWrapUpOp.notificationNamed  = notifKey // setup name of NSNotification
        } else {        return (nil, nil) }//throw
        
        // this should kick off the pipeline
        let o1 = StartingPipelineOp( )
        o1.igp = igp //amen
        o1.finalWrapUpOp = finalWrapUpOp
        // o1.delegate = self.callingVC
        return (o1,self.finalWrapUpOp)
        
    }
    private func startLoadingUpdatePipeline(pipelineNamed named:String , notifKey:String? ,igp: SocialDataProcessor) -> (NsOp?,FinalWrapUpOp? ){
        // no concurrency for now, each pipeline is a single threaded sequence of api calls
        self.notifKey = notifKey
        // make this now and return it to caller
        self.finalWrapUpOp = FinalWrapUpOp( )
        if let finalWrapUpOp = self.finalWrapUpOp {
            finalWrapUpOp.notificationNamed  = notifKey // setup name of NSNotification
        } else {        return (nil, nil) }//throw
        
        // this should kick off the pipeline
        let o1 = StartingUpdatePipelineOp( )
        o1.igp = igp //amen
        o1.finalWrapUpOp = finalWrapUpOp
        // o1.delegate = self.callingVC
        return (o1,self.finalWrapUpOp)
        
    }
  private  func  loadupForUpdateBackgroundOperation( pipelineNamed:String , notifKey:String? , igp:SocialDataProcessor, delegate: IGDataEngineDelegate? ) -> (NsOp,FinalWrapUpOp) {
        BackOp.aprint ("* starting update api pipeline for \(pipelineNamed)")
        self.callingVC = delegate
        let (start,final) = self.startLoadingUpdatePipeline(pipelineNamed:pipelineNamed, notifKey:notifKey ,igp:igp)
        guard start != nil && final != nil else {
            fatalError("bad pipeline start and finish")
        }
        if let first = start {
            first.opname = pipelineNamed
        }
        return (start!,final!) // and return the ultimate final block
    }
   private func  loadupForBackgroundOperation( pipelineNamed:String , notifKey:String? , igp:SocialDataProcessor, delegate: IGDataEngineDelegate? ) -> (NsOp,FinalWrapUpOp) {
        BackOp.aprint ("* starting background api pipeline for \(pipelineNamed)")
        self.callingVC = delegate
        let (start,final) = self.startLoadingPipeline(pipelineNamed:pipelineNamed, notifKey:notifKey ,igp:igp)
        guard start != nil && final != nil else {
            fatalError("bad pipeline start and finish")
        }
        if let first = start {
            first.opname = pipelineNamed
        }
        return (start!,final!) // and return the ultimate final block
    }
}

struct  IGDataEngine {
    // MARK: - Components that are UI free
    private var targetUserID: String
      private var targetToken: String
    private var igData:SocialDataProcessor
    private var delegate: IGDataEngineDelegate?
    private var notifKey  : String?
    
    private var igBackgroundLoadingPipeline : IGBackgroundLoadingPipeline
    
    private var startTime : NSDate?
    
    init(forLoggedOnUser:String, targetToken:String, delegate:IGDataEngineDelegate?) {
        self.targetUserID = forLoggedOnUser
         self.targetToken = targetToken
        self.igData = SocialDataProcessor(id:forLoggedOnUser,token:targetToken) // placeholder, better be overwritten in setuppipeline
        self.igBackgroundLoadingPipeline = IGBackgroundLoadingPipeline()
        self.delegate = delegate
    }
    
    func checkapierr(errcode:Int) {
        guard errcode == 200  else {
            // removed from server version -= FS.removeUserData(self.targetUserID)
            // do something
            if errcode == 400 || errcode == 403 {
                //in this case we can live to fight another day
                print ("-setupPipeline  error \(errcode) from fullStartup")
                self.delegate?.tellUserAboutError(
                    errcode, msg: "Privacy error in full startup",
                    prompt:"Can not get personal info from Instagram for this user errcode = \(errcode)",
                    title:"You have no access to this user")
                return
            }
            fatalError("-- YIKES error \(errcode) from fullStartup, please contact your vendor")
        }
    }
    //MARK: - setupPipeline  is ONLY Externally Called Method
    private mutating func start_pipeline_from_api(_ igp:SocialDataProcessor,targetID:String,notifKey:String?) -> (NsOp,FinalWrapUpOp) {
        
        print("* contacting Instagram for user \(targetID) data...")
        self.targetUserID = targetID
        return self.igBackgroundLoadingPipeline.loadupForBackgroundOperation(pipelineNamed: "mainpipe", notifKey: notifKey, igp: igp, delegate: self.delegate)
    }
    private mutating func start_pipeline_from_update_api(_ igp:SocialDataProcessor,targetID:String,notifKey:String?) -> (NsOp,FinalWrapUpOp) {
        
        print("* contacting Instagram for updating user \(targetID) data...")
        self.targetUserID = targetID
        return self.igBackgroundLoadingPipeline.loadupForUpdateBackgroundOperation(pipelineNamed: "mainpipe", notifKey: notifKey, igp: igp, delegate: self.delegate)
    }
    private mutating func start_pipeline_from_disk(_ igp:SocialDataProcessor,targetID:String,notifKey:String?) -> (NsOp,FinalWrapUpOp) {
        self.targetUserID = targetID
        //        if igp.pd.ouVersion != igp.pd.plistVersion {
        //            print("* db version mismatch hence must reload")
        //            return self.igBackgroundLoadingPipeline.loadupForBackgroundOperation(pipelineNamed: "mainpipe", notifKey: notifKey, igp: igp, delegate: self.delegate)
        //        }
        print("* pulling from disk for user \(targetID) schema version is \(igp.pd.ouVersion!) ... ")
        self.targetUserID = targetID
        return self.igBackgroundLoadingPipeline.loadupForBackgroundOperation(pipelineNamed:"diskpipe",notifKey: notifKey,  igp: igp, delegate: self.delegate)
    }
    func startPipeline(firstOp:NSOperation) {
        //print("* starting Pipeline with  \(firstOp) added to operation Q")
        Sm.axx.operationQueue.addOperation(firstOp) // this kicks it off
    }
    mutating func setupPipeline (notifKey: String,igp:SocialDataProcessor ) -> (NsOp,FinalWrapUpOp) {
        // load user data
        self.igData = igp
        self.startTime = NSDate()
        let l : (NsOp,FinalWrapUpOp)
        do {
            
            print("* will restore from disk for  user \(self.targetUserID) data...")
            let pd = try  PersonData.restore(userID:self.targetUserID)
            // if restore fails we go down to the catch
            self.igData.pd = pd
            // start pipeline after good restore from disk
            
            print("* did restore from disk for  user \(self.targetUserID) data...")
            l  = start_pipeline_from_disk(self.igData,targetID: self.targetUserID,notifKey:notifKey)
        }
        catch (_)  {
             print("* did not restore from disk for  user \(self.targetUserID) data...")
            // start pipeline to interact with Instagram
            l = start_pipeline_from_api(self.igData,targetID: self.targetUserID,notifKey:notifKey)
        }// end of catch
        
        //
        return l
    }//pull sR
    mutating func setupUpdatePipeline (notifKey: String,igp:SocialDataProcessor ) -> (NsOp,FinalWrapUpOp) {
        // load user data
        self.igData = igp
        self.startTime = NSDate()
        let l : (NsOp,FinalWrapUpOp)
        print("*** setupUpdatePipeline periodic update")
        // start pipeline to interact with Instagram
        l = start_pipeline_from_update_api(self.igData,targetID: self.targetUserID,notifKey:notifKey)
        
        return l
    }//pull sR
}