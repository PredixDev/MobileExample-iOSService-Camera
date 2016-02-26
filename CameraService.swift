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

    /**
        TODO
    - parameter:
    - errorReturnBlock      :   (NSData?) -> Void
    - barcodeReturnBlock    :   (NSData?) -> Void
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

    /**
        Video Save function
    */
    func video(videoPath: NSString, didFinishSavingWithError error: NSError?, contextInfo info: AnyObject) {
        guard error == nil else
        {
            self.sendResponse("Error saving video! \(error)", type: .error)
            return
        }
        self.sendResponse(videoPath as String, type: .Video_location)

    }


//  MARK: image picker delegate
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject])
    {
        picker .dismissViewControllerAnimated(true, completion: nil)

//        if(self.getSourceType())
//        {
//
//        }

        let mediaType = info[UIImagePickerControllerMediaType] as! NSString
        // Handle a movie capture
        if mediaType == kUTTypeMovie ||  mediaType == kUTTypeVideo
        {
            let path = (info[UIImagePickerControllerMediaURL] as! NSURL).path
            if UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(path!) {
                UISaveVideoAtPathToSavedPhotosAlbum(path!, self, "video:didFinishSavingWithError:contextInfo:", nil)
//                self.sendResponse(path!, isError: false)
            }
            else
            {
                PGSDKLogger.error("Error in saving video!");
                self.sendResponse("Error in saving video!",type: .error)
            }
        }
        else
        {
    //        imageView.image=info[UIImagePickerControllerOriginalImage] as? UIImage
            let returnImg = info[UIImagePickerControllerOriginalImage] as? UIImage
    //        let imageData = UIImagePNGRepresentation(returnImg!)
            let imageData = UIImageJPEGRepresentation(returnImg!, self.getCompression())
            let base64String = imageData!.base64EncodedStringWithOptions(.Encoding64CharacterLineLength)
            self.sendResponse(base64String, type: .Photo_src)
        }
    }



    func imagePickerControllerDidCancel(picker: UIImagePickerController)
    {
        self.picker!.dismissViewControllerAnimated(true, completion: nil)
//        PGSDKLogger.error("User cancelled!");
        self.sendResponse("User cancelled", type: .error)
    }

}
