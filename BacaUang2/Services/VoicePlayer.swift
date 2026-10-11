//
//  VoicePlayer.swift
//  BacaUang2
//
//  Plays the pre-generated ElevenLabs clips bundled in Resources/Voice.
//  A line with no bundled clip falls back to the system Indonesian voice.
//

import AVFoundation

final class VoicePlayer: NSObject, AVAudioPlayerDelegate, AVSpeechSynthesizerDelegate {
    /// id -> spoken text, from voice_lines.json (also the source for the TTS fallback).
    static let lines: [String: String] = {
        guard let url = Bundle.main.url(forResource: "voice_lines", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let dict = try? JSONDecoder().decode([String: String].self, from: data)
        else { return [:] }
        return dict
    }()

    private let synthesizer = AVSpeechSynthesizer()
    private var player: AVAudioPlayer?
    private var queue: [String] = []

    override init() {
        super.init()
        synthesizer.delegate = self
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .voicePrompt, options: [.duckOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    func announce(_ label: String) {
        play(["den_\(label)"])
    }

    /// Replaces whatever is playing and speaks the given line ids in order.
    func play(_ ids: [String]) {
        stop()
        queue = ids
        playNext()
    }

    func stop() {
        queue = []
        player?.stop()
        player = nil
        synthesizer.stopSpeaking(at: .immediate)
    }

    private func playNext() {
        guard !queue.isEmpty else { return }
        let id = queue.removeFirst()

        if let url = Bundle.main.url(forResource: id, withExtension: "mp3"),
           let p = try? AVAudioPlayer(contentsOf: url) {
            p.delegate = self
            player = p
            p.play()
            return
        }

        guard let text = Self.lines[id] else { playNext(); return }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "id-ID")
        synthesizer.speak(utterance)
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        playNext()
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        playNext()
    }
}
