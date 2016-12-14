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
Responsible for camera access
*/
class PMCamera: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate
{
    ///  a shared instance
    static let sharedInstance       = PMCamera()

    typealias successReturnBlock    = (Data?) -> Void
    typealias errorReturnBlock      = (Data?) -> Void

    fileprivate var mErrorReturn:errorReturnBlock?
    fileprivate var mSuccessReturn:successReturnBlock?

    var picker:UIImagePickerController?
    weak var imageView: UIImageView!

    fileprivate var responseData :[String : AnyObject]?
    fileprivate var topViewController: UIViewController?
    fileprivate var mOptions :[String : Any]?
    fileprivate var state:State? = State.idle



    fileprivate var photoDirPath:String?
    fileprivate var videoDirPath:String?

    fileprivate enum ResponseType : Int {

        case photo_src
        case photo_location

        case video_src
        case video_location

        case msg
        case error
    }

    fileprivate enum LocationType : Int {

        case data
        case location
        case native
    }

    fileprivate enum State : Int {

        case idle
        case processing
    }

    override init() {
        self.picker=UIImagePickerController()

        do
        {
            try self.photoDirPath = PMCamera.createDir(PMCamera.photoDirName)
            try self.videoDirPath = PMCamera.createDir(PMCamera.videoDirName)

        }
        catch let error
        {
            print("an error during PMCamera initialization:- \(error.localizedDescription)")
        }
    }

    /**
     TODO
     - Parameter errorReturnBlock      :   (Data?) -> Void
     - Parameter successReturnBlock    :   (Data?) -> Void
     - Returns: :-)
     */
    func processPOSTRequest(_ options : [String: Any], errorReturn : @escaping errorReturnBlock, successReturn : @escaping successReturnBlock)
    {
        guard self.state == State.idle else
        {
            sendBusyResponse(errorReturn)
            return
        }

        self.state = State.processing

        self.mErrorReturn   = errorReturn
        self.mSuccessReturn = successReturn
        self.mOptions       = options
        picker?.delegate    = self

        picker!.allowsEditing = self.getEditingAllowed()

        switch(self.getSourceType()) {

        case UIImagePickerControllerSourceType.camera:
            //            self.picker!.sourceType = UIImagePickerControllerSourceType.Camera

            let mediaType = self.getMediaType()
            if(1 == mediaType) //its video
            {
                picker!.mediaTypes = [/*kUTTypeImage as String,*/ kUTTypeMovie as String, kUTTypeVideo as String]
            }
            openCamera()

        case UIImagePickerControllerSourceType.photoLibrary:
            self.picker!.sourceType = UIImagePickerControllerSourceType.photoLibrary
            picker!.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String, kUTTypeVideo as String]
            openGallary()

        case UIImagePickerControllerSourceType.savedPhotosAlbum:
            self.picker!.sourceType = UIImagePickerControllerSourceType.savedPhotosAlbum
            picker!.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String, kUTTypeVideo as String]
            openGallary()
        }

    }

    /**
     Handels GET request
     - Parameter errorReturnBlock      :   (Data?) -> Void
     - Parameter successReturnBlock    :   (Data?) -> Void
     - Returns: :-)
     */
    func processGETRequest(_ entity : String, errorReturn : @escaping errorReturnBlock, successReturn : @escaping successReturnBlock)
    {
        guard self.state == State.idle else
        {
            sendBusyResponse(errorReturn)
            return
        }

        self.state = State.processing

        self.mErrorReturn   = errorReturn
        self.mSuccessReturn = successReturn

        switch (entity)
        {
            case "image":
                do
                {
                    let files = try PMCamera.getFileURLs(.photo_location)
                    self.sendResponse(convert(files), type: .photo_location)
                }
                catch PMCameraError.fileHandlingError(let errorMsg)
                {
                    self.sendResponse("\(errorMsg)", type: .error)
                }
                catch PMCameraError.maxCacheError(let errorMsg)
                {
                    self.sendResponse("\(errorMsg)", type: .error)
                }
                catch let error
                {
                    self.sendResponse("\(error.localizedDescription)", type: .error)
                }


            case "video":
                do
                {
                    let files = try PMCamera.getFileURLs(.video_location)
                    self.sendResponse(convert(files), type: .video_location)
                }
                catch PMCameraError.fileHandlingError(let errorMsg)
                {
                    self.sendResponse("\(errorMsg)", type: .error)
                }
                catch PMCameraError.maxCacheError(let errorMsg)
                {
                    self.sendResponse("\(errorMsg)", type: .error)
                }
                catch let error
                {
                    self.sendResponse("\(error.localizedDescription)", type: .error)
                }


            default:
                self.sendResponse("Unknown source type option!", type: .error)
        }
    }

    /**
     Handels GET request
     - Parameter errorReturnBlock      :   (Data?) -> Void
     - Parameter successReturnBlock    :   (Data?) -> Void
     - Returns: :-)
     */
    func processDeleteRequest(_ entity : String, errorReturn : @escaping errorReturnBlock, successReturn : @escaping successReturnBlock)
    {
        guard self.state == State.idle else
        {
            sendBusyResponse(errorReturn)
            return
        }

        self.state = State.processing

        self.mErrorReturn   = errorReturn
        self.mSuccessReturn = successReturn

        switch (entity)
        {
        case "image":
            do
            {
                try PMCamera.deleteFiles(.photo_location)
                self.sendResponse("Files deleted successfully", type: .msg)
            }catch PMCameraError.fileHandlingError(let errorMsg)
            {
                self.sendResponse("\(errorMsg)", type: .error)
            }
            catch PMCameraError.maxCacheError(let errorMsg)
            {
                self.sendResponse("\(errorMsg)", type: .error)
            }
            catch let error
            {
                self.sendResponse("\(error.localizedDescription)", type: .error)
            }


        case "video":
            do
            {
                try PMCamera.deleteFiles(.video_location)
                self.sendResponse("Files deleted successfully", type: .msg)
            }catch PMCameraError.fileHandlingError(let errorMsg)
            {
                self.sendResponse("\(errorMsg)", type: .error)
            }
            catch PMCameraError.maxCacheError(let errorMsg)
            {
                self.sendResponse("\(errorMsg)", type: .error)
            }
            catch let error
            {
                self.sendResponse("\(error.localizedDescription)", type: .error)
            }


        default: //TODO: functionality to delete a single file
            self.sendResponse("Unknown source type option in file delete!", type: .error)
        }
    }


    //    MARK: private functions
    /**
    Converts [URL] to String
    - Parameter filesPath: an array containing files path
    - Returns: String
    */

    fileprivate func convert(_ filesPath: [URL]) -> String
    {
        var toReturn:String = ""
        if filesPath.count < 1
        {
            toReturn = "No files yet..."
        }

        for path : URL in filesPath {
            toReturn = toReturn + path.absoluteString + ","
        }
        return toReturn
    }

    /**
     Top View controller
     - Returns: UIViewController
     */
    fileprivate func getTopVC() ->UIViewController
    {
        var toReturn:UIViewController?
        if let topController = UIApplication.shared.keyWindow?.rootViewController {
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
    fileprivate func sendBusyResponse(_ errorReturn : errorReturnBlock)
    {
        var busyRespData :[String : AnyObject]? = [String : AnyObject]()
        busyRespData!["error".lowercased()] = "Already processing a request, Please try again." as AnyObject?
        do
        {
            let toReturn = try JSONSerialization.data(withJSONObject: busyRespData!, options: JSONSerialization.WritingOptions(rawValue: 0))
            errorReturn(toReturn)

        }
        catch let error
        {
            Logger.error("Error serializing busy response data into JSON: \(error)")
        }

    }

    /**
     returns a response to calling closure
     - Parameter msg: message which will be sent back
     - Parameter type: type of message
     */
    fileprivate func sendResponse(_ msg: String, type: ResponseType)
    {
        self.responseData = [String : AnyObject]()

        self.state = State.idle

        switch(type)
        {
        case .photo_src:
            self.responseData!["image_src".lowercased()] = msg as AnyObject?

        case .photo_location:
            self.responseData!["image_location".lowercased()] = msg as AnyObject?

        case .video_src:
            self.responseData!["video_src".lowercased()] = msg as AnyObject?

        case .video_location:
            self.responseData!["video_location".lowercased()] = msg as AnyObject?

        case .msg:
            self.responseData!["message".lowercased()] = msg as AnyObject?

        case .error:
            self.responseData!["error".lowercased()] = msg as AnyObject?
        }


        do
        {
            let toReturn = try JSONSerialization.data(withJSONObject: self.responseData!, options: JSONSerialization.WritingOptions(rawValue: 0))

            switch(type)
            {
            case .error:
                self.mErrorReturn!(toReturn)

            case .photo_src, .photo_location, .video_src, .video_location, .msg:
                self.mSuccessReturn!(toReturn)
            }

        }
        catch let error
        {
            Logger.error("Error serializing user data into JSON: \(error)")
        }

    }







    func openCamera()
    {
        if(UIImagePickerController .isSourceTypeAvailable(UIImagePickerControllerSourceType.camera))
        {
            self.picker!.sourceType = UIImagePickerControllerSourceType.camera
            self.topViewController = getTopVC()
            DispatchQueue.main.async {
                self.topViewController!.present(self.picker!, animated: true, completion: nil)
            }

        }
        else
        {
            Logger.error("Camera not accessible!")
            self.sendResponse("Camera not accessible", type: .error)
        }
    }
    func openGallary()
    {
        if UIDevice.current.userInterfaceIdiom == .phone
        {
            self.topViewController = getTopVC()
            DispatchQueue.main.async {
                self.topViewController!.present(self.picker!, animated: true, completion: nil)
            }
        }
        else
        {
            self.topViewController = getTopVC()
            DispatchQueue.main.async {
                
                self.picker!.modalPresentationStyle = .popover
                self.picker!.popoverPresentationController?.sourceView = self.topViewController!.view
                self.topViewController!.present(self.picker!, animated: true, completion: nil)
                //self.popover=UIPopoverController(contentViewController: self.picker!)
                //self.popover!.present(from: CGRect(x: 50.0, y: 50.0, width: 400, height: 400), in: self.topViewController!.view, permittedArrowDirections: UIPopoverArrowDirection.any, animated: true)
            }

        }
    }



    //  MARK: image picker delegate

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any])
    {
        picker .dismiss(animated: true, completion: nil)

        var outputData:Data?
        let mediaType = info[UIImagePickerControllerMediaType] as! String
        // Handle a movie capture
        if mediaType == kUTTypeMovie as String ||  mediaType == kUTTypeVideo as String
        {
            let path = (info[UIImagePickerControllerMediaURL] as! URL)
            outputData = try! Data(contentsOf: path)
            self.mOptions!["mediaType"] = 1 as AnyObject? // Overriding options based on what we received from Picker

        }
        else
        {
            self.mOptions!["mediaType"] = 0 as AnyObject? // Overriding options based on what we received from Picker
            let returnImg = info[UIImagePickerControllerOriginalImage] as? UIImage
            outputData = UIImageJPEGRepresentation(returnImg!, self.getCompression())
        }
        generateOutput(outputData!)
    }



    func imagePickerControllerDidCancel(_ picker: UIImagePickerController)
    {
        self.picker!.dismiss(animated: true, completion: nil)
        self.sendResponse("User cancelled", type: .error)
    }


    fileprivate func generateOutput(_ data: Data)
    {
        switch(getOutputType())
        {
        case .photo_src:
            print("send base64")
            let base64String = data.base64EncodedString(options: .lineLength64Characters)
            self.sendResponse(base64String, type: .photo_src)

        case .photo_location:
            saveNSendResponse(data, type: .photo_location)

        case .video_location:
            saveNSendResponse(data, type: .video_location)

        case .error, .msg, .video_src:
            self.sendResponse("Unknown output format! 1", type: .error)

        }
    }

    //  MARK: Options parser - Seperate Class^
    /**
    Compression option
    - Returns : CGFloat
    */
    fileprivate func getCompression() ->CGFloat
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
    fileprivate func getSourceType() ->UIImagePickerControllerSourceType
    {
        var toReturn:UIImagePickerControllerSourceType
        toReturn = UIImagePickerControllerSourceType.photoLibrary
        if let srcType = self.mOptions!["sourceType"] as? Int
        {
            toReturn = UIImagePickerControllerSourceType(rawValue: srcType)!

        }
        return toReturn
    }

    /**
     Media option
     */
    fileprivate func getMediaType() ->Int
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
    fileprivate func getOutputType() ->ResponseType
    {
        var toReturn:ResponseType
        toReturn = .error
        if let outputType = self.mOptions!["output"] as? Int
        {
            //            toReturn = outputType ==
            switch(outputType) {

            case 0: //File URI
                toReturn = (0 == self.getMediaType()) ? .photo_location : .video_location

            case 1: // SRC
                toReturn = (0 == self.getMediaType()) ? .photo_src : .error

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
    fileprivate func getEditingAllowed() ->Bool
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
    fileprivate func getCameraDirection() ->Int
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

    enum PMCameraError : Error {
        case fileHandlingError(String)
        case maxCacheError(String)
    }

    /// Saves data in relevant format based on provided options and returns a response
    ///
    /// - Parameters:
    ///     - dataToBeWritten: image or video data which needs to be persisted
    ///     - type: type of response
    fileprivate func saveNSendResponse(_ dataToBeWritten: Data, type: ResponseType)
    {
        do
        {
            let savePath = try generateUniqueFilename(type)
            let isSaved = (try? dataToBeWritten.write(to: URL(fileURLWithPath: savePath), options: [.atomic])) != nil
            if isSaved
            {
                switch(type)
                {

                case .photo_location:
                    self.sendResponse(savePath, type: .photo_location)

                case .video_location:
                    self.sendResponse(savePath, type: .video_location)

                case .photo_src, .video_src, .msg, .error:
                    self.sendResponse("Unknown output format! 2", type: .error)
                }

            }
            else
            {
                self.sendResponse("Error in saving file!", type: .error)
            }

        }
        catch PMCameraError.fileHandlingError(let errorMsg)
        {
            self.sendResponse("\(errorMsg)", type: .error)
        }
        catch PMCameraError.maxCacheError(let errorMsg)
        {
            self.sendResponse("\(errorMsg)", type: .error)
        }
        catch let error
        {
            self.sendResponse("\(error.localizedDescription)", type: .error)
        }



    }

    /**
     Generates a unique name for image/mov types
     - Parameter type      :   Photo_location / Video_location
     - Returns: filename as String
     */
    fileprivate func generateUniqueFilename(_ type: ResponseType) throws -> String {
        do
        {
            if try PMCamera.isFileCacheLimitReached(type)
            {
                throw PMCameraError .maxCacheError("Max limit of storage reached. Try deleting few files first.")
            }


        }
        catch let error
        {
            throw error
        }
        var extensionName:String?
        var documentPath:String?
        switch(type)
        {

        case .photo_location:
            extensionName = "jpeg"
            documentPath = photoDirPath

        case .video_location:
            extensionName = "mov"
            documentPath = videoDirPath

        case .photo_src, .video_src, .msg, .error:
            throw PMCameraError .fileHandlingError("Invalid option in file generation!!")
            //                extensionName = "ERROR_FORMAT"
            //                documentPath = "ERROR_FORMAT"
        }

        let guid = ProcessInfo.processInfo.globallyUniqueString
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
    fileprivate static func createDir(_ dirName: String) throws -> String
    {
        let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        let documentsDirectory = paths[0]
        let dataPath = documentsDirectory.appending("/").appending(dirName)
        
        var isDir : ObjCBool = false

        if FileManager.default.fileExists(atPath: dataPath, isDirectory: &isDir) {
            if isDir.boolValue {
                // file exists & its a dir :-)
            } else {
                // file exists & isn't dir??? whoa- TODO:? :-(

            }
        }
        else {
            // file doesn't exist :-<
            do {
                try FileManager.default.createDirectory(atPath: dataPath, withIntermediateDirectories: false, attributes: nil)
            } catch let error {
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
    fileprivate static func isFileCacheLimitReached(_ type: ResponseType) throws -> Bool
    {
        return false

        var dirName:String?
        switch(type)
        {

        case .photo_location:
            dirName = photoDirName
        case .video_location:
            dirName = videoDirName

        case .photo_src, .video_src, .msg, .error:
            throw PMCameraError.fileHandlingError("Invalid option in response type!")
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
        catch let error
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
    fileprivate static func getFileURLs(_ type: ResponseType) throws -> [URL]
    {

        var dirName:String?
        switch(type)
        {

        case .photo_location:
            dirName = photoDirName
        case .video_location:
            dirName = videoDirName

        case .photo_src, .video_src, .msg, .error:
            throw PMCameraError.fileHandlingError("Invalid option in response type!")
        }

        var toReturn:[URL]
        let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        var dataPath:URL
        if #available(iOS 9.0, *) {
            dataPath = URL(fileURLWithPath: dirName!, isDirectory: true, relativeTo: documentsUrl)
        } else {
            dataPath = documentsUrl.appendingPathComponent(dirName!, isDirectory: true)
        }

        do {
            toReturn = try FileManager.default.contentsOfDirectory(at: dataPath, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions())

        } catch let error {
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
    fileprivate static func deleteFiles(_ type: ResponseType) throws
    {
        do
        {

            let files:[URL] = try PMCamera.getFileURLs(type)
            if files.count < 1
            {
                throw PMCameraError.fileHandlingError("No file cached!")
            }
            for path : URL in files {
                let slicedPath:String = path.absoluteString.replacingOccurrences(of: "file://", with: "")
                if FileManager.default.fileExists(atPath: slicedPath)
                {
                    try FileManager.default.removeItem(atPath: slicedPath)
                    print("old photo has been removed")
                }
            }

        }

        catch let error
        {
            throw error
        }
    }

    fileprivate static func deleteFile(_ name:String) throws
    {
        let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        if paths.count > 0 {
            let dirPath = paths[0]
            let fileName = "someFileName"
            let filePath = String(format:"%@/%@.png", dirPath, fileName)
            if FileManager.default.fileExists(atPath: filePath) {
                do {
                    try FileManager.default.removeItem(atPath: filePath)
                    print("old photo has been removed")

                } catch let error {
                    print("an error during a removing:- \(error.localizedDescription)")
                    throw error
                }
            }
        }

    }

}
