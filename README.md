# MobileExample-iOSService-Camera
This repo demonstrates a camera iOS native service and a webapp utilizing that service.

## Step 0 - Prerequisites
It is assumed you already have a Predix Mobile cloud services installation, have installed the Predix Mobile command line tool, and have installed a Predix Mobile iOS Container, following the Getting Started examples for those repos.

It is also assumed you have a basic knowledge of mobile iOS development using XCode and Swift.

## Step 1 - Integrate the example code

Here you will add the `CameraService.swift` and `PMCamera.swift` files from this repo to your container project.

Open your Predix Mobile container app project. In the Project Manager in left-hand pane, expand the PredixMobileReferenceApp project, then expand the PredixMobileReferenceApp group. Within that group, expand the Classes group. In this group, create a group called "Services".

Add the files CameraService.swift and PMCamera.swift to this group, either by dragging from Finder, or by using the Add Files dialog in XCode. When doing this, ensure the CameraService.swift and PMCamera.swift files are copied to your project, and added to your PredixMobileReferenceApp target.

## Step 2 - Register your new service

The CameraService.swift & and PMCamera.swift files contains all the code needed for our example service, however we still need to register our service in the container in order for it to be available to our webapp. In order to do this, we will add a line of code to our AppDelegate.

In the AppDelegate.swift file, navigate to the application: didFinishLaunchingWithOptions: method. In this method, you will see a line that looks like this:
```
PredixMobilityConfiguration.loadConfiguration()
```
Directly after that line, add the following:
```
PredixMobilityConfiguration.additionalBootServicesToRegister = [CameraService.self]
```
This will inform the iOS Predix Mobile SDK framework to load your new service when the app starts, thus making it available to your webapp.

## Step 3 - Review the code

The Swift files you added to your container are heavily documented. Read through these for a full understanding of how they work, and what they are doing.

In brief - they take you through creating an implemenation of the ServiceProtocol protoccol, handling requests to the service with this protocol, and returning data or error status codes to callers.

## Step 4 - Run the unit tests.


## Step 5 - Call the service from a webapp

Your new iOS client service is exposed through the service identifier `camera`. So calling http://pmapi/camera from a webapp will call this service.
A simple demo webapp is provided in the dist directory in the git repo.

**Camera service options for POST request**:
*Compression* :  
    Compression of served image, ranges from `0-100`  

*MediaType* :  
|&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|&nbsp;&nbsp;&nbsp;|&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|  
| ------------- |:-------------:| :---------------------------------:|  
| PICTURE       | 0             | Allows selection of pictures only. |  
| VIDEO         | 1             |   Allows selection of videos only. |  


*SourceType* :  
|               |               |                                    |  
| ------------- |:-------------:| :---------------------------------:|  
| LIBRARY       | 0             | Choose from library.               |  
| CAMERA        | 1             | Take from camera.                  |  
| SAVEDALBUM    | 2             | Choose from picture library.       |  


*OUTPUT* :  
|               |               |                                    |
| ------------- |:-------------:| :---------------------------------:|
| FILE-URI      | 0             | File uri string.                   |
| SRC-DATA      | 1             | Base64 encoded string.             |


*Edit* :  
|               |               |                                    |
| ------------- |:-------------:| :---------------------------------:|
| HIDE-CTRL     | 0             | Hide editing control.              |
| SHOW-CTRL     | 1             | Show editing control.              |


*CameraDirection* : <TODO>  


**Camera service options for GET request**:
|               |               |                                    |
| ------------- |:-------------:| :---------------------------------:|
| PICTURE       | image         | An array of URL's of all images.   |
| VIDEO         | video         | An array of URL's of all videos.   |


**Camera service options for DELETE request**:
|               |               |                                    |
| ------------- |:-------------:| :---------------------------------:|
| PICTURE       | image         | Delete all images.                 |
| VIDEO         | video         | Delete all videos.                 |
