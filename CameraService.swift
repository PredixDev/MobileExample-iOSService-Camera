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
    static var serviceIdentifier: String {get { return "camera" }}

    // MARK: performRequest - entry point for request
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
    static func performRequest(_ request: URLRequest, response: HTTPURLResponse, responseReturn : @escaping responseReturnBlock, dataReturn : @escaping dataReturnBlock, requestComplete: @escaping requestCompleteBlock) {

        /// First let's examine the request. In this example, we're going to expect only a GET request, and the URL path should only be the serviceIdentifier

        /// we'll use a guard statement here just to verify the request object is valid. The HTTPMethod and URL properties of a NSURLRequest
        /// are optional, and we need to ensure we're dealing with a request that contains them.
        guard let _ = request.url, let method = request.httpMethod else {
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
            self.respondWithErrorStatus(.badRequest, response, responseReturn, requestComplete)
            return
        }

        switch method {
            case "POST":
                handlePOSTRequest(request, response: response, responseReturn: responseReturn, dataReturn: dataReturn, requestComplete: requestComplete)

            case "DELETE":
                handleDELETERequest(request, response: response, responseReturn: responseReturn, dataReturn: dataReturn, requestComplete: requestComplete)

            case "GET":
                handleGETRequest(request, response: response, responseReturn: responseReturn, dataReturn: dataReturn, requestComplete: requestComplete)

            default:
                Logger.error("Camera Service: Invalid HTTPmethod: \(method)")
                let headers = ["Allow": "POST, DELETE, GET"]
                self.respondWithErrorStatus(.methodNotAllowed, response, responseReturn, requestComplete, headers)
                return

        }

    }

    fileprivate static func handlePOSTRequest(_ request: URLRequest, response: HTTPURLResponse, responseReturn : @escaping responseReturnBlock, dataReturn : @escaping dataReturnBlock, requestComplete: @escaping requestCompleteBlock) {

        guard let _ = request.url, let bodyData = request.httpBody else {
            Logger.error("Camera Service: No body preset")
            self.respondWithErrorStatus(.badRequest, response, responseReturn, requestComplete)
            return
        }

        do {
            let bodyObject = try JSONSerialization.jsonObject(with: bodyData, options: JSONSerialization.ReadingOptions.allowFragments)
            guard let bodyDictionary = bodyObject as? [String : Any] else {

                Logger.error("Camera Service: invalid POST body.")
                self.respondWithErrorStatus(.badRequest, response, responseReturn, requestComplete)
                return
            }

            /// Now we know that our request is understood, and we've handled error conditions, let's try opening camera

            let pmCamera = PMCamera.sharedInstance
            pmCamera.processPOSTRequest( bodyDictionary,

                errorReturn: { (error : Data?) -> Void in

                    /// the default response object is always pre-set with a 200 (OK) response code, so can be directly used when there are no problems.
                    responseReturn(response)

                    /// we return the JSON object containing error details
                    dataReturn(error)

                    /// An inform the caller the service call is complete
                    requestComplete()
                },

                successReturn: { (data: Data?) -> Void in

                    /// the default response object is always pre-set with a 200 (OK) response code, so can be directly used when there are no problems.
                    responseReturn(response)

                    /// we return the JSON object for data
                    dataReturn(data)

                    /// An inform the caller the service call is complete
                    requestComplete()

                }
            )
        } catch let error {
            Logger.error("Camera Service: error deserializing POST body: \(error)")
            self.respondWithErrorStatus(.badRequest, response, responseReturn, requestComplete)
            return
        }
    }

    fileprivate static func handleGETRequest(_ request: URLRequest, response: HTTPURLResponse, responseReturn : @escaping responseReturnBlock, dataReturn : @escaping dataReturnBlock, requestComplete: @escaping requestCompleteBlock) {

        let pmCamera = PMCamera.sharedInstance
        pmCamera.processGETRequest((request.url?.lastPathComponent)!,
            errorReturn: { (error : Data?) -> Void in

                /// the default response object is always pre-set with a 200 (OK) response code, so can be directly used when there are no problems.
                responseReturn(response)

                /// we return the JSON object containing error details
                dataReturn(error)

                /// An inform the caller the service call is complete
                requestComplete()
            },

            successReturn: { (data: Data?) -> Void in

                /// the default response object is always pre-set with a 200 (OK) response code, so can be directly used when there are no problems.
                responseReturn(response)

                /// we return the JSON object for data
                dataReturn(data)

                /// An inform the caller the service call is complete
                requestComplete()

            }
        )
    }

    fileprivate static func handleDELETERequest(_ request: URLRequest, response: HTTPURLResponse, responseReturn : @escaping responseReturnBlock, dataReturn : @escaping dataReturnBlock, requestComplete: @escaping requestCompleteBlock) {
        let pmCamera = PMCamera.sharedInstance
        pmCamera.processDeleteRequest((request.url?.lastPathComponent)!,
            errorReturn: { (error : Data?) -> Void in

                /// the default response object is always pre-set with a 200 (OK) response code, so can be directly used when there are no problems.
                responseReturn(response)

                /// we return the JSON object containing error details
                dataReturn(error)

                /// An inform the caller the service call is complete
                requestComplete()
            },

            successReturn: { (data: Data?) -> Void in

                /// the default response object is always pre-set with a 200 (OK) response code, so can be directly used when there are no problems.
                responseReturn(response)

                /// we return the JSON object for data
                dataReturn(data)

                /// An inform the caller the service call is complete
                requestComplete()

            }
        )
    }

}
