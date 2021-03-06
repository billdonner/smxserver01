# smxserver01
SMXServer is the generic name for our Web Service for Instagram Analytics. 


![http://billdonner.com/instagramanalytics/instagramanalytics.001.png](http://billdonner.com/instagramanalytics/instagramanalytics.001.png)



Server Deployment
=================

Currently Deployed under IBM Kitura on a dedicated mac Mini running OSX but moving to Linux and Docker containers. 

base code for Kitura based t5 server 
[https://github.com/IBM-Swift/Kitura](https://github.com/IBM-Swift/Kitura)


Clients
=======

There is an associated IOS Client - SMXClient01, which autheticates the user with Instagram and SMXServer, and then requests various reports 

When a new user is identified with the service, the "membership" service sets up the service infrastructure for that client including a background agent that periodically synchronizes the client with Instagram's data. This happens without client involvement. 

The normal client behavior is simply to authenticate and then request reports via the rest interface




Routes and Servers
==========

There are 4 Logical Servers, each running on a different tcp/ip port. 

There is no shared memory between any of them, so they can run in separate processes, and even on separate processors.


Data Stores
===========

There is a persistent database for Members that is behind the Membership Web Service on port xxxx
- Cloudant

There is a persistent database for Workers that is behind the Workers Web Service on port yyyy
- MySQL or similar

There is a reports cache maintained in Memory for the Reports Service on port zzzz 

## Reports routes called by clients:

- get("/reports")
- get("/reports/:id/:reportname")

## Members routes called by clients:


- get("/showlogin") - step one in instagram credentials
- get("/unwindor") - when done


## HomePage Routes

- get("/fp") -- front panel html homepage
- get("/") -- a plain homepage
- get("/log")
- get("/status")


## HomePage Routes used within SMXServer:

- post("/postcallback") -- to and from ig
- get("/postcallback")  -- to and from ig
- all("/_/", middleware: staticFileServer)

## Members routes used within SMXServer:

- get("/membership") -- full list
- delete("/membership") - delete all
- get("/membership/:id")
- delete("/membership/:id")
- post("/membership")
- get("/showlogin") - step one in instagram credentials
- get("/authcallback") - from ig
- get("/status")


## Workers routes used within SMXServer:

- get("/workers/start/:id")
- get("/workers/stop/:id")
- get("/status") - for ops only 
