//import Foundation
//import SwiftUI
//import UIKit
//
//class ShareViewController: UIViewController {
//    private let deviceName = UIDevice.current.name
//    private let deviceIdentifier = UIDevice.current.identifierForVendor?.uuidString ?? ""
//    
//    private var viewModel = ShareViewModel()
//    
//    
//    // MARK: - MULTIPART STRUCTS
//    
//    struct MultipartField: Identifiable {
//        let id = UUID()
//        let key: String
//        let value: String
//    }
//    
//    
//    // MARK: - VIEWDIDLOAD
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        let swiftUIView = ContentView(viewModel: viewModel, connect: connect)
//        let hostingController = UIHostingController(rootView: swiftUIView)
//        
//        addChild(hostingController)
//        hostingController.view.frame = view.bounds
//        view.addSubview(hostingController.view)
//        hostingController.didMove(toParent: self)
//    }
//    
//    
//    // MARK: - CONNECT TO THE SERVICE
//    func connect() {
//        
//    }
//    
//    
//    // MARK: - HANDLE POST REQUEST
//    
//    func post(dstURL: String, endpoint: String, completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
//        guard let url = URL(string: dstURL) else {
//            print("Invalid URL")
//            return
//        }
//        
//        switch endpoint {
//        case "addDevice":
//            print("Adding your device to the service...")
//            
//            let queryItems: [URLQueryItem] = [URLQueryItem(name: "name", value: deviceName),
//                                              URLQueryItem(name: "identifier", value: deviceIdentifier)]
//            
//            let request = createFormURLEncodedRequest(url: url, queryItems: queryItems)
//            
//            URLSession.shared.dataTask(with: request) { data, response, error in
//                completion(data, response, error)
//            }.resume()
//            
//        default:
//            print("Invalid endpoint")
//            return
//        }
//    }
//    
//    func createFormURLEncodedRequest(url: URL, queryItems: [URLQueryItem]) -> URLRequest {
//        let headers: [String:String] = ["Content-Type": "application/x-www-form-urlencoded"]
//        
//        var components = URLComponents()
//        components.queryItems = queryItems
//        
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.allHTTPHeaderFields = headers
//        request.httpBody = components.query?.data(using: .utf8)
//        
//        return request
//    }
//}
