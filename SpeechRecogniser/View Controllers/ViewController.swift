import Cocoa
import AVFoundation
import Speech

class ViewController: NSViewController {
    // UI references
    @IBOutlet weak var mostrarTexto: NSTextFieldCell!
    @IBOutlet weak var comenzarReconocimiento: NSButton!
    
    var chosenLocale: Locale!
    var speechRecognizer: SFSpeechRecognizer!
    
    override public func viewDidAppear() {
        super.viewDidAppear()
        // get permission to perform speech recognition:
        
        SFSpeechRecognizer.requestAuthorization { authStatus in

          // The authorization status results in changes to the
          // app’s interface, so process the results on the app’s
          // main queue.
             OperationQueue.main.addOperation {
                switch authStatus {
                   case .authorized:
                        print("authorized")

                   case .denied:
                        print("denied")

                   case .restricted:
                        print("restricted")

                   case .notDetermined:
                        print("not determined")
                    
                }
            }
        }
        
        // Ensure Spanish locale object is supported
        let supportedLocales = SFSpeechRecognizer.supportedLocales()
        if supportedLocales.contains(Locale(identifier: "es-ES")) {
            chosenLocale = Locale(identifier: "es-ES")
        }
        
        for locale in supportedLocales {
            speechRecognizer = SFSpeechRecognizer(locale: locale)
            print("language: ", locale.identifier, "supports on-device: ", speechRecognizer.supportsOnDeviceRecognition)
        }
        
        // instantiate speech recognizer object with chosen locale (i.e. language)
        speechRecognizer = SFSpeechRecognizer(locale: chosenLocale)
        print("recogniser available: ", speechRecognizer.isAvailable, "\n",
            "supports on-device: ", speechRecognizer.supportsOnDeviceRecognition, "\n", speechRecognizer.locale)
         
         
        if speechRecognizer.supportsOnDeviceRecognition {
             print("device supports on-device recognition for chosen language: \(chosenLocale.identifier)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    // functions needed for recognition process, in order of use
    
    
    
    @IBAction func comenzarReconocimientoClicked(_ sender: Any) {
        
        print("recogniser available: ", speechRecognizer.isAvailable, "\n",
        "supports on-device: ", speechRecognizer.supportsOnDeviceRecognition, "\n", speechRecognizer.locale)
        // tempSettingUp()
    }
}

