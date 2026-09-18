//
//  TutorialOverlayView.swift
//  BacaUang2
//
//  Created by Imelda Damayanti on 16/09/26.
//

import SwiftUI
import AVFoundation

struct TutorialOverlayView: View {
    let onDismiss : (() -> Void)
    private let synthesizer = AVSpeechSynthesizer()
    
    private static let steps = [
        "Hold the phone in front of your chest.",
        "Unfold the money and point it at the back camera.",
        "Keep some distance by half-extending the hand holding the money.",
        "Hold still until the phone beeps or vibrates.",
    ]
    
    private static let hapticRows: [(label: String, spoken: String, desc: String)] = [
        ("1,000", "one thousand", "1 time short vibration"),
        ("2,000", "two thousand", "2 times short vibration"),
        ("5,000", "five thousand", "3 times short vibration"),
        ("10,000", "ten thousand", "1 time short vibration + 1 time long vibration"),
        ("20,000", "twenty thousand", "2 times short vibration + 1 time long vibration"),
        ("50,000", "fifty thousand", "3 times short vibration + 1 time long vibration"),
        ("100,000", "one hundred thousand", "4 times short vibration + 1 time long vibration"),
    ]
    
    var body: some View {
        ZStack{
            Color.black.opacity(0.85).ignoresSafeArea()
            
            ScrollView{
                VStack(alignment: .leading, spacing: 16){
                 
                    Text("How to Use")
                        .font(.title.bold())
                        .foregroundStyle(.white)
                    
                    ForEach(Array(Self.steps.enumerated()), id: \.offset) { index, step in
                        Text("\(index + 1). \(step)")
                            .foregroundStyle(.white)
                    }
                    
                    Text("Short vibration = digit, long vibration = marks a larger thousand value:")
                        .foregroundStyle(.white)
                    
                    Text("Tap anywhere on the screen to continue.")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.top, 8)
                    
                    
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Self.hapticRows, id: \.label) { row in
                            Text("\(row.label) → \(row.desc)")
                                .foregroundStyle(.white.opacity(0.9))
                        }
                    }
                    
                    
                }
                .padding()
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { dismiss() }
        .onAppear { speakAll() }
        .onDisappear { synthesizer.stopSpeaking(at: .immediate) }
    }
    private func dismiss(){
        synthesizer.stopSpeaking(at: .immediate)
        onDismiss()
    }
    
    private func speakAll(){
        var sentences = ["How to use."]
        sentences.append(contentsOf: Self.steps)
        sentences.append("Short vibration means a digit, long vibration marks a larger thousand value.")
        sentences.append("Tap anywhere on the screen to continue.")
        for row in Self.hapticRows {
            sentences.append("\(row.spoken): \(row.desc).")
        }
        
        
        for sentence in sentences {
            let utterance = AVSpeechUtterance(string: sentence)
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            synthesizer.speak(utterance)
        }
    }
}


#Preview {
    TutorialOverlayView(onDismiss: {})
}
