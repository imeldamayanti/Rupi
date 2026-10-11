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
    /// Needed when OCR couldn't read any digits (classifier alone).
    private let strictThreshold = 0.95
    /// Enough when OCR independently read the same denomination.
    private let ocrConfirmedThreshold = 0.70
    
    private let announceCooldown: TimeInterval = 4
    
    @State private var ocrDigits: [String] = []
    @State private var ocrBusy = false
    @State private var lastOCRAt = Date.distantPast
    private let ocrInterval: TimeInterval = 0.5

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
                VStack(spacing: 4) {
                    Text("\(result.label)  conf=\(String(format: "%.2f", result.confidence))")
                        .font(.title2.bold())
                    Text("OCR: \(ocrDigits.isEmpty ? "-" : ocrDigits.joined(separator: ", "))")
                        .font(.title3)
                }
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

                    // Continuous OCR for on-screen display (throttled, one request at a time).
                    if !ocrBusy, Date().timeIntervalSince(lastOCRAt) >= ocrInterval {
                        ocrBusy = true
                        lastOCRAt = Date()
                        TextRecognizer.recognizedDigitStrings(in: cgImage) { digits in
                            DispatchQueue.main.async {
                                ocrDigits = digits
                                ocrBusy = false
                            }
                        }
                    }

                    guard r.label != "empty", r.confidence >= ocrConfirmedThreshold else {
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
                    let confidence = r.confidence
                    TextRecognizer.recognizedDigitStrings(in: cgImage) { digitStrings in
                        let verdict = TextRecognizer.confirms(label: labelToConfirm, digitStrings: digitStrings)
                        DispatchQueue.main.async {
                            // OCR ran async; re-check the guess hasn't moved on in the meantime.
                            guard pendingLabel == labelToConfirm, pendingCount >= requiredConsecutive else { return }
                            guard verdict != false else { return } // OCR read a different number: skip, let it retry next frame
                            // OCR inconclusive (nil): fall back to the strict classifier-only threshold.
                            if verdict == nil { guard confidence >= strictThreshold else { return } }

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
