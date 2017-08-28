# MobileExample-iOSService-Camera
This repo demonstrates a camera iOS native service and a web app utilizing that service.

## Prerequisites
It is assumed you already have a Predix Mobile service installation, have installed the Predix Mobile pm command line tool, and have installed a Predix Mobile iOS Container.

It is also assumed you have a basic knowledge of mobile iOS development using XCode and Swift.

To get started, follow this documentation:
* [Get Started with the Mobile Service and Mobile SDK] (https://www.predix.io/docs#rae4EfJ6) 
* [Running the Predix Mobile Sample App] (https://www.predix.io/docs#EGUzWwcC)
* [Creating a Mobile Hello World Web App] (https://www.predix.io/docs#DrBWuHkl) 


## Step 1 - Integrate the example code

1. Add the `CameraService.swift` and `PMCamera.swift` files from this repo to your container project:

  a. Open your Predix Mobile container app project. 
  b. In the Project Manager in left-hand pane, expand the PredixMobileReferenceApp project, expand the PredixMobileReferenceApp group, and expand the Classes group. 
  c.In the Classes group, create a group called "Services".

  d. Add the files `CameraService.swift` and `PMCamera.swift` to the Services group, either by dragging from Finder, or by using the Add Files dialog in XCode. When doing this, ensure the `CameraService.swift` and `PMCamera.swift` files are copied to your project, and added to your PredixMobileReferenceApp target.

## Step 2 - Register your new service

The `CameraService.swift` and `PMCamera.swift` files contain all the code needed for the example service, but you must register the service in the container in order for it to be available to your web app. Add a line of code to your `AppDelegate`.

1. In the `AppDelegate.swift` file, navigate to the application: didFinishLaunchingWithOptions: method. In this method, look for a line that looks like this:
```
PredixMobilityConfiguration.loadConfiguration()
```
2. Directly after that line, add the following:
```
PredixMobilityConfiguration.additionalBootServicesToRegister.append(CameraService.self)
```
This will inform the iOS Predix Mobile SDK framework to load your new service when the app starts, thus making it available to your web app.

3. Add the "Privacy - Camera Usage Description", "Privacy - Photo Library Usage Description", and "Privacy - Microphone Usage Description" keys to your Predix Mobile container app's Info.plist file with a string value explaining to the user how the app uses this data. for example you could use "Needed for camera demo functionality."


## Step 3 - Review the code

The Swift files you added to your container are heavily documented. Read through these for a full understanding of how they work, and what they are doing.

The comments take you through creating an implemenation of the ServiceProtocol protocol, handling requests to the service with this protocol, and returning data or error status codes to callers.

## Step 4 - Run the unit tests.


## Step 5 - Call the service from a web app

Your new iOS client service is exposed through the service identifier `camera`. So, calling http://pmapi/camera from a web app will call this service.
A simple demo webapp is provided in the dist directory in the git repo.

**Camera service options for POST request**:  A POST request to `http://pmapi/camera` can be sent with following options  

*Compression* :  
    Compression of served image, ranges from `0-100`  

*MediaType* :  

| parameter     | value         | description                        |  
| ------------- |:-------------:| :---------------------------------:|  
| PICTURE       | 0             | Allows selection of pictures only. |  
| VIDEO         | 1             | Allows selection of videos only.   |  


*SourceType* :  

| parameter     | value         | description                        |  
| ------------- |:-------------:| :---------------------------------:|  
| LIBRARY       | 0             | Choose from library.               |  
| CAMERA        | 1             | Take from camera.                  |  
| SAVEDALBUM    | 2             | Choose from picture library.       |  


*OUTPUT* :  

| parameter     | value         | description                        |  
| ------------- |:-------------:| :---------------------------------:|
| FILE-URI      | 0             | File uri string.                   |
| SRC-DATA      | 1             | Base64 encoded string.             |


*Edit* :  

| parameter     | value         | description                        |  
| ------------- |:-------------:| :---------------------------------:|
| HIDE-CTRL     | 0             | Hide editing control.              |
| SHOW-CTRL     | 1             | Show editing control.              |


*CameraDirection* : <TODO>  


**Camera service options for GET request**: A GET request can be sent to `http://pmapi/camera/image` or `http://pmapi/camera/video` to get array of file URL's  

| parameter     | value         | description                        |  
| ------------- |:-------------:| :---------------------------------:|
| PICTURE       | image         | An array of URL's of all images.   |
| VIDEO         | video         | An array of URL's of all videos.   |


**Camera service options for DELETE request**: A DELETE request can be sent to `http://pmapi/camera/image` or `http://pmapi/camera/video` to delete pictures or video files.  

| parameter     | value         | description                        |  
| ------------- |:-------------:| :---------------------------------:|
| PICTURE       | image         | Delete all images.                 |
| VIDEO         | video         | Delete all videos.                 |
