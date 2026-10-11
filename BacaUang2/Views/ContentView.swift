//
//  ContentView.swift
//  BacaUang2
//
//  Created by Imelda Damayanti on 14/09/26.
//

import SwiftUI
struct ContentView: View {
    @StateObject private var camera = CameraController()
    @State private var classifier: MoneyClassifier?
    @State private var loadError: String?
    @State private var result: ClassifierResult?
    
    @State private var speaker = SpeechAnnouncer()
    
    @State private var lastAnnounced: String?
    @State private var lastAnnouncedAt = Date.distantPast
    @State private var haptics = HapticsService()
    
    @State private var pendingLabel: String?
    @State private var pendingCount = 0
    private let requiredConsecutive = 3
    
    private let announceCooldown: TimeInterval = 4
    
    @State private var showTutorial = false
    private static let hasSeenTutorialKey = "hasSeenTutorial"
    
    
    static let hapticMap: [String: (short: Int, long: Bool)] = [
        "1000": (1, false), "2000": (2, false), "5000": (3, false),
        "10000": (1, true), "20000": (2, true), "50000": (3, true),
        "100000": (4, true),
    ]
    
    var body: some View {
        ZStack(alignment: .bottom) {
            CameraPreviewView(session: camera.session)
                .ignoresSafeArea()
            
            if let result {
                Text("\(result.label)  conf=\(String(format: "%.2f", result.confidence))")
                    .font(.title2.bold())
                    .padding()
                    .background(.ultraThinMaterial)
                    .padding(.bottom, 40)
            }
            
            VStack {
                HStack {
                    Spacer()
                    Button {
                        showTutorial = true
                    } label: {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.white, Color.accentColor)
                    }
                    .padding()
                }
                Spacer()
            }
            
            if showTutorial {
                TutorialOverlayView {
                    showTutorial = false
                    UserDefaults.standard.set(true, forKey: Self.hasSeenTutorialKey)
                }
            }
        }
        .onAppear {
            do {
                classifier = try MoneyClassifier()
            } catch {
                loadError = "Gagal load model: \(error)"
            }
            camera.onFrame = { cgImage in
                guard !showTutorial else { return }
                guard let r = classifier?.classify(cgImage: cgImage) else { return }
                DispatchQueue.main.async {
                    result = r
                    guard r.label != "empty", r.confidence >= 0.95 else {
                        pendingLabel = nil
                        pendingCount = 0
                        return
                    }
                    
                    if r.label == pendingLabel {
                        pendingCount += 1
                    } else {
                        pendingLabel = r.label
                        pendingCount = 1
                    }
                    
                    guard pendingCount >= requiredConsecutive else { return }

                    let now = Date()
                    let sameLabelStillCooling = r.label == lastAnnounced && now.timeIntervalSince(lastAnnouncedAt) < announceCooldown
                    guard !sameLabelStillCooling else { return }

                    let labelToConfirm = r.label
                    TextRecognizer.recognizedDigitStrings(in: cgImage) { digitStrings in
                        let verdict = TextRecognizer.confirms(label: labelToConfirm, digitStrings: digitStrings)
                        DispatchQueue.main.async {
                            // OCR ran async; re-check the guess hasn't moved on in the meantime.
                            guard pendingLabel == labelToConfirm, pendingCount >= requiredConsecutive else { return }
                            guard verdict != false else { return } // OCR read a different number: skip, let it retry next frame

                            lastAnnounced = labelToConfirm
                            lastAnnouncedAt = Date()
                            speaker.announce(labelToConfirm)
                            if let (short, long) = ContentView.hapticMap[labelToConfirm] {
                                haptics.playDenomination(shortCount: short, hasLong: long)
                            }
                        }
                    }
                }
            }
            camera.start()
            if !UserDefaults.standard.bool(forKey: Self.hasSeenTutorialKey) {
                showTutorial = true
            }
        }
        .onDisappear { camera.stop() }
        .alert("Error", isPresented: .constant(loadError != nil || camera.setupError != nil)) {
            Button("OK") {}
        } message: {
            Text(loadError ?? camera.setupError ?? "")
        }
    }
}

#Preview {
    ContentView()
}
