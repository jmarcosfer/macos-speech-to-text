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
    private var instanceNumber: AudioDeviceID?
    private var controllerInstance: ViewController?
    
    init(instanceNumber sttInstanceNumber: AudioDeviceID) {
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
        
//        guard let inputUnit = inputNode.audioUnit else { return inputNode }
//
//        // get proper ID number ref through low-level kAudio-type calls:
//        var inputDeviceID = self.instanceNumber
//
//        var propertyAddress = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDefaultInputDevice, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMaster)
//
//        var deviceIdSize = UInt32(MemoryLayout<AudioDeviceID>.size)
//
//        AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &propertyAddress, 0, nil, &deviceIdSize, &inputDeviceID)
//
//        AudioUnitSetProperty(inputUnit, kAudioOutputUnitProperty_CurrentDevice, kAudioUnitScope_Global, 0, &inputDeviceID, deviceIdSize)
        
        // back to inputNode: set a listening tap on it to fill buffers for recognition
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) -> Void in
            
            let inNumberFrames: Int = Int(buffer.frameLength)

            for i in 0..<inNumberFrames {
                let sample = buffer.floatChannelData![1][i]
                print("sample: ", sample)
            }
//            if buffer.format.channelCount > 0 {
//                let samples = (buffer.floatChannelData![0])
//                var avgValue: Float32 = 0
//                vDSP_meamgv(samples, buffer.stride, &avgValue, inNumberFrames)
//                var v: Float = -100
//                if avgValue != 0 {
//                    v = 20.0 * log10f(avgValue)
//                    print("samples:", v)
//                }
//            }
            
            self.recognitionRequest?.append(buffer.floatChannelData![1])
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
