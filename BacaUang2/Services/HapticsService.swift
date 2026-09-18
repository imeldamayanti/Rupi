//
//  Haptics.swift
//  BacaUang2
//
//  Created by Imelda Damayanti on 14/09/26.
//

import CoreHaptics

final class HapticsService {
    private var engine: CHHapticEngine?
    private let supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics

    private func startEngineIfNeeded() {
        guard engine == nil else { return }
        engine = try? CHHapticEngine()
        try? engine?.start()
        engine?.stoppedHandler = { [weak self] _ in self?.engine = nil }
        engine?.resetHandler = { [weak self] in self?.engine = nil }
    }

    func playDenomination(shortCount: Int, hasLong: Bool) {
        guard supportsHaptics else { return }
        startEngineIfNeeded()

        var events: [CHHapticEvent] = []
        let gap = 0.30
        for i in 0..<shortCount {
            events.append(CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.9),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8),
                ],
                relativeTime: Double(i) * gap
            ))
        }
        if hasLong {
            let start = Double(shortCount) * gap + 0.1
            events.append(CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.25),
                ],
                relativeTime: start,
                duration: 0.4
            ))
        }

        guard let pattern = try? CHHapticPattern(events: events, parameters: []),
              let player = try? engine?.makePlayer(with: pattern)
        else { return }
        try? player.start(atTime: 0)
    }
}
