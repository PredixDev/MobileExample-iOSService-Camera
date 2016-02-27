//
//  CameraService.swift
//  PredixMobileReferenceApp
//
//  Created by  on 2/23/16.
//  Copyright © 2016 GE. All rights reserved.
//

import Foundation
import UIKit
import MobileCoreServices
/// import the PredixMobile framework, so Swift can find the PredixMobile components we'll need
import PredixMobileSDK

/// As this protocol is defined as Obj-C compatible, the implementer must be an Obj-C compatible class.
@objc class CameraService: NSObject, ServiceProtocol {

    /// - Note:
    /// ServiceProtocol's properties and methods are all defined as static, and no class implementation of your service is ever created.
    /// This is a purposeful architectural decision. Services should be stateless and interaction with them ephemeral. A static
    /// object enforces this direction.


    /// the serviceIdentifier property defines first path component in the URL of the service.
    static var serviceIdentifier : String {get { return "camera" }}


    //  MARK: performRequest - entry point for request
    /**
    performRequest is the meat of the service. It is where all requests to the service come in.

    The request parameter will contain all information the caller has provided for the request, this will include the URL,
    the HTTP Method, and in the case of a POST or PUT, any HTTP body data.
    The nature of services are asynchronous. So this method has no return values, it communicates with its caller through three
    blocks or closures. These three are the parameters responseReturn, dataReturn, and requestComplete. This follows the general
    nature of a web-based HTTP interaction.

    - parameters:
    - responseReturn    : generally every call to performRequest should call responseReturn once, and only once. The call requires an
    NSHTTPResponse object, and a default object is provided as the "response" parameter. The response object can be returned directly,
    or can be used as a container for default values, and a new NSHTTPResponse can be built from it. The default response parameter's
    status code is 200 (OK), so error conditions will not return the response object unaltered. (See the respondWithErrorStatus methods,
    and the createResponse method documentation below for helpers in creating other response objects.)

    - dataReturn        : Services that return data, and not just a status code will use the dataReturn parameter to return data. Generally
    this block will be called once, however it could be called multiple times to return particularly large amounts of data in a
    chunked fashion. Again, this behavior follows general web-based HTTP interaction. If used, the dataReturn block should be called after
    the responseReturn block is called, and before the responseComplete block is called.

    - requstComplete    : this block indicates to the caller that the service has completed processing, and the call is complete. The requestComplete
    block must be called, and it must be called only once per performRequest call. Once the requestComplete block is called, no additional
    processing should happen in the service, and no other blocks should be called.
    */
    static func performRequest(request : NSURLRequest, response : NSHTTPURLResponse, responseReturn : responseReturnBlock, dataReturn : dataReturnBlock, requestComplete: requestCompleteBlock)
    {

        /// First let's examine the request. In this example, we're going to expect only a GET request, and the URL path should only be the serviceIdentifier

        /// we'll use a guard statement here just to verify the request object is valid. The HTTPMethod and URL properties of a NSURLRequest
        /// are optional, and we need to ensure we're dealing with a request that contains them.
        guard let url = request.URL, path = url.path, method = request.HTTPMethod else
        {
            /**
            if the request does not contain a URL or a HTTPMethod, then we return a error. We'll also return an error if the URL
            does not contain a path. In a normal interaction this would never happen, but we need to be defensive and expect anything.

            we'll use one of the respondWithErrorStatus methods to return an error condition to the caller, in this case,
            a status code of 400 (Bad Request).

            Note that the respondWithErrorStatus methods all take the response object, the reponseReturn block and the requestComplete
            block. This is because the respondWithErrorStatus constructs an appropriate NSHTTPURLResponse object, and calls
            the reponseReturn and requestComplete blocks for you. Once a respondWithErrorStatus method is called, the performRequest
            method should not continue processing and should always return.
            */
            self.respondWithErrorStatus(.BadRequest, response, responseReturn, requestComplete)
            return
        }

        /**
        Now that we know we have a path and method string, let's examine them for our expected values.
        For this example we'll return an error if the url has any additional path or querystring parameters.
        We'll also return an error if the method is not the expected GET HTTP method. The HTTP Status code convention
        has standard codes to return in these cases, so we'll use those.
        */

        /**
        Path in this case should match the serviceIdentifier, or "barcodescanner". We know the serviceIdentifier is all
        lower case, so we ensure the path is too before comparing.
        In addition, we expect the query string to be nil, as no query parameters are expected in this call.
        In your own services you may want to be more lenient, simply ignoring extra path or parameters.
        */

        guard path.lowercaseString == "/\(self.serviceIdentifier)" && url.query == nil else
        {
            /// In this case, if the request URL is anything other than "http://pmapi/barcodescanner" we're returning a 400 status code.
            self.respondWithErrorStatus(.BadRequest, response, responseReturn, requestComplete)
            return
        }

        /// now that we know our path is what we expect, we'll check the HTTP method. If it's anything other than "POST"
        /// we'll return a standard HTTP status used in that case.
        guard method == "POST" else
        {
            /// According to the HTTP specification, a status code 405 (Method not allowed) must include an Allow header containing a list of valid methods.
            /// this  demonstrates one way to accomplish this.
            let headers = ["Allow" : "POST"]

            /// This respondWithErrorStatus overload allows additional headers to be passed that will be added to the response.
            self.respondWithErrorStatus(HTTPStatusCode.MethodNotAllowed, response, responseReturn, requestComplete, headers)
            return
        }

        guard let bodyData = request.HTTPBody else
        {
            PGSDKLogger.error("Camera Service: No body preset");
            self.respondWithErrorStatus(.BadRequest, response, responseReturn, requestComplete)
            return
        }

        do
        {
            let bodyObject = try NSJSONSerialization.JSONObjectWithData(bodyData, options: NSJSONReadingOptions.AllowFragments)
            guard let bodyDictionary = bodyObject as? [String : AnyObject] else
            {

                PGSDKLogger.error("Camera Service: invalid POST body.");
                self.respondWithErrorStatus(HTTPStatusCode.BadRequest, response, responseReturn, requestComplete)
                return
            }

            /// Now we know that our path and method were correct, and we've handled error conditions, let's try opening camera

            let pmCamera = PMCamera.sharedInstance
            pmCamera.processRequest( bodyDictionary,

                errorReturn: { (error : NSData?) -> Void in

                    /// the default response object is always pre-set with a 200 (OK) response code, so can be directly used when there are no problems.
                    responseReturn(response)

                    /// we return the JSON object containing error details
                    dataReturn(error)

                    /// An inform the caller the service call is complete
                    requestComplete()
                },

                barcodeReturn: { (barcode : NSData?) -> Void in

                    /// the default response object is always pre-set with a 200 (OK) response code, so can be directly used when there are no problems.
                    responseReturn(response)

                    /// we return the JSON object for barcode
                    dataReturn(barcode)

                    /// An inform the caller the service call is complete
                    requestComplete()

                }
            )
        }
        catch let error
        {
            PGSDKLogger.error("Camera Service: error deserializing POST body: \(error)");
            self.respondWithErrorStatus(HTTPStatusCode.BadRequest, response, responseReturn, requestComplete)
            return
        }

    }


}

//MARK: PMCamera
/**
Responsible for camera access and scanning barcode
*/
class PMCamera: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPopoverControllerDelegate
{
    ///  a shared instance
    static let sharedInstance       = PMCamera()

    typealias barcodeReturnBlock    = (NSData?) -> Void
    typealias errorReturnBlock      = (NSData?) -> Void

    private var mErrorReturn:errorReturnBlock?
    private var mBarcodeReturn:barcodeReturnBlock?

    var picker:UIImagePickerController?=UIImagePickerController()
    weak var imageView: UIImageView!
    var popover:UIPopoverController?=nil

    private var responseData :[String : AnyObject]?
    private var topViewController: UIViewController?
    private var mOptions :[String : AnyObject]?

    private enum ResponseType : Int {

        case Photo_src
        case Photo_location

        case Video_src
        case Video_location

        case msg
        case error
    }

    private enum LocationType : Int {

        case Data
        case Location
        case Native
    }

    private enum State : Int {

        case IDLE
        case PROCESSING
    }

    private var state:State? = State.IDLE

    let FILE_NAME_SUFFIX    = "PM_CAMERA_"
    let imageDirName        = "images"
    let movDirName          = "mov"
    let maxImgFiles         = 5
    let maxVideoFiles       = 5
    var imageDirPath:String?
    var videoDirPath:String?

    override init() {

        imageDirPath = PMCamera.createDir(imageDirName)
        videoDirPath = PMCamera.createDir(movDirName)
    }

    /**
        TODO
    - Parameter errorReturnBlock      :   (NSData?) -> Void
    - Parameter barcodeReturnBlock    :   (NSData?) -> Void
    - Returns: :-)
    */
    func processRequest(options : Dictionary<String, AnyObject>, errorReturn : errorReturnBlock, barcodeReturn : barcodeReturnBlock)
    {
        guard self.state == State.IDLE else
        {
            sendBusyResponse(errorReturn)
            return
        }

        self.state = State.PROCESSING

        self.mErrorReturn   = errorReturn
        self.mBarcodeReturn = barcodeReturn
        self.mOptions       = options
        picker?.delegate    = self

        picker!.allowsEditing = self.getEditingAllowed()

        switch(self.getSourceType()) {

        case UIImagePickerControllerSourceType.Camera:
            self.picker!.sourceType = UIImagePickerControllerSourceType.Camera

            let mediaType = self.getMediaType()
            if(1 == mediaType) //its video
            {
                picker!.mediaTypes = [/*kUTTypeImage as String,*/ kUTTypeMovie as String, kUTTypeVideo as String]
            }
            openCamera()

        case UIImagePickerControllerSourceType.PhotoLibrary:
            self.picker!.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
            picker!.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String, kUTTypeVideo as String]
            openGallary()

        case UIImagePickerControllerSourceType.SavedPhotosAlbum:
            self.picker!.sourceType = UIImagePickerControllerSourceType.SavedPhotosAlbum
            picker!.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String, kUTTypeVideo as String]
            openGallary()

//        default:
//            self.sendResponse("Unknown source type option!", type: .error)

        }

    }

    //    MARK: private functions
    /**
    gets viewcontrolller which is presented on screen
    - Returns: UIViewController
    */
    internal func getTopVC() ->UIViewController
    {
        var toReturn:UIViewController?
        if let topController = UIApplication.sharedApplication().keyWindow?.rootViewController {
            if(topController.presentedViewController == nil)
            {
                toReturn = topController
            }

            else
            {
                while let presentedViewController = topController.presentedViewController {
                    toReturn = presentedViewController
                    break
                }
            }
        }
        return toReturn!
    }


    /**
     Busy error response
     - Parameter errorReturn: errorReturnBlock
    */
    private func sendBusyResponse(errorReturn : errorReturnBlock)
    {
        var busyRespData :[String : AnyObject]? = [String : AnyObject]()
        busyRespData!["error".lowercaseString] = "Already processing a request, Please try again."
        do
        {
            let toReturn = try NSJSONSerialization.dataWithJSONObject(busyRespData!, options: NSJSONWritingOptions(rawValue: 0))
            errorReturn(toReturn)

        }
        catch let error
        {
            PGSDKLogger.error("Error serializing busy response data into JSON: \(error)")
        }

    }

    /**
         returns a response to calling closure
        - Parameter msg: todo
        - Parameter type: todo
     */
    private func sendResponse(msg: String, type: ResponseType)
    {
        self.responseData = [String : AnyObject]()

        self.state = State.IDLE

        switch(type)
        {
            case .Photo_src:
                self.responseData!["image_src".lowercaseString] = msg

            case .Photo_location:
                self.responseData!["image_location".lowercaseString] = msg

            case .Video_src:
                self.responseData!["video_src".lowercaseString] = msg

            case .Video_location:
                self.responseData!["video_location".lowercaseString] = msg

            case .msg:
                self.responseData!["message".lowercaseString] = msg

            case .error:
                self.responseData!["error".lowercaseString] = msg
        }


        do
        {
            let toReturn = try NSJSONSerialization.dataWithJSONObject(self.responseData!, options: NSJSONWritingOptions(rawValue: 0))

            switch(type)
            {
                case .error:
                    self.mErrorReturn!(toReturn)

                case .Photo_src, .Photo_location, .Video_src, .Video_location, .msg:
                    self.mBarcodeReturn!(toReturn)
            }

        }
        catch let error
        {
            PGSDKLogger.error("Error serializing user data into JSON: \(error)")
        }

    }

//  MARK: Options parser
    /**
        Compression option
    - Returns : CGFloat
    */
    private func getCompression() ->CGFloat
    {
        var toReturn:CGFloat
        toReturn = 0.0
        if let compression = self.mOptions!["compression"] as? CGFloat
        {
            toReturn = compression/100

        }
        return toReturn
    }

    /**
         Source type option
     */
    private func getSourceType() ->UIImagePickerControllerSourceType
    {
        var toReturn:UIImagePickerControllerSourceType
        toReturn = UIImagePickerControllerSourceType.PhotoLibrary
        if let srcType = self.mOptions!["sourceType"] as? Int
        {
            toReturn = UIImagePickerControllerSourceType(rawValue: srcType)!

        }
        return toReturn
    }

    /**
     Media option
     */
    private func getMediaType() ->Int
    {
        var toReturn:Int
        toReturn = 0
        if let srcType = self.mOptions!["mediaType"] as? Int
        {
            toReturn = srcType

        }
        return toReturn
    }

    /**
         Output option
     */
    private func getOutputType() ->ResponseType
    {
        var toReturn:ResponseType
        toReturn = .error
        if let outputType = self.mOptions!["output"] as? Int
        {
//            toReturn = outputType ==
            switch(outputType) {

            case 0: //File URI
                toReturn = (0 == self.getMediaType()) ? .Photo_location : .Video_location

            case 1: // SRC
                toReturn = (0 == self.getMediaType()) ? .Photo_src : .error

            default:
                toReturn = .error
            }

        }
        return toReturn
    }

    /**
         Editing option

        - Returns: Bool
     */
    private func getEditingAllowed() ->Bool
    {
        var toReturn:Bool
        toReturn = false
        if let edit = self.mOptions!["edit"] as? Int
        {
            toReturn = (edit == 0) ? false : true

        }
        return toReturn
    }

//  TODO:
    private func getCameraDirection() ->Int
    {
        var toReturn:Int
        toReturn = 0
        if let cameraDirection = self.mOptions!["cameraDirection"] as? Int
        {
            toReturn = cameraDirection

        }
        return toReturn
    }





    func openCamera()
    {
        if(UIImagePickerController .isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera))
        {
            self.topViewController = getTopVC()
            dispatch_async(dispatch_get_main_queue()) {
                self.topViewController!.presentViewController(self.picker!, animated: true, completion: nil)
            }

        }
        else
        {
            PGSDKLogger.error("Camera not accessible!")
            self.sendResponse("Camera not accessible", type: .error)
        }
    }
    func openGallary()
    {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone
        {
            self.topViewController = getTopVC()
            dispatch_async(dispatch_get_main_queue()) {
                self.topViewController!.presentViewController(self.picker!, animated: true, completion: nil)
            }
        }
        else
        {
            self.topViewController = getTopVC()
            dispatch_async(dispatch_get_main_queue()) {
                self.popover=UIPopoverController(contentViewController: self.picker!)
                self.popover!.presentPopoverFromRect(CGRectMake(50.0, 50.0, 400, 400), inView: self.topViewController!.view, permittedArrowDirections: UIPopoverArrowDirection.Any, animated: true)
            }

        }
    }



//  MARK: image picker delegate

    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject])
    {
        picker .dismissViewControllerAnimated(true, completion: nil)

        var outputData:NSData?
        let mediaType = info[UIImagePickerControllerMediaType] as! NSString
        // Handle a movie capture
        if mediaType == kUTTypeMovie ||  mediaType == kUTTypeVideo
        {
            let path = (info[UIImagePickerControllerMediaURL] as! NSURL)
            outputData = NSData(contentsOfURL: path)!

        }
        else
        {
            let returnImg = info[UIImagePickerControllerOriginalImage] as? UIImage
            outputData = UIImageJPEGRepresentation(returnImg!, self.getCompression())
        }
        generateOutput(outputData!)
    }



    func imagePickerControllerDidCancel(picker: UIImagePickerController)
    {
        self.picker!.dismissViewControllerAnimated(true, completion: nil)
        self.sendResponse("User cancelled", type: .error)
        self.generateUniqueFilename(.error)
    }


    private func generateOutput(data: NSData)
    {
        switch(getOutputType())
        {
            case .Photo_src:
                print("send base64")
                let base64String = data.base64EncodedStringWithOptions(.Encoding64CharacterLineLength)
                self.sendResponse(base64String, type: .Photo_src)

            case .Photo_location:
                saveNSendResponse(data, type: .Photo_location)

            case .Video_location:
                saveNSendResponse(data, type: .Video_location)

            case .error, .msg, .Video_src:
                self.sendResponse("Unknown output format! 1", type: .error)

        }
    }




//   MARK: File handling

    /// Saves data in relevant format based on provided options and returns a response
    ///
    /// - Parameters:
    ///     - dataToBeWritten: image or video data which needs to be persisted
    ///     - type: type of response
    private func saveNSendResponse(dataToBeWritten: NSData, type: ResponseType)
    {
        let savePath = generateUniqueFilename(type)




        let isSaved = dataToBeWritten.writeToFile(savePath, atomically: true)
        if isSaved
        {
            switch(type)
            {

            case .Photo_location:
                self.sendResponse(savePath, type: .Photo_location)

            case .Video_location:
                self.sendResponse(savePath, type: .Video_location)

            case .Photo_src, .Video_src, .msg, .error:
                self.sendResponse("Unknown output format! 2", type: .error)
            }

        }
        else
        {
            self.sendResponse("Error in saving file!", type: .error)
        }
    }

    private func generateUniqueFilename(type: ResponseType) -> String {

        var extensionName:String?
        var documentPath:String?
        switch(type)
        {

            case .Photo_location:
                extensionName = "jpeg"
                documentPath = imageDirPath

            case .Video_location:
                extensionName = "mov"
            documentPath = videoDirPath

            case .Photo_src, .Video_src, .msg, .error:
                extensionName = "ERROR_FORMAT"
                documentPath = "ERROR_FORMAT"
        }

        let guid = NSProcessInfo.processInfo().globallyUniqueString
        let uniqueFileName = documentPath! + "/" + ("\(FILE_NAME_SUFFIX)\(guid).\(extensionName!)")

        print("uniqueFileName: \(uniqueFileName)")
//        self.listFiles(imageDirName)
        return uniqueFileName
    }

    private func listFiles(dirName: String)
    {
        // We need just to get the documents folder url

        let documentsUrl =  NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        var dataPath:NSURL
        if #available(iOS 9.0, *) {
            dataPath = NSURL(fileURLWithPath: dirName, isDirectory: true, relativeToURL: documentsUrl)
        } else {
            dataPath = documentsUrl.URLByAppendingPathComponent(dirName, isDirectory: true)//NSURL(fileURLWithPath: dirName, isDirectory: true)
        }

        print("documentsUrl: \(documentsUrl)")

        do {
            let directoryContents = try NSFileManager.defaultManager().contentsOfDirectoryAtURL(dataPath, includingPropertiesForKeys: nil, options: NSDirectoryEnumerationOptions())
            print("directoryContents: \(directoryContents)")

        } catch let error as NSError {
            print(error.localizedDescription)
        }

    }

    private func deleteFile(name:String)
    {
        let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        if paths.count > 0 {
            let dirPath = paths[0]
            let fileName = "someFileName"
            let filePath = NSString(format:"%@/%@.png", dirPath, fileName) as String
            if NSFileManager.defaultManager().fileExistsAtPath(filePath) {
                do {
                    try NSFileManager.defaultManager().removeItemAtPath(filePath)
                    print("old image has been removed")
                } catch {
                    print("an error during a removing")
                }
            }
        }

    }


    private static func createDir(dirName: String) -> String
    {
        let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let documentsDirectory: AnyObject = paths[0]
        let dataPath = documentsDirectory.stringByAppendingPathComponent(dirName)

        var isDir : ObjCBool = false

        if NSFileManager.defaultManager().fileExistsAtPath(dataPath, isDirectory: &isDir) {
            if isDir {
                // file exists & its a dir :-)
            } else {
                // file exists & isn't dir??? whoa- TODO:? :-(

            }
        }
        else {
            // file doesn't exist :-<
            do {
                try NSFileManager.defaultManager().createDirectoryAtPath(dataPath, withIntermediateDirectories: false, attributes: nil)
            } catch let error as NSError {
                print(error.localizedDescription);
            }
        }

        return dataPath

    }

}
