//
//  MoneyClassifier.swift
//  BacaUang2
//
//  Created by Imelda Damayanti on 14/09/26.
//

import CoreGraphics
import CoreML

struct ClassifierResult{
    let label: String
    let confidence: Double
    let allProbs: [String: Double]
}

final class MoneyClassifier{
    private let model: BacaUang
    let labels: [String]
    let imgSize: Int

    init() throws {
        model = try BacaUang(configuration: MLModelConfiguration())
        (labels, imgSize) = Self.loadMeta()
    }
    
    private static func loadMeta() -> ([String], Int) {
         guard let url = Bundle.main.url(forResource: "labels", withExtension: "json"),
               let data = try? Data(contentsOf: url),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let labels = json["labels"] as? [String],
               let imgSize = json["img_size"] as? Int
         else {
             assertionFailure("labels.json missing or malformed in bundle")
             return (["1000", "2000", "5000", "10000", "20000", "50000", "100000", "empty"], 224)
         }
         return (labels, imgSize)
     }
    
    func classify(cgImage: CGImage) -> ClassifierResult? {
          guard let buffer = Letterbox.pixelBuffer(from: cgImage, size: imgSize) else { return nil }
          guard let output = try? model.prediction(image: buffer) else { return nil }
          let probs = output.classLabel_probs
          return ClassifierResult(label: output.classLabel, confidence: probs[output.classLabel] ?? 0, allProbs: probs)
      }
    
}
