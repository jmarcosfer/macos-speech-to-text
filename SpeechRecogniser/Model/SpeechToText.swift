//
//  SpeechToText.swift
//  SpeechRecogniser
//
//  Created by Jorge on 18/02/2020.
//  Copyright © 2020 Jorge. All rights reserved.
//

import Foundation
import AVFoundation
import Accelerate
import Speech

//protocol SpeechToTextDelegate {
//    // will require extending the ViewController class to provide whatever functionality is established as required for STT delegate
//
//}

class SpeechToText {
    
    // create stt variables
    var recognizer: SFSpeechRecognizer!
    var recognitionRequest: SFSpeechAudioBufferRecognitionRequest!
    var recognitionTask: SFSpeechRecognitionTask!
    let audioEngine = AVAudioEngine()
    private var instanceNumber: Int
    private var controllerInstance: ViewController?
    
    init(instanceNumber sttInstanceNumber: Int) {
        instanceNumber = sttInstanceNumber
    }
    
    // define stt functions
    func setup(_ controller: ViewController){
        self.controllerInstance = controller
        
        // get permission to perform speech recognition:
        SFSpeechRecognizer.requestAuthorization { authStatus in

          // The authorization status results in changes to the
          // app’s interface, so process the results on the app’s
          // main queue.
             OperationQueue.main.addOperation {
                switch authStatus {
                    case .authorized:
                        self.controllerInstance?.comenzarReconocimiento.isEnabled = true
                        print("authorized")

                    case .denied:
                        self.controllerInstance?.comenzarReconocimiento.isEnabled = false
                        print("denied")

                    case .restricted:
                        self.controllerInstance?.comenzarReconocimiento.isEnabled = false
                        print("restricted")

                    case .notDetermined:
                        self.controllerInstance?.comenzarReconocimiento.isEnabled = false
                        print("not determined")
                
                    @unknown default:
                        fatalError()
                }
            }
        }
        
        // Ensure Spanish locale object is supported & instantiate speech recognizer object with chosen locale (i.e. language)
        let supportedLocales = SFSpeechRecognizer.supportedLocales()
        
        if supportedLocales.contains(Locale(identifier: "es-ES")) {
            self.recognizer = SFSpeechRecognizer(locale: Locale(identifier: "es-ES"))
            
            print("Language: ", self.recognizer.locale)
            print("Is available: ", self.recognizer.isAvailable)
            print("Supports on-device recognition: ", self.recognizer.supportsOnDeviceRecognition)
        }
    }
    
    func start(){
        let myInputNode = self.startAudio()
        // Create recognition request:
        self.recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        self.recognitionRequest.shouldReportPartialResults = true
        // SWAP ORDER HERE: REQUEST <–> STARTAUDIO ???
        self.startRecognitionTask(myInputNode)
    }
    
    private func startAudio() -> AVAudioInputNode {
        let inputNode = self.audioEngine.inputNode
        print("Found ", inputNode.numberOfOutputs, "output buses on system's default audio input device")
        print("Uses format: ", inputNode.outputFormat(forBus: 0))
        print("Name: ", inputNode.name(forOutputBus: 0) ?? "no name")
        
        // grab single channel pointer, put into new AVAudioPCMBuffer object, then pass to request object
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) -> Void in
            
            let singleChannelBuffer = AVAudioPCMBuffer(pcmFormat: buffer.format,frameCapacity:  buffer.frameCapacity)!
            
//            let inNumberSamples: Int = Int(buffer.frameLength)
            for i in 0..<Int(buffer.frameLength) {
                singleChannelBuffer.floatChannelData![0][i] = buffer.floatChannelData![1][i]
                print(singleChannelBuffer.audioBufferList.pointee)
            }

            self.recognitionRequest?.append(singleChannelBuffer)
        }
        
        self.audioEngine.prepare()
        do {
            try self.audioEngine.start()
            print("audio started")
        } catch {
            print("AVAudioEngine error: \(error)")
        }
        
        return inputNode
    }
    
    private func startRecognitionTask(_ node: AVAudioInputNode){
        self.recognitionTask = self.recognizer.recognitionTask(with: self.recognitionRequest) { result, error in
            var isFinal = false

            if let result = result {
                print("i heard something!")
                self.controllerInstance?.mostrarTexto.stringValue = result.bestTranscription.formattedString
                print(result.bestTranscription.formattedString)
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                print("there was an error")
                self.audioEngine.stop()
                node.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                // self.controllerInstance?.comenzarReconocimiento.setNextState()
            }

        }
    }
    
    func stop(){
        return
    }
}
