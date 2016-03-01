//  PMCamera.swift
//
//  PredixMobileReferenceApp
//
//  Created by  on 2/29/16.
//  Copyright © 2016 GE. All rights reserved.
//

import Foundation
import UIKit
import MobileCoreServices
import PredixMobileSDK

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

    var picker:UIImagePickerController?
    weak var imageView: UIImageView!
    var popover:UIPopoverController?=nil

    private var responseData :[String : AnyObject]?
    private var topViewController: UIViewController?
    private var mOptions :[String : AnyObject]?



    private var state:State? = State.IDLE



    private var photoDirPath:String?
    private var videoDirPath:String?

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

//    private enum xxx : Int
//    {
//        case Photo
//        case Video
//    }

    override init() {
        self.picker=UIImagePickerController()

        do
        {
            //            try PMCamera.listFiles(PMCamera.imageDirName)
            try photoDirPath = PMCamera.createDir(PMCamera.photoDirName)
            try videoDirPath = PMCamera.createDir(PMCamera.videoDirName)

        }
        catch let error as NSError
        {
            print("an error during PMCamera initialization:- \(error.localizedDescription)")


        }
    }

    /**
     TODO
     - Parameter errorReturnBlock      :   (NSData?) -> Void
     - Parameter barcodeReturnBlock    :   (NSData?) -> Void
     - Returns: :-)
     */
    func processPOSTRequest(options : Dictionary<String, AnyObject>, errorReturn : errorReturnBlock, barcodeReturn : barcodeReturnBlock)
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
            //            self.picker!.sourceType = UIImagePickerControllerSourceType.Camera

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

    /**
     TODO
     - Parameter errorReturnBlock      :   (NSData?) -> Void
     - Parameter barcodeReturnBlock    :   (NSData?) -> Void
     - Returns: :-)
     */
    func processGETRequest(entity : String, errorReturn : errorReturnBlock, barcodeReturn : barcodeReturnBlock)
    {
        guard self.state == State.IDLE else
        {
            sendBusyResponse(errorReturn)
            return
        }

        self.state = State.PROCESSING

        self.mErrorReturn   = errorReturn
        self.mBarcodeReturn = barcodeReturn

        switch (entity)
        {
            case "image":
                do
                {
                    let files = try PMCamera.getFileURLs(.Photo_location)
                    self.sendResponse(convert(files), type: .Photo_location)
                }
                catch let err as NSError
                {
                    self.sendResponse("\(err)", type: .error)
                }

            case "video":
                do
                {
                    let files = try PMCamera.getFileURLs(.Video_location)
                    self.sendResponse(convert(files), type: .Video_location)
                }
                catch let err as NSError
                {
                    self.sendResponse("\(err)", type: .error)
                }

            default:
                self.sendResponse("Unknown source type option!", type: .error)
        }
    }



    //    MARK: private functions
    /**
    gets viewcontrolller which is presented on screen
    - Returns: UIViewController
    */

    private func convert(filesPath: [NSURL]) -> String
    {
        var toReturn:String = ""
        if filesPath.count < 1
        {
            toReturn = "No files yet..."
        }

        for path : NSURL in filesPath {
            toReturn = toReturn + path.absoluteString + ","
        }
        return toReturn
    }
    private func getTopVC() ->UIViewController
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







    func openCamera()
    {
        if(UIImagePickerController .isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera))
        {
            self.picker!.sourceType = UIImagePickerControllerSourceType.Camera
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
            self.mOptions!["mediaType"] = 1 // Overriding options based on what we received from Picker

        }
        else
        {
            self.mOptions!["mediaType"] = 0 // Overriding options based on what we received from Picker
            let returnImg = info[UIImagePickerControllerOriginalImage] as? UIImage
            outputData = UIImageJPEGRepresentation(returnImg!, self.getCompression())
        }
        generateOutput(outputData!)
    }



    func imagePickerControllerDidCancel(picker: UIImagePickerController)
    {
        self.picker!.dismissViewControllerAnimated(true, completion: nil)
        self.sendResponse("User cancelled", type: .error)
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

    //  MARK: Options parser - Seperate Class^
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




    //   MARK: File handling - Seperate Class^

    static let FILE_NAME_SUFFIX    = "PM_CAMERA_"
    static let photoDirName        = "image"
    static let videoDirName        = "video"
    static let maxImgFiles         = 100
    static let maxMovFiles         = 20

    enum PMCameraError : ErrorType {
        case FileHandlingError(String)
        case MaxCacheError(String)
    }

    /// Saves data in relevant format based on provided options and returns a response
    ///
    /// - Parameters:
    ///     - dataToBeWritten: image or video data which needs to be persisted
    ///     - type: type of response
    private func saveNSendResponse(dataToBeWritten: NSData, type: ResponseType)
    {
        do
        {
            let savePath = try generateUniqueFilename(type)
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
        catch PMCameraError.FileHandlingError(let errorMsg)
        {
            self.sendResponse("\(errorMsg)", type: .error)
        }
        catch PMCameraError.MaxCacheError(let errorMsg)
        {
            self.sendResponse("\(errorMsg)", type: .error)
        }
        catch let error as NSError
        {
            self.sendResponse("\(error.localizedDescription)", type: .error)
        }



    }

    /**
     Generates a unique name for image/mov types
     - Parameter type      :   Photo_location / Video_location
     - Returns: filename as String
     */
    private func generateUniqueFilename(type: ResponseType) throws -> String {
        do
        {
            if try PMCamera.isFileCacheLimitReached(type)
            {
                throw PMCameraError .MaxCacheError("Max limit of storage reached. Try deleting few files first.")
            }


        }
        catch let error as NSError
        {
            throw error
        }
        var extensionName:String?
        var documentPath:String?
        switch(type)
        {

        case .Photo_location:
            extensionName = "jpeg"
            documentPath = photoDirPath

        case .Video_location:
            extensionName = "mov"
            documentPath = videoDirPath

        case .Photo_src, .Video_src, .msg, .error:
            throw PMCameraError .FileHandlingError("Invalid option in file generation!!")
            //                extensionName = "ERROR_FORMAT"
            //                documentPath = "ERROR_FORMAT"
        }

        let guid = NSProcessInfo.processInfo().globallyUniqueString
        let uniqueFileName = documentPath! + "/" + ("\(PMCamera.FILE_NAME_SUFFIX)\(guid).\(extensionName!)")

        print("uniqueFileName: \(uniqueFileName)")
        //        self.listFiles(imageDirName)
        return uniqueFileName
    }

    /**
     Creates a directiory in PMCamera specific folder
     - Parameter dirName      :   directory name
     - Returns: path to directory as String
     */
    private static func createDir(dirName: String) throws -> String
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
                print(error.localizedDescription)
                throw error
            }
        }

        return dataPath

    }

    /**
     Crawls through all files in PMCamera
     - Parameter type      :   Imahe or Mov dir
     - Returns: ^
     */
    private static func isFileCacheLimitReached(type: ResponseType) throws -> Bool
    {
        return false

        var dirName:String?
        switch(type)
        {

        case .Photo_location:
            dirName = photoDirName
        case .Video_location:
            dirName = videoDirName

        case .Photo_src, .Video_src, .msg, .error:
            throw PMCameraError.FileHandlingError("Invalid option in response type!")
        }
        var toReturn:Bool = false
        do
        {

            let files = try PMCamera.getFileURLs(type)
            if dirName == photoDirName && files.count >= maxImgFiles
            {
                toReturn = true
            }
            else if dirName == videoDirName && files.count >= maxMovFiles
            {
                toReturn = true
            }
        }
        catch let error as NSError
        {
            throw error
        }

        return toReturn
    }

    /**
     Crawls through all files in PMCamera
     - Parameter type      :   Imahe or Mov dir
     - Returns: ^
     */
    private static func getFileURLs(type: ResponseType) throws -> [NSURL]
    {

        var dirName:String?
        switch(type)
        {

        case .Photo_location:
            dirName = photoDirName
        case .Video_location:
            dirName = videoDirName

        case .Photo_src, .Video_src, .msg, .error:
            throw PMCameraError.FileHandlingError("Invalid option in response type!")
        }

        var toReturn:[NSURL]
        let documentsUrl =  NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        var dataPath:NSURL
        if #available(iOS 9.0, *) {
            dataPath = NSURL(fileURLWithPath: dirName!, isDirectory: true, relativeToURL: documentsUrl)
        } else {
            dataPath = documentsUrl.URLByAppendingPathComponent(dirName!, isDirectory: true)//NSURL(fileURLWithPath: dirName, isDirectory: true)
        }

//        print("documentsUrl: \(documentsUrl)")

        do {
            toReturn = try NSFileManager.defaultManager().contentsOfDirectoryAtURL(dataPath, includingPropertiesForKeys: nil, options: NSDirectoryEnumerationOptions())

        } catch let error as NSError {
            print(error.localizedDescription)
            throw error
        }

        return toReturn
    }

    /**
     Deletes a given file from a PMCamera specific dir
     - Parameter name      :   file name with extension
     - Returns: ^
     */
    private func deleteFile(name:String) throws
    {
        let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        if paths.count > 0 {
            let dirPath = paths[0]
            let fileName = "someFileName"
            let filePath = NSString(format:"%@/%@.png", dirPath, fileName) as String
            if NSFileManager.defaultManager().fileExistsAtPath(filePath) {
                do {
                    try NSFileManager.defaultManager().removeItemAtPath(filePath)
                    print("old photo has been removed")

                } catch let error as NSError{
                    print("an error during a removing:- \(error.localizedDescription)")
                    throw error
                }
            }
        }

    }

}
