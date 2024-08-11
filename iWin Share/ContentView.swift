import SwiftUI
import Network
import SwiftQRCodeScanner

struct Service: Codable, Identifiable {
    var id = UUID()
    let name: String
}

struct ContentView: View {
    private let deviceName = UIDevice.current.name
    private let deviceIdentifier = UIDevice.current.identifierForVendor?.uuidString ?? ""
    
    @State private var showingNoInternet = false
    
    @State private var showingScanner = false
    @State private var showExtraOptions = false
    @State private var scannedValue: String = ""
    @State private var result: Result<String, QRCodeError>?
    
    @State private var showingSuccessAlert = false
    @State private var successAlertValue = ""
    @State private var showingErrorAlert = false
    @State private var errorAlertValue = ""

    @State private var services: [Service] = []
    
    var body: some View {
        VStack (spacing: 20) {
            Text("Connected PCs")
                .padding(.top)
                .font(.title .bold())
            
            List(services) { service in
                HStack(spacing: 0) {
                    Text(service.name)
                    Spacer()
                    Button {
                        self.removeService(id: service.id)
                    } label: {
                        Text("delete")
                            .foregroundStyle(.red)
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 4)
            }
            
            Spacer()
            
            Button {
                self.showingScanner = true
            } label: {
                Label("Connect", systemImage: "qrcode.viewfinder")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .padding(.bottom)
            .sheet(isPresented: $showingScanner) {
                QRScanner(showExtraOptions: $showExtraOptions, result: self.$result)
            }
            .onChange(of: result) { newValue in
                guard let unwrappedResult = newValue else { return }
                switch unwrappedResult {
                case .success(let qrCodeString):
                    print("Scanned text: \(qrCodeString)")
                    
                    // TODO: - Register to the the PC
                    registerToService(qrCodeString: qrCodeString) { success, error in
                        if success {
                            self.showingSuccessAlert = true
                        } else {
                            self.errorAlertValue = error
                            self.showingErrorAlert = true
                        }
                    }
                    
                case .failure(let qrCodeError):
                    print("Failed to scan the QR code: \(qrCodeError)")
                    self.errorAlertValue = "Could not scan the QR code"
                    self.showingErrorAlert = true
                }
            }
            .alert("Note: Verify this device on your computer to complete the registration", isPresented: $showingSuccessAlert) {
                Button("OK", role: .cancel) {
                    self.result = nil
                }
            }
            .alert("Failed to register: \(self.errorAlertValue)", isPresented: $showingErrorAlert) {
                Button("OK", role: .cancel) {
                    self.result = nil
                }
            }
            .alert("No internet connection", isPresented: $showingNoInternet) {
                Button("OK", role: .cancel) {}
            }
        }
        .padding()
        .onAppear() {
            LocalNetworkAuthorization().requestAuthorization()
            loadServices()
        }
    }
    
    func addService(name: String) {
        let service = Service(name: name)
        services.append(service)
        saveServices()
    }
    
    func removeService(id: UUID) {
        services = services.filter { $0.id != id }
        saveServices()
        
        print("Service removed")
    }
    
    func saveServices() {
        if let data = try? JSONEncoder().encode(services) {
            UserDefaults.standard.set(data, forKey: "services")
        }
    }
    
    func loadServices() {
        if let data = UserDefaults.standard.data(forKey: "services"),
           let savedServices = try? JSONDecoder().decode([Service].self, from: data) {
            services = savedServices
            
            return
        }
        
        services = []
    }


    
    // MARK: - HANDLE POST REQUEST
    
    func registerToService(qrCodeString: String, completion: @escaping (Bool, String) -> Void) {
        print("Registering to service...")
        let arr = qrCodeString.components(separatedBy: " ")
        if arr.count == 2 {
            let hostName = arr[0]
            let ipAddr = arr[1]
            
            // Connect to the file receiving server
            post(dstURL: "http:\(ipAddr):6789/addDevice", endpoint: "addDevice") { data, response, error in
                let response = response as? HTTPURLResponse
                if response?.statusCode == 200 {
                    print("Registered to \(hostName) (\(ipAddr)) successfully")
                    addService(name: hostName)
                    completion(true, "")
                } else if response?.statusCode == 400 {
                    print("Already connected to \(hostName) (\(ipAddr))")
                    completion(false, "Already connected to \(hostName) (\(ipAddr))")
                } else {
                    print("Could not register to \(hostName) (\(ipAddr))")
                    completion(false, "Could register to \(hostName) (\(ipAddr))")
                }
            }
        } else {
            print("Service name invalid")
            completion(false, "Service name invalid")
        }
    }
    
    func post(dstURL: String, endpoint: String, completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        guard let url = URL(string: dstURL) else {
            print("Invalid URL")
            return
        }
        
        switch endpoint {
        case "addDevice":
            print("Registering...")
            
            let queryItems: [URLQueryItem] = [URLQueryItem(name: "name", value: deviceName),
                                              URLQueryItem(name: "identifier", value: deviceIdentifier)]
            
            let request = createFormURLEncodedRequest(url: url, queryItems: queryItems)
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                completion(data, response, error)
            }.resume()
            
        default:
            print("Invalid endpoint")
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
}
