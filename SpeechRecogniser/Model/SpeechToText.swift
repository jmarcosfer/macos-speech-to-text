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
    var started = false
    private var instanceNumber: Int
    private var controllerInstance: ViewController?
    private var previousResult: SFSpeechRecognitionResult?
    private var myInputNode: AVAudioInputNode?
    private var seenSegments: [Int] = []
    
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
        self.myInputNode = self.startAudio()
        // Create recognition request:
        self.recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        self.recognitionRequest.shouldReportPartialResults = true
        // SWAP ORDER HERE: REQUEST <–> STARTAUDIO ???
        self.startRecognitionTask(self.myInputNode!)
        self.started = true
    }
    
    private func startAudio() -> AVAudioInputNode {
        let inputNode = self.audioEngine.inputNode
        print("Found ", inputNode.numberOfOutputs, "output buses on system's default audio input device")
        print("Uses format: ", inputNode.outputFormat(forBus: 0))
        print("Name: ", inputNode.name(forOutputBus: 0) ?? "no name")
        
        // grab single channel pointer, put into new AVAudioPCMBuffer object, then pass to request object
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) -> Void in
            
//            let singleChannelBuffer = AVAudioPCMBuffer(pcmFormat: buffer.format,frameCapacity:  buffer.frameCapacity)!
//
//            for i in 0..<Int(buffer.frameLength) {
//                singleChannelBuffer.floatChannelData![0][i] = buffer.floatChannelData![0][i]
//                print(singleChannelBuffer.audioBufferList.pointee)
//            }

            self.recognitionRequest?.append(buffer) // singleChannelBuffer (2ch)
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
            var wordArray: [String] = []
            
            if !self.controllerInstance!.wordsToWatch.stringValue.isEmpty {
                // get wanted words, convert Substrings –> Strings for easier comparison later
                for substring in self.controllerInstance!.wordsToWatch.stringValue.split(separator: ",") {
                    wordArray.append(String(substring.lowercased()))
                }
                print("Wanted words: ", wordArray)
                
                if let foundResult = result {
                    print("i heard something!")
                    let formattedResult = foundResult.bestTranscription.formattedString
                    let prevFormattedResult = self.previousResult?.bestTranscription.formattedString ?? ""
                    
                    // check for wanted words only if new partial result HAS changed (i.e. != self.previousResult)
                    if  formattedResult != prevFormattedResult {
                        // case-check each word against individual segments of transcription (utterances)
                        // only those added to partial result since self.previousResult
                        let prevSegmentArraySize = self.previousResult?.bestTranscription.segments.count ?? 1
                        let currentSegmentArraySize = foundResult.bestTranscription.segments.count
                        if currentSegmentArraySize > prevSegmentArraySize {
                            for s in foundResult.bestTranscription.segments[prevSegmentArraySize-1...currentSegmentArraySize-1] {
                                if wordArray.contains(s.substring.lowercased()) && !self.seenSegments.contains(s.substringRange.location) {
                                    // print to display if found
                                    self.controllerInstance!.mostrarTexto.stringValue += s.substring + " "
                                    print("I detected the word: ", s.substring)
                                    self.seenSegments.append(s.substringRange.location)
                                }
                            }
//                            self.controllerInstance!.mostrarTexto.stringValue = foundResult.bestTranscription.formattedString
                        }
                    }
                    
                    self.previousResult = foundResult
                    isFinal = foundResult.isFinal
                }
                
            } else if self.controllerInstance!.wordsToWatch.stringValue.isEmpty {
                if let foundResult = result {
                    self.controllerInstance?.mostrarTexto.stringValue = foundResult.bestTranscription.formattedString
                    print(foundResult.bestTranscription.formattedString)
                }
            }
            
            if error != nil {
                print("There was an error \(error!.localizedDescription)")
                self.audioEngine.stop()
                node.removeTap(onBus: 0)
                node.reset()
                
                self.recognitionRequest.endAudio()
                self.recognitionRequest = nil
                self.recognitionTask.finish()
                self.recognitionTask = nil
                
                self.seenSegments = []
                
                print("Re-starting recognition...")
                self.start()
                
                // self.controllerInstance?.comenzarReconocimiento.setNextState()
            }
            
            if isFinal {
                print("FINAL RESULT reached")
                self.audioEngine.stop()
                node.removeTap(onBus: 0)
                node.reset()
                
                self.recognitionRequest.endAudio()
                self.recognitionRequest = nil
                self.recognitionTask.cancel()
                self.recognitionTask = nil
                
                self.seenSegments = []
                
                print("Re-starting recognition...")
                self.start()
            }

        }
    }
    
}
