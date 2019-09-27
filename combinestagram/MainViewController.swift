/// Copyright (c) 2019 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit
import RxSwift
import RxCocoa

class MainViewController: UIViewController {

  @IBOutlet weak var imagePreview: UIImageView!
  @IBOutlet weak var buttonClear: UIButton!
  @IBOutlet weak var buttonSave: UIButton!
  @IBOutlet weak var itemAdd: UIBarButtonItem!
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    print("resources: \(RxSwift.Resources.total)")
  }
  
  private let disposeBag = DisposeBag()
  
  private let images = BehaviorRelay<[UIImage]>(value: [])//Variable<[UIImage]>([])

  override func viewDidLoad() {
    super.viewDidLoad()
    images.asObservable().subscribe(onNext: { [weak self](selectedPhotos) in
      self?.imagePreview.image = selectedPhotos.collage(size: self?.imagePreview.bounds.size ?? CGSize.zero)//UIImage.collage(images: selectedPhotos, size: self?.imagePreview.bounds.size ?? CGSize.zero)
      self?.updateUI(selectedPhotos: selectedPhotos)
      }).disposed(by: disposeBag)
  }
  
  @IBAction func actionClear() {
    images.accept([])
  }

  @IBAction func actionSave() {
    guard let image = imagePreview.image else { return }
    PhotoWriter.save(image)
      .subscribe(onError: { [weak self] error in
        self?.showMessage("Error", description: error.localizedDescription)
      }, onCompleted: { [weak self] in
        self?.showMessage("Saved")
        self?.actionClear()
      })
      .disposed(by: disposeBag)
  }

  @IBAction func actionAdd() {
    guard let vc = storyboard?.instantiateViewController(withIdentifier: "PhotosViewController") as? PhotosViewController else{
      return 
    }
    vc.selectedPhotos.subscribe(onNext: { [weak self] (selectedPhoto) in
    self?.images.accept((self?.images.value ?? []) + [selectedPhoto])
      }, onDisposed: {
        print("completed photo selection")
    }).disposed(by: vc.bag)
    
    navigationController?.pushViewController(vc, animated: true)
  }

  func showMessage(_ title: String, description: String? = nil) {
//    let alert = UIAlertController(title: title, message: description, preferredStyle: .alert)
//    alert.addAction(UIAlertAction(title: "Close", style: .default, handler: { [weak self] _ in self?.dismiss(animated: true, completion: nil)}))
//    present(alert, animated: true, completion: nil)
    showAlertWith(title: title, message: description).subscribe().disposed(by: disposeBag)
  }
}
private extension MainViewController{
  func updateUI(selectedPhotos: [UIImage]){
    buttonSave.isEnabled = selectedPhotos.count > 0 && selectedPhotos.count % 2 == 0
    buttonClear.isEnabled = selectedPhotos.count > 0
    itemAdd.isEnabled = selectedPhotos.count < 6
    title = selectedPhotos.count > 0 ? "\(selectedPhotos.count) photos" : "Collage"
  }
}
extension UIViewController{
  func showAlertWith(title: String, message: String?)->Completable{
    return Completable.create { [weak self](completable) -> Disposable in
      let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "Close", style: .default, handler: {(_) in
        completable(.completed)
      }))
      self?.present(alert, animated: true, completion: nil)
      return Disposables.create {
        self?.dismiss(animated: true, completion: nil)
      }
    }
  }
}
