//
//  CameraService.swift
//  PredixMobileReferenceApp
//
//  Created by  on 2/23/16.
//  Copyright © 2016 GE. All rights reserved.
//

import Foundation
//import UIKit
//import MobileCoreServices
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
        */
//        guard path.lowercaseString == "/\(self.serviceIdentifier)" else
//        {
//            self.respondWithErrorStatus(.BadRequest, response, responseReturn, requestComplete)
//            return
//        }

//        let httpMethod = request.HTTPMethod ?? ""

        switch method
        {
            case "POST":
                handlePOSTRequest(request, response: response, responseReturn: responseReturn, dataReturn: dataReturn, requestComplete: requestComplete)

            case "DELETE":
                handleDELETERequest(request, response: response, responseReturn: responseReturn, dataReturn: dataReturn, requestComplete: requestComplete)

            case "GET":
                handleGETRequest(request, response: response, responseReturn: responseReturn, dataReturn: dataReturn, requestComplete: requestComplete)

            default:
                PGSDKLogger.error("Camera Service: Invalid HTTPmethod: \(request.HTTPMethod)")
                let headers = ["Allow" : "POST, DELETE, GET"]
                self.respondWithErrorStatus(.MethodNotAllowed, response, responseReturn, requestComplete, headers)
                return

        }

        /// now that we know our path is what we expect, we'll check the HTTP method. If it's anything other than "POST"
        /// we'll return a standard HTTP status used in that case.
//        guard method == "POST" else
//        {
//            /// According to the HTTP specification, a status code 405 (Method not allowed) must include an Allow header containing a list of valid methods.
//            /// this  demonstrates one way to accomplish this.
//            let headers = ["Allow" : "POST"]
//
//            /// This respondWithErrorStatus overload allows additional headers to be passed that will be added to the response.
//            self.respondWithErrorStatus(HTTPStatusCode.MethodNotAllowed, response, responseReturn, requestComplete, headers)
//            return
//        }



    }

    private static func handlePOSTRequest(request : NSURLRequest, response : NSHTTPURLResponse, responseReturn : responseReturnBlock, dataReturn : dataReturnBlock, requestComplete: requestCompleteBlock)
    {

        guard let url = request.URL where url.query == nil else
        {
            /// In this case, if the request URL is anything other than "http://pmapi/barcodescanner" we're returning a 400 status code.
            self.respondWithErrorStatus(.BadRequest, response, responseReturn, requestComplete)
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
            pmCamera.processPOSTRequest( bodyDictionary,

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

    private static func handleGETRequest(request : NSURLRequest, response : NSHTTPURLResponse, responseReturn : responseReturnBlock, dataReturn : dataReturnBlock, requestComplete: requestCompleteBlock)
    {
//        guard let url = request.URL where url.query != nil else
//        {
//            /// In this case, if the request URL is anything other than "http://pmapi/barcodescanner" we're returning a 400 status code.
//            self.respondWithErrorStatus(.BadRequest, response, responseReturn, requestComplete)
//            return
//        }
//        TODO:
        let pmCamera = PMCamera.sharedInstance
        pmCamera.processGETRequest((request.URL?.lastPathComponent)!,
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

    private static func handleDELETERequest(request : NSURLRequest, response : NSHTTPURLResponse, responseReturn : responseReturnBlock, dataReturn : dataReturnBlock, requestComplete: requestCompleteBlock)
    {
        let pmCamera = PMCamera.sharedInstance
        pmCamera.processDeleteRequest((request.URL?.lastPathComponent)!,
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

}
