import Foundation
import UIKit
import Vision
import RxRelay

/**
 The ImageClassifier class classifies images using ML model
 */

class ImageClassifier {
    let classificationResult: PublishRelay<String> = PublishRelay()

    lazy var classificationRequest: VNCoreMLRequest = {
        do {
            let model = try VNCoreMLModel(for: QuickDraw4_1().model)
            let request = VNCoreMLRequest(model: model, completionHandler: { [weak self] request, error in
                self?.processClassifications(for: request, error: error)
            })
            request.imageCropAndScaleOption = .scaleFill
            return request
        } catch {
            fatalError("Failed to load Vision ML model: \(error)")
        }
    }()

    func processClassifications(for request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            guard let classifications = request.results as? [VNClassificationObservation] else {
                print("Unable to classify image.\n\(error!.localizedDescription)")
                return
            }

            if !classifications.isEmpty {
                self.classificationResult.accept(classifications[0].identifier)
            }
        }
    }

    /**
     Classifies images. The classification process works asynchronously.
     
     
     You need to subscribe to `classificationResult` observable to get the result of classification.
    
     Usage:
     ~~~
     let imageClassifier = ImageClassifier()
     
     imageClassifier.classificationResult.subscribe(onNext: { (value) in
        // use 'value'
        }).disposed(by: disposeBag)
     
     imageClassifier.classify(image: image)
     ~~~
      - Parameter image: The image to be classified
     */

    func classify(image: UIImage) {
        guard let ciImage = CIImage(image: image) else {
            fatalError("Unable to create \(CIImage.self) from \(image).")
        }
        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(ciImage: ciImage)
            do {
                try handler.perform([self.classificationRequest])
            } catch {
                print("Failed to perform classification.\n\(error.localizedDescription)")
            }
        }
    }
}
