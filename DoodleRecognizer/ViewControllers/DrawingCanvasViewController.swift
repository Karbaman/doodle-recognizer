import UIKit
import PencilKit
import SnapKit
import Vision
import RxSwift
import RxRelay
import RxCocoa

final class DrawingCanvasViewController: UIViewController {
    let imageClassifier = ImageClassifier()
    let canvasChanges: PublishRelay<Void> = PublishRelay()
    let disposeBag = DisposeBag()

    let canvasView: PKCanvasView = {
        let canvasView = PKCanvasView()
        canvasView.backgroundColor = UIColor.white
        canvasView.isOpaque = false
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 20)
        return canvasView
    }()

    let predictionResultLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = UIColor.black
        label.text = ""
        return label
    }()

    let clearButton = UIBarButtonItem(title: "Clear", style: .plain, target: nil, action: nil)
    let shareButton = UIBarButtonItem(barButtonSystemItem: .save, target: nil, action: nil)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupRx()
    }

    func setupViews() {
        navigationItem.rightBarButtonItems = [clearButton]
        navigationItem.leftBarButtonItems = [shareButton]

        view.addSubview(canvasView)
        canvasView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
        }
        canvasView.delegate = self

        view.addSubview(predictionResultLabel)
        predictionResultLabel.snp.makeConstraints {make in
            make.leading.equalTo(0)
            make.trailing.equalTo(0)
            make.top.equalTo(100)
            make.height.equalTo(20)
        }
    }

    func setupRx() {
        imageClassifier.classificationResult.subscribe(onNext: { (value) in
            self.predictionResultLabel.text = value
            }).disposed(by: disposeBag)

        canvasChanges
            .debounce(.milliseconds(500), scheduler: MainScheduler.instance)
            .subscribe(onNext: { _ in
                self.finishDrawing()
            })
            .disposed(by: disposeBag)

        clearButton.rx.tap.bind { _ in
            self.clearCanvas()
        }.disposed(by: disposeBag)

        shareButton.rx.tap.bind { _ in
            self.shareImage()
        }.disposed(by: disposeBag)
    }

    func finishDrawing() {
        let image = getDrawingImage().withBackground(color: UIColor.white)
        imageClassifier.classify(image: image)
    }

    func shareImage() {
        let imageShare = [ getDrawingImage() ]
        let activityViewController = UIActivityViewController(activityItems: imageShare, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view
        self.present(activityViewController, animated: true, completion: nil)
    }

    func clearCanvas() {
        DispatchQueue.main.async {
            self.canvasView.drawing = PKDrawing()
            self.predictionResultLabel.text = ""
        }
    }

    func getDrawingImage() -> UIImage {
        let drawingRect = canvasView.drawing.bounds.boundingSquare
        let image = canvasView.drawing.image(from: drawingRect, scale: UIScreen.main.scale * 1.0)
        return image
    }
}

extension DrawingCanvasViewController: PKCanvasViewDelegate {
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        let drawingRect = canvasView.drawing.bounds
        guard drawingRect.size != .zero else {
            return
        }
        canvasChanges.accept(Void())
    }
}
