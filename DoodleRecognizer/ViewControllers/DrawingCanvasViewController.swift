import UIKit
import PencilKit
import SnapKit
import Vision
import RxSwift
import RxRelay
import RxCocoa

final class DrawingCanvasViewController: UIViewController {
    
    let canvasChanges:PublishRelay<Void> = PublishRelay()
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupRx()
    }
    
    func setupViews() {
        
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
        canvasChanges
            .debounce(.milliseconds(500), scheduler: MainScheduler.instance)
            .subscribe(onNext: { Void in
                self.finishDrawing()
            })
            .disposed(by: disposeBag)
    }
    
    func finishDrawing() {
        //TODO: call a model to recognize the result image
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
