
var Camera = function()
{
  var imgView = null;
  var statusView = null;
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
    var options = {
      "compression":compression,
      "sourceType" : sourceType,
      "mediaType" : mediaType,
      "edit" : 0,
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
      else {
        statusView.innerHTML = responseRcvd;
        imgView.src = "";
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
