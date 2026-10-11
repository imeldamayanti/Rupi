//
//  TextRecognizer.swift
//  BacaUang2
//

import Vision
import CoreGraphics

enum TextRecognizer {
    /// Runs Vision text recognition on a frame and returns every numeric run found
    /// (punctuation like "10.000" or "Rp10000" stripped to plain digits).
    static func recognizedDigitStrings(in cgImage: CGImage, completion: @escaping ([String]) -> Void) {
        let request = VNRecognizeTextRequest { request, error in
            guard error == nil, let observations = request.results as? [VNRecognizedTextObservation] else {
                completion([])
                return
            }
            let digitStrings = observations.compactMap { observation -> String? in
                guard let candidate = observation.topCandidates(1).first else { return nil }
                let digits = candidate.string.filter(\.isNumber)
                return digits.count >= 3 ? digits : nil
            }
            completion(digitStrings)
        }
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false
        request.minimumTextHeight = 0.03

        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }

    /// nil = OCR found no usable digits (inconclusive, don't block on it).
    /// true = a recognized number matches the classifier's label.
    /// false = OCR read a different denomination than the classifier guessed.
    static func confirms(label: String, digitStrings: [String]) -> Bool? {
        guard !digitStrings.isEmpty else { return nil }
        return digitStrings.contains(label)
    }
}
