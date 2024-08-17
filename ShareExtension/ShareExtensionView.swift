import SwiftUI

class ShareExtensionViewModel: ObservableObject {
    @Published var discoveredServices: [Service] = []

    func addService(name: String, ipAddr: String) {
        let service = Service(name: name, ipAddr: ipAddr)
        DispatchQueue.main.async {
            self.discoveredServices.append(service)
        }
    }
    
    func clearService() {
        if discoveredServices.count > 0 {
            DispatchQueue.main.async {
                self.discoveredServices.removeAll()
            }
        }
    }
}

struct ShareExtensionView: View {
    @ObservedObject var viewModel: ShareExtensionViewModel
    let sendFiles: (Service) -> Void

    var body: some View {
        NavigationStack{
            Divider()
            VStack (spacing: 20) {
                ForEach(viewModel.discoveredServices) { service in
                    HStack (spacing: 20) {
                        VStack (alignment: .leading, spacing: 0) {
                            Text(service.name)
                                .font(.headline)
                            Text(service.ipAddr)
                                .font(.subheadline)
                        }
                        Spacer()
                        Button {
                            // TODO: send files
                            sendFiles(service)
                        } label: {
                            Text("Send")
                        }
                    }
                    .padding()
                    .scaledToFit()
                    .background(Color(uiColor: .secondarySystemBackground).clipShape(RoundedRectangle(cornerRadius:16)))
                }
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        Text("Send to").font(.headline)
                        Spacer()
                        Button {
                            close()
                        } label: {
                            Image(systemName: "xmark")
                        }
                        .foregroundColor(Color.secondary)
                    }
                }
            }
        }
    }
    
    func close() {
        NotificationCenter.default.post(name: NSNotification.Name("close"), object: nil)
    }
}
