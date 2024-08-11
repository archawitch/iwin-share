import UIKit
import SwiftQRCodeScanner
import SwiftUI

struct QRScanner: UIViewControllerRepresentable {
    @Binding var showExtraOptions: Bool
    @Binding var result: Result<String, QRCodeError>?
    @Environment(\.presentationMode) var presentationMode
    
    func makeCoordinator() -> QRScanner.Coordinator {
        return Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> QRCodeScannerController {
        var picker: QRCodeScannerController?
        
        picker = QRCodeScannerController()
        
        picker!.delegate = context.coordinator
        return picker!
    }
    
    func updateUIViewController(_ uiViewController: QRCodeScannerController, context: Context) {}
}

extension QRScanner {
    class Coordinator: NSObject, QRScannerCodeDelegate {
        @Environment(\.presentationMode) var presentationMode
        var parent: QRScanner
        
        init(_ parent: QRScanner) {
            self.parent = parent
        }
        
        func qrScanner(_ controller: UIViewController, didScanQRCodeWithResult result: String) {
            parent.result = .success(result)
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func qrScanner(_ controller: UIViewController,
                       didFailWithError error: SwiftQRCodeScanner.QRCodeError) {
            parent.result = .failure(error)
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func qrScannerDidCancel(_ controller: UIViewController) {
            print("QR Controller did cancel")
        }
    }
}
