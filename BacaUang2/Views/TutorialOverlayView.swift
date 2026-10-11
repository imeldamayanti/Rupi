//
//  TutorialOverlayView.swift
//  BacaUang2
//
//  Created by Imelda Damayanti on 16/09/26.
//

import SwiftUI

struct TutorialOverlayView: View {
    let onDismiss : (() -> Void)
    @State private var voice = VoicePlayer()
    
    private static let steps = [
        "Pegang ponsel di depan dada.",
        "Buka lipatan uang, lalu arahkan ke kamera belakang.",
        "Jaga jarak dengan merentangkan setengah tangan yang memegang uang.",
        "Tahan sampai ponsel berbunyi atau bergetar.",
    ]
    
    private static let hapticRows: [(label: String, desc: String)] = [
        ("1.000", "getar pendek 1 kali"),
        ("2.000", "getar pendek 2 kali"),
        ("5.000", "getar pendek 3 kali"),
        ("10.000", "getar pendek 1 kali + getar panjang 1 kali"),
        ("20.000", "getar pendek 2 kali + getar panjang 1 kali"),
        ("50.000", "getar pendek 3 kali + getar panjang 1 kali"),
        ("100.000", "getar pendek 4 kali + getar panjang 1 kali"),
    ]
    
    var body: some View {
        ZStack{
            Color.black.opacity(0.85).ignoresSafeArea()
            
            ScrollView{
                VStack(alignment: .leading, spacing: 16){
                 
                    Text("Cara Memakai")
                        .font(.title.bold())
                        .foregroundStyle(.white)
                    
                    ForEach(Array(Self.steps.enumerated()), id: \.offset) { index, step in
                        Text("\(index + 1). \(step)")
                            .foregroundStyle(.white)
                    }
                    
                    Text("Getaran pendek = angka, getaran panjang = menandai nilai ribuan yang lebih besar:")
                        .foregroundStyle(.white)
                    
                    Text("Ketuk di mana saja pada layar untuk melanjutkan.")
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
        .onDisappear { voice.stop() }
    }
    private func dismiss(){
        voice.stop()
        onDismiss()
    }
    
    private func speakAll(){
        let denominations = ["1000", "2000", "5000", "10000", "20000", "50000", "100000"]
        var ids = ["tutorial_title"]
        ids += (1...Self.steps.count).map { "tutorial_step_\($0)" }
        ids += ["tutorial_explain", "tutorial_tap"]
        ids += denominations.map { "haptic_\($0)" }
        voice.play(ids)
    }
}


#Preview {
    TutorialOverlayView(onDismiss: {})
}
