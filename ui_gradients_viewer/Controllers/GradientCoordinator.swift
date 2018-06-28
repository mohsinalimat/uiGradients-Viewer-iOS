import UIKit
import Pulley
import GradientView
import Photos
import UIKit

enum GradientAction {
    enum DrawerContext {
        case customize
        case popular
        case export
    }
    
    case selectedGradient(Int)
    case selectedGradientFromDrawer(Int)
    case saveGradient(UIImage)
    case drawerContextChange(DrawerContext)
    case colorIndexChange(startingIndex: Int, endingIndex: Int)
}

protocol GradientActionDispatching: class {
    func dispatch(_ action: GradientAction)
}

final class GradientCoordinator {
    let root: PulleyViewController?
    let content: RootPageViewController
    let drawer: GradientDrawerViewController
    var gradients: [GradientColor] = []
    
    var selectedGradient: GradientColor? {
        didSet {
            drawer.gradient = selectedGradient
            guard let gradientDetailViewController = content.gradientVCs.first(where: { vc in
                vc.gradientColor?.title == selectedGradient?.title
            }) else {
                    return
            }
            gradientDetailViewController.gradientColor = selectedGradient
        }
    }
    
    init() {
        let drawer = GradientDrawerViewController()
        self.drawer = drawer
        
        let content = RootPageViewController()
        self.content = content
        
        root = PulleyViewController(contentViewController: self.content, drawerViewController: self.drawer)
        
        self.content.dispatch = self
        self.drawer.dispatch = self
        
        _ = GradientHelper.produceGradients { [weak self] (gradients) in
            guard let strongSelf = self else { return }
            strongSelf.gradients = gradients
            DispatchQueue.main.async {
                let index = Int.random(in: 0 ..< gradients.count)
                strongSelf.content.startingIndex = index
                strongSelf.content.gradientVCs = gradients.map(GradientDetailViewController.init)
                
                strongSelf.content.gradientVCs.forEach { vc in
                    vc.dispatch = self
                }
                
                
                strongSelf.selectedGradient = gradients[index]
                strongSelf.content.scrollToPage(.at(index: index), animated: true)
            }
        }
    }
    
    private func saveImage(image: UIImage) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }, completionHandler: { success, error in
            if success {
                // Saved successfully!
                let successAlert = UIAlertController(title: "Save Successful", message: "save_to_camera_roll_dialog_success_message", preferredStyle: .alert)
                successAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                DispatchQueue.main.async { [weak self] in
                    guard let strongSelf = self else { return }
                    strongSelf.root?.present(successAlert, animated: true, completion: nil)
                }
            }
            else if let error = error {
                // Save photo failed with error
                let successAlert = UIAlertController(title: "Save Unsuccessful", message: String(format: "save_to_camera_roll_dialog_unsuccess_message", error.localizedDescription), preferredStyle: .alert)
                successAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                DispatchQueue.main.async { [weak self] in
                    guard let strongSelf = self else { return }
                    strongSelf.root?.present(successAlert, animated: true, completion: nil)
                }
            }
            else {
                // Save photo failed with no error
            }
        })
    }
    
    private func drawerContextDidChange(_ context: GradientAction.DrawerContext) {
        switch context {
        case .customize: drawer.pager.collection.scrollToItem(at: IndexPath(row: 0, section: 0), at: .centeredHorizontally, animated: true)
        case .export: drawer.pager.collection.scrollToItem(at: IndexPath(row: 2, section: 0), at: .centeredHorizontally, animated: true)
        case .popular: drawer.pager.collection.scrollToItem(at: IndexPath(row: 1, section: 0), at: .centeredHorizontally, animated: true)
        }
    }
}

extension GradientCoordinator: GradientActionDispatching {
    func dispatch(_ action: GradientAction) {
        switch action {
        case .selectedGradient(let index):
            selectedGradient = gradients[index]
        case .selectedGradientFromDrawer(let index):
            content.scrollToPage(.at(index: index), animated: true)
        case .saveGradient(let image): saveImage(image: image)
        case .drawerContextChange(let context): drawerContextDidChange(context)
        
        case .colorIndexChange(let startingIndex, let endingIndex):
            if let gradient = selectedGradient {
                var colors = gradient.colors
                let element = colors.remove(at: startingIndex)
                colors.insert(element, at: endingIndex)
                selectedGradient?.colors = colors
            }
        }
    }
}


