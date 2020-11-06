import Cocoa

class ViewController: NSViewController {
    // UI references

    @IBOutlet weak var mostrarTexto: NSTextField!
    @IBOutlet weak var comenzarReconocimiento: NSButton!
    @IBOutlet weak var wordsToWatch: NSTextField!
    
    // instance of our Model object:
    var stt = SpeechToText(instanceNumber: 0)
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
            if !self.stt.started {
                self.stt.start()
            }
        }
    }
}
