import Cocoa

class ViewController: NSViewController {
    // UI references

    @IBOutlet weak var mostrarTexto: NSTextField!
    @IBOutlet weak var comenzarReconocimiento: NSButton!
    
    // instance of our Model object:
    let stt = SpeechToText(instanceNumber: 0)
    // -----------------------------
    
    override public func viewDidAppear() {
        super.viewDidAppear()
        
//        stt.delegate = self
        self.comenzarReconocimiento.state = NSControl.StateValue(0)
        
        self.stt.setup(self)
        
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
    
    @IBAction func comenzarReconocimientoClicked(_ sender: Any) {
        if self.comenzarReconocimiento.state == NSControl.StateValue(1) {
            self.comenzarReconocimiento.highlight(true)
            self.stt.start()
        } else if self.comenzarReconocimiento.state == NSControl.StateValue(0) {
            print("we're done here")
            self.stt.stop()
        }
    }
}
