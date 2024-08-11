import SwiftUI
import Network
import UniformTypeIdentifiers

class ShareViewController: UIViewController, NetServiceBrowserDelegate, NetServiceDelegate {
    private let deviceName = UIDevice.current.name
    private let deviceIdentifier = UIDevice.current.identifierForVendor?.uuidString ?? ""
    
    private var netServiceBrowser: NetServiceBrowser?
    private var items: [NSItemProvider] = []
    
    private var viewModel = ShareExtensionViewModel()
    
    
    // MARK: - IDENTIFIERS
    
    private let allowedURLIdentifier = UTType.url.identifier
    private let allowedTextIdentifier = UTType.plainText.identifier
    private let allowedFilesTypes: [UTType] = [
        UTType.fileURL, .image, .movie, .video, .mp3, .audio, .quickTimeMovie, .avi, .aiff, .wav, .midi, .livePhoto, .tiff, .gif, UTType("com.apple.quicktime-image")!, UTType("com.apple.quicktime-movie")!, .icns]

    
    // MARK: - MULTIPART STRUCTS
    
    struct MultipartField: Identifiable {
        let id = UUID()
        let key: String
        let value: String
    }
    struct MultipartFile: Identifiable {
        let id = UUID()
        let key = "file-\(UUID().uuidString)"
        let name: String
        let mimeType: String
        let data: Data
    }
    
    // MARK: - FILES OR URL TO BE UPLOADED
    
    private var filesContent: [MultipartFile] = []
    private var urlContent: String = ""
    private var textContent: String = ""
    

    // MARK: - VIEWDIDLOAD
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let item = extensionContext?.inputItems.first as? NSExtensionItem,
            let providers = item.attachments else {
            print("No file attachments")
            close()
            return
        }
        
        // set up the app
        setupSwiftUIView()
        loadFiles(providers: providers)
        
        // discover services
        startServiceDiscovery()
        
        // listen for a closing signal from the main app to close the app when needed
        NotificationCenter.default.addObserver(forName: NSNotification.Name("close"), object: nil, queue: nil) { _ in
            DispatchQueue.main.async {
                self.close()
            }
        }
    }
    
    
    // MARK: - SET UP THE EXTENSION VIEW
    
    private func setupSwiftUIView() {
        let swiftUIView = ShareExtensionView(viewModel: viewModel) { service in
            self.sendFiles(to: service)
        }
        let contentView = UIHostingController(rootView: swiftUIView)
        
        addChild(contentView)
        view.addSubview(contentView.view)
        contentView.didMove(toParent: self)
        
        // set up constraints
        contentView.view.translatesAutoresizingMaskIntoConstraints = false
        contentView.view.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        contentView.view.bottomAnchor.constraint (equalTo: self.view.bottomAnchor).isActive = true
        contentView.view.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        contentView.view.rightAnchor.constraint (equalTo: self.view.rightAnchor).isActive = true
        
        print("Loaded UI view successfully")
    }
    
    
    // MARK: - LOAD DATA FROM FILES
    
    private func loadFiles(providers: [NSItemProvider]) {
        for provider: NSItemProvider in providers {
            print("Loading \(provider.registeredTypeIdentifiers)...")
            // a variable to check if the file conforms to app allowed types
            var isTypeValid = false
            
            // check if the file has a valid file type or not
            for type in allowedFilesTypes {
                let identifier = type.identifier
                if provider.hasItemConformingToTypeIdentifier(identifier) {
                    // the file is a valid file
                    isTypeValid = true
                    provider.loadItem(forTypeIdentifier: identifier, options: nil) { data, error in
                        guard error == nil else {
                            print("Could not load data: \(error!.localizedDescription)")
                            self.close()
                            return
                        }
                        
                        if let url = data as? URL, let fileData = try? Data(contentsOf: url) {
                            print("Loaded data successfully")
                            
                            let fileName = url.lastPathComponent
                            let mimeType = url.mimeType()  // Assuming `mimeType()` is defined elsewhere in your code
                            
                            let imageContent = MultipartFile(name: fileName, mimeType: mimeType, data: fileData)
                            self.filesContent.append(imageContent)
                        } else {
                            print("Failed to convert data to URL")
                            self.close()
                            return
                        }
                    }
                    break
                }
            }
            
            // or if it is not a file, then check if it is a string or URL or not both
            if !isTypeValid {
                // if the attachments contain URL, then extract only the first URL
                if provider.hasItemConformingToTypeIdentifier(allowedURLIdentifier) {
                    // the file is a valid URL
                    isTypeValid = true
                    provider.loadItem(forTypeIdentifier: allowedURLIdentifier, options: nil) { data, error in
                        guard error == nil else {
                            print("Could not load URL")
                            self.close()
                            return
                        }
                        
                        if let url = data as? URL {
                            let urlString = url.absoluteString
                            print("Loaded URL: \(urlString)")
                            self.urlContent = urlString
                        } else if let text = data as? String {
                            print("Loaded text: \(text)")
                            self.textContent = text
                        } else {
                            print("Failed to convert data to URL")
                            self.close()
                            return
                        }
                    }
                    return
                }
                // if the attachments does not contain a file, then try to check if it conforms to text type
                else if provider.hasItemConformingToTypeIdentifier(allowedTextIdentifier) {
                    // the file is a valid text
                    isTypeValid = true
                    provider.loadItem(forTypeIdentifier: allowedTextIdentifier, options: nil) { data, error in
                        guard error == nil else {
                            print("Could not load URL")
                            self.close()
                            return
                        }
                        
                        if let text = data as? String {
                            print("Loaded text: \(text)")
                            self.textContent = text
                        } else {
                            print("Failed to convert data to URL")
                            self.close()
                            return
                        }
                    }
                    return
                }
            }
            
            // otherwise, the file does not comform to any allowed types, so we close the app
            if !isTypeValid {
                print("an item does not conform to any identifiers")
                self.close()
            }
        }
    }
    
    
    // MARK: - HANDLE SERVICE DISCOVERY
    
    private func startServiceDiscovery() {
        let params = NWParameters()
        params.includePeerToPeer = true
        
        let serviceType = "_iw._tcp"
        let browser = NWBrowser(for: .bonjour(type: serviceType, domain: nil), using: params)
        
        browser.stateUpdateHandler = { newState in
            switch newState {
            case .failed(let error):
                print("NW Browser is in error state: \(error)")
            case .ready:
                print("NW Browser is in ready state")
            default:
                break
            }
        }
        
        browser.browseResultsChangedHandler = { results, change in
            print("Browser results has changed")
            self.viewModel.clearService()
            for result in results {
                var serviceName = result.endpoint.debugDescription
                print("Found: \(serviceName)")
            
                if let range = serviceName.range(of: "._iw") {
                    serviceName = String(serviceName[..<range.lowerBound])
                    
                    let arr = serviceName.components(separatedBy: "__")
                    if arr.count != 2 {
                        print("Invalid service name: \(serviceName)")
                        break
                    }
                    
                    let ipArr = arr[1].components(separatedBy: "--")
                    if ipArr.count != 4 {
                        print("Invalid service name: \(serviceName)")
                        break
                    }
                    
                    let hostName = arr[0]
                    let ipAddr = "\(ipArr[0]).\(ipArr[1]).\(ipArr[2]).\(ipArr[3])"
                    
                    print("Discovered iWin service: \(hostName) (\(ipAddr))")
                    
                    // Connect to the file receiving server
                    self.post(dstURL: "http:\(ipAddr):6789/connect", endpoint: "connect") { data, response, error in
                        if error != nil {
                            print("An error occured while connecting to the server")
                        }
                        else if let response = response as? HTTPURLResponse, response.statusCode == 200 {
                            print("Connected to \(hostName) (\(ipAddr))")
                            
                            // TODO: - Add service to the service list
                            self.viewModel.addService(name: hostName, ipAddr: ipAddr)
                        } else {
                            print("Failed to connect to the server")
                        }
                    }
                    
                } else {
                    print("The service name [\(serviceName)] is not used in this app")
                }
            }
        }
        
        browser.start(queue: .main)
        print("Started Browsing...")
    }
    
    
    // MARK: - HANDLE APP ACTIONS

    private func sendFiles(to service: Service) {
        post(dstURL: "http:\(service.ipAddr):6789/upload", endpoint: "upload") { data, response, error in
            if let response = response as? HTTPURLResponse, response.statusCode == 200 {
                print("Uploaded files successfully")
                self.close()
                return
            }
            
            print("Could not upload files")
        }
    }
    
    
    // MARK: - HANDLE POST REQUEST
    
    func post(dstURL: String, endpoint: String, completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        guard let url = URL(string: dstURL) else {
            print("Invalid URL: \(dstURL)")
            self.close()
            return
        }
        
        switch endpoint {
        case "connect":
            print("Connecting...")
            
            let queryItems: [URLQueryItem] = [URLQueryItem(name: "name", value: deviceName),
                                              URLQueryItem(name: "identifier", value: deviceIdentifier)]
            
            let request = createFormURLEncodedRequest(url: url, queryItems: queryItems)
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                completion(data, response, error)
            }.resume()
            
        case "upload":
            print("Uploading...")
            
            var fields: [MultipartField] = [MultipartField(key: "name", value: deviceName),
                                            MultipartField(key: "identifier", value: deviceIdentifier)]
            
            // check if we send a URL or not
            if urlContent != "" {
                fields.append(MultipartField(key: "url", value: urlContent))
            }
            // or if we send a text or not
            if textContent != "" {
                fields.append(MultipartField(key: "text", value: textContent))
            }
            
            let request: URLRequest = createMultipartRequest(url: url, fields: fields, files: filesContent)
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                completion(data, response, error)
            }.resume()
            
            
        default:
            print("Invalid URL endpoint")
            return
        }
    }
    
    func createFormURLEncodedRequest(url: URL, queryItems: [URLQueryItem]) -> URLRequest {
        let headers: [String:String] = ["Content-Type": "application/x-www-form-urlencoded"]
        
        var components = URLComponents()
        components.queryItems = queryItems
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = components.query?.data(using: .utf8)
        
        return request
    }
    
    func createMultipartRequest(url: URL, fields: [MultipartField], files: [MultipartFile]) -> URLRequest {
        let boundary = UUID().uuidString
        let headers: [String:String] = ["Content-Type": "multipart/form-data; boundary=\(boundary)"]
        
        // check if we send a URL or files
        let body: Data = createMultipartBody(boundary: boundary, fields: fields, files: files)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = body
        
        return request
    }
    
    func createMultipartBody(boundary: String, fields: [MultipartField], files: [MultipartFile]) -> Data {
        var body = Data()

        for field in fields {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(field.key)\"\r\n\r\n\(field.value)\r\n")
        }

        for file in files {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(file.key)\"; filename=\"\(file.name)\"\r\n")
            body.append("Content-Type: \(file.mimeType)\r\n\r\n")
            body.append(file.data)
            body.append("\r\n")
        }

        body.append("--\(boundary)--\r\n")
        
        return body
    }
    
    
    // MARK: - CLOSE THE EXTENSION
    
    func close() {
        urlContent = ""
        filesContent.removeAll()
        viewModel.clearService()
        
        print("Content cleared")
        print("Closing the extension...")
        
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
    
}


// MARK: - EXTENSION FOR SOME CLASSES

extension Data {
    mutating func append(
        _ string: String,
        encoding: String.Encoding = .utf8
    ) {
        guard let data = string.data(using: encoding) else {
            return
        }
        append(data)
    }
}

extension URL {
    func mimeType() -> String {
        if let mimeType = UTType(filenameExtension: self.pathExtension)?.preferredMIMEType {
            return mimeType
        }
        else {
            return "application/octet-stream"
        }
    }
}
