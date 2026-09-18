//
//  SpeechAnnouncer.swift
//  BacaUang2
//
//  Created by Imelda Damayanti on 14/09/26.
//

import AVFoundation

final class SpeechAnnouncer {
    private let synthesizer = AVSpeechSynthesizer()
    private var lastSpoken: String?
    private var lastSpokenAt = Date.distantPast
    
    
    private static let spokenForm: [String: String] = [
           "1000": "seribu",
           "2000": "dua ribu",
           "5000": "lima ribu",
           "10000": "sepuluh ribu",
           "20000": "dua puluh ribu",
           "50000": "lima puluh ribu",
           "100000": "seratus ribu",
       ]

    init() {
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .voicePrompt, options: [.duckOthers])
            try? AVAudioSession.sharedInstance().setActive(true)
        }

        func announce(_ label: String) {
            let utterance = AVSpeechUtterance(string: Self.spokenForm[label] ?? label)
            utterance.voice = AVSpeechSynthesisVoice(language: "id-ID") ?? AVSpeechSynthesisVoice(language: "en-US")
            synthesizer.speak(utterance)
        }
}
