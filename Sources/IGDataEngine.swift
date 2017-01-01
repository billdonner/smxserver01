///  provenance - SocialMaxx Server
/// builds on XCode 8.2 standard release on OSX 10.12
/// as of 2 Jan 2017
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
    fileprivate var callingVC: IGDataEngineDelegate?
    fileprivate var notifKey: String?
    fileprivate var finalWrapUpOp : FinalWrapUpOp?
 
    
}

public struct  IGDataEngine {
    // MARK: - Components that are UI free
    fileprivate var targetUserID: String
    fileprivate var targetToken: String
    fileprivate var igData:SocialDataProcessor
    fileprivate var delegate: IGDataEngineDelegate?
    fileprivate var notifKey  : String?
    
    fileprivate var igBackgroundLoadingPipeline : IGBackgroundLoadingPipeline
    
    fileprivate var startTime : Date?
    
    init(forLoggedOnUser:String, targetToken:String, delegate:IGDataEngineDelegate?) {
        self.targetUserID = forLoggedOnUser
        self.targetToken = targetToken
        self.igData = SocialDataProcessor(id:forLoggedOnUser,token:targetToken) // placeholder, better be overwritten in setuppipeline
        self.igBackgroundLoadingPipeline = IGBackgroundLoadingPipeline()
        self.delegate = delegate
    }
    
    func checkapierr(_ errcode:Int) {
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
    fileprivate       func  loadupForBackgroundOperation( _ pipelineNamed:String , notifKey:String? , igp:SocialDataProcessor, delegate: IGDataEngineDelegate? ) -> (NsOp,FinalWrapUpOp) {
        
        func startLoadingPipeline(pipelineNamed named:String , notifKey:String? ,igp: SocialDataProcessor) -> (StartingPipelineOp?,FinalWrapUpOp? ){
            // no concurrency for now, each pipeline is a single threaded sequence of api calls
            //self.notifKey = notifKey
            // make this now and return it to caller
            let finalWrapUpOp = FinalWrapUpOp( )
            finalWrapUpOp.notificationNamed  = notifKey // setup name of NSNotification

            // this should kick off the pipeline
            let o1 = StartingPipelineOp( )
            o1.opname = pipelineNamed
            o1.igp = igp //amen
            o1.finalWrapUpOp = finalWrapUpOp
            o1.delegate = delegate
            return (o1, finalWrapUpOp)
            
        }
       NsOp.aprint ("* starting background api pipeline for \(pipelineNamed)")
        //self.callingVC = delegate
        let (start,final) = startLoadingPipeline(pipelineNamed: pipelineNamed, notifKey: notifKey, igp: igp)
        guard start != nil && final != nil else {
            fatalError("bad pipeline start and finish")
        }
        if let first = start {
            first.opname = pipelineNamed
        }
        return (start!,final!) // and return the ultimate final block
    }
    
     func startPipeline(_ firstOp:Operation) {
        //print("* starting Pipeline with  \(firstOp) added to operation Q")
        Sm.axx.operationQueue.addOperation(firstOp) // this kicks it off
    }
    mutating public func setupPipeline (_ notifKey: String,igp:SocialDataProcessor ) -> (NsOp,FinalWrapUpOp) {
        // load user data
        self.igData = igp
        self.startTime = Date()
        let l : (NsOp,FinalWrapUpOp)
        do {
            
            print("* will restore from disk for  user \(self.targetUserID) data...")
            let pd = try  PersonData.restore(self.targetUserID)
            // if restore fails we go down to the catch
            self.igData.pd = pd
            self.targetUserID = self.igData.targetID            // start pipeline after good restore from disk
            print("* pulling from disk for user \(self.targetUserID) schema version is \(igp.pd.ouVersion!) ... ")
              l  = loadupForBackgroundOperation("diskpipe",notifKey: notifKey,  igp: igp, delegate: self.delegate)
            
            
        }
        catch (_)  {
            // start pipeline to interact with Instagram
            print("* could not restore from disk - contacting Instagram for new user \(self.targetUserID) data...")
            l  =  loadupForBackgroundOperation("mainpipe", notifKey: notifKey, igp: igp, delegate: self.delegate)
            
        }// end of catch
        
        //
        return l
    }//pull sR
    mutating public func setupUpdatePipeline (_ notifKey: String,igp:SocialDataProcessor ) -> (NsOp,FinalWrapUpOp) {
        // load user data
        self.igData = igp
        self.startTime = Date()
        let l : (NsOp,FinalWrapUpOp)
        print("*** setupUpdatePipeline periodic update")
        // start pipeline to interact with Instagram  
        l  =  loadupForBackgroundOperation("updatepipe", notifKey: notifKey, igp: igp, delegate: self.delegate)
        return l
    }//pull sR
}
