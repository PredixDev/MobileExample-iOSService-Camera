
var Camera = function()
{
  var imgView = null;
  var statusView = null;

  this.getFilesList = function(type, idimgView,idstatus)
  {
    if (null == statusView) {
      statusView = idstatus;
    }
    if (null == imgView) {
      imgView = idimgView;
    }

    var cameraURL = 'http://pmapi/camera/'+type;
    console.log('camera get URL: '+ cameraURL);

    _sendGETRequest(cameraURL, function(respData) {
      statusView.innerHTML = JSON.stringify(respData);
   }, function(err) {
     statusView.innerHTML = JSON.stringify(err);
   });
  }

  this.deleteFiles = function(type, idimgView,idstatus)
  {
    if (null == statusView) {
      statusView = idstatus;
    }
    if (null == imgView) {
      imgView = idimgView;
    }

    var cameraURL = 'http://pmapi/camera/'+type;
    console.log('camera delete URL: '+ cameraURL);

    _sendDELETERequest(cameraURL, function(respData) {
      statusView.innerHTML = JSON.stringify(respData);
   }, function(err) {
     statusView.innerHTML = JSON.stringify(err);
   });
  }

  this.openCamera = function(compression, sourceType, mediaType, idimgView, idstatus)
  {
    if (null == imgView) {
      imgView = idimgView;
    }
    if (null == statusView) {
      statusView = idstatus;
    }

    var cameraURL = 'http://pmapi/camera';
    console.log('camera URL: '+ cameraURL);

// 1. compression
//   1-100
// 2. picture/video - MediaType
//   PICTURE		0	Allow selection of still pictures only. DEFAULT. Will return format specified via DestinationType
//   VIDEO		1	Allow selection of video only, ONLY RETURNS URL
//   ALLMEDIA	2	Allow selection from all media types
//
// 3. camera/saved/gallery - dONE - sourceType
//   PHOTOLIBRARY	0	Choose image from picture library (same as SAVEDPHOTOALBUM for Android)
//   CAMERA			1	Take picture from camera
//   SAVEDPHOTOALBUM	2	Choose image from picture library (same as PHOTOLIBRARY for Android)
//
// 4. OUTPUT
//   0 - FILE URI || 1 - src ||  x-Native-URI
//
// 5. edit
//   0/1

    var options = {
      "compression":compression,
      "sourceType" : sourceType,
      "mediaType" : mediaType,
      "edit" : 0,
      "output" : 0,
      "cameraDirection" : 0
    };
    //sending GET request to db service to fetch document.
    _sendPOSTRequest(cameraURL, options, function(data) {
      var responseRcvd = JSON.stringify(data);
      // console.log('image: '+ barcodeRcvd);
      if (data.hasOwnProperty('image_src')) {
          imgView.src = "data:image/jpeg;base64," + data.image_src;
          statusView.innerHTML = "";
      }
      else if(data.hasOwnProperty('image_location')){
        statusView.innerHTML = "";
        imgView.src = data.image_location;
      }
      else {
        {
          statusView.innerHTML = responseRcvd;
          imgView.src = "";
        }
      }

    }, function(err) {
      console.error('Something went wrong:', err);
    });
  };

  this.openCam = function(options, idimgView, idstatus)
  {
    if (null == imgView) {
      imgView = idimgView;
    }
    if (null == statusView) {
      statusView = idstatus;
    }

    var cameraURL = 'http://pmapi/camera';
    console.log('camera URL: '+ cameraURL);
    // var options = {
    //   "compression":compression,
    //   "sourceType" : sourceType,
    //   "mediaType" : mediaType,
    //   "edit" : 0,
    //   "cameraDirection" : 0
    // };
    //sending GET request to db service to fetch document.
    _sendPOSTRequest(cameraURL, options, function(data) {
      var responseRcvd = JSON.stringify(data);
      // console.log('image: '+ barcodeRcvd);
      if (data.hasOwnProperty('image_src')) {
          imgView.src = "data:image/jpeg;base64," + data.image_src;
          statusView.innerHTML = "";
      }
      else {
        statusView.innerHTML = responseRcvd;
        imgView.src = "";
      }

    }, function(err) {
      console.error('Something went wrong:', err);
    });
  };

  // sends a GET HTTP request
    var _sendGETRequest = function(url, successHandler, errorHandler) {
      var xhr = new XMLHttpRequest();
      xhr.open('get', url, true);
      xhr.responseType = 'json';
      xhr.onload = function() {
        var status = xhr.status;
        if (status >= 200 && status <= 299) {
          successHandler && successHandler(xhr.response);
        } else {
          errorHandler && errorHandler(status);
        }
      };
      xhr.send();
    };

    // sends a GET HTTP request
      var _sendDELETERequest = function(url, successHandler, errorHandler) {
        var xhr = new XMLHttpRequest();
        xhr.open('delete', url, true);
        xhr.responseType = 'json';
        xhr.onload = function() {
          var status = xhr.status;
          if (status >= 200 && status <= 299) {
            successHandler && successHandler(xhr.response);
          } else {
            errorHandler && errorHandler(status);
          }
        };
        xhr.send();
      };

  // sends a POST HTTP request
var _sendPOSTRequest = function(url, body, successHandler, errorHandler) {
  var xhr = new XMLHttpRequest();
  xhr.open('POST', url, true);
  xhr.setRequestHeader("Content-Type", "application/json;charset=UTF-8");
  xhr.setRequestHeader('Content-Length', body.length);
  xhr.responseType = 'json';
  xhr.onload = function() {
    var status = xhr.status;
    if (status >= 200 && status <= 299) {
      successHandler && successHandler(xhr.response);
    } else {
      errorHandler && errorHandler(status);
    }
  };
  xhr.send(JSON.stringify(body));
};


}

var cam = new Camera();
