import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtSensors

ApplicationWindow {
  id: root
  width: 420
  height: 760
  visible: true
  title: "Motion Based Auth"

  readonly property int defaultFontSize: 22
  readonly property int imageSize: width / 2

  property var recordedPathdis: []
  property var recordedPathdir: []
  property var newPathdis: []
  property var newPathdir: []
  property bool isRecording: false
  property bool isAuth: false

  function reset(): void {
    recordedPathdis = [];
    recordedPathdir = [];
    newPathdis = [];
    newPathdir = [];

    calibrate();
  }
  
  Button {
        text: "شروع/توقف ضبط"
        onClicked: startStopRecording()
        anchors\.centerIn: parent
        background: Rectangle {
            implicitWidth: 150
            implicitHeight: 50
            color: "#f6f6f6"
            border\.color: "#26282a"
            border\.width: 1
            radius: 25
        }
    }

    Button {
        text: "شروع/توقف تأیید هویت"
        onClicked: startStopAuth()
        anchors\.centerIn: parent
        background: Rectangle {
            implicitWidth: 150
            implicitHeight: 50
            color: "#f6f6f6"
            border\.color: "#26282a"
            border\.width: 1
            radius: 25
        }
    }
    
  function calibrate(): void {
    accelerometer.cax += accelerometer.ax
    accelerometer.cay += accelerometer.ay
    accelerometer.caz += accelerometer.az
    rotation.rx = 0
    rotation.ry = 0
    rotation.rz = 0

    position.px = 0
    position.py = 0
    position.pz = 0

    accelerometer.vx = 0
    accelerometer.vy = 0
    accelerometer.vz = 0
  }

  function kalmanFilter() {
    var r = 10.0; // Measurement noise covariance
    var q = 0.1;  // Process noise covariance
    var a = 1.0;  // State transition matrix
    var c = 1.0;  // Measurement matrix
    var b = 0.0;  // Control input matrix

    var cov = NaN; // Covariance
    var x = NaN;  // State estimate

    this.filter = function(measurement) {
      if (isNaN(x)) {
        x = 1 / c * measurement;
        cov = 1 / c * q * (1 / c);
      } else {
        var prediction = this.predict();
        var uncertainty = this.uncertainty();
        var gain = uncertainty * c * (1 / (c * uncertainty * c + q));
        x = prediction + gain * (measurement - c * prediction);
        cov = uncertainty - gain * c * uncertainty;
      }
      return x;
    };

    this.predict = function() {
      return a * x + b * 0; // No control input in this example
    };

    this.uncertainty = function() {
      return a * cov * a + r;
    };

    this.lastMeasurement = function() {
      return x;
    };

    this.setMeasurementNoise = function(noise) {
      r = noise;
    };

    this.setProcessNoise = function(noise) {
      q = noise;
    };
  }

  function startStopRecording() : void {
    isRecording = !isRecording
  }

  function startStopAuth() : void {
    isAuth = !isAuth
  }

  function arraysEqual(arr1, arr2) {
    if (arr1.length !== arr2.length) {
      return false;
    }
    for (var i = 0; i < arr1.length; i++) {
      if (arr1[i] !== arr2[i]) {
        return false;
      }
    }
    return true;
  }

  function auth() : void {
    console.log("recorded path:", recordedPathdis);
    console.log("auth path:", newPathdis);

    console.log("recorded path Dir:", recordedPathdir);
    console.log("auth path Dir:", newPathdir);

    if (arraysEqual(newPathdis, recordedPathdis) && arraysEqual(newPathdir, recordedPathdir))
    {
      authStatus.text = "Authenticated"
    }
    else
    {
      authStatus.text = "not authorized"
    }
  }

  function addPath(x) : void {
    console.log("Added Path")
    if (isRecording) {
      recordedPathdis.push(x)
      recordedPathdir.push(gyroscope.direction)
    } else if(isAuth) {
      newPathdis.push(x)
      newPathdir.push(gyroscope.direction)
    }
  }

  StackView {
    id: stack
    anchors.fill: parent
