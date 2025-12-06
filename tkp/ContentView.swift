import SwiftUI
import AVKit
import PhotosUI

struct ContentView: View {
    @State private var videoURLs: [URL] = []
    @State private var selectedVideoURL: URL?
    @State private var showPicker = false

    var body: some View {
        NavigationView {
            VStack {
                if let url = selectedVideoURL {
                    VideoPlayer(player: AVPlayer(url: url))
                        .frame(maxHeight: 300)
                } else {
                    Text("无视频\n点击右上角选择视频")
                        .multilineTextAlignment(.center)
                        .font(.title3)
                        .foregroundColor(.gray)
                        .padding()
                }

                Spacer()
            }
            .navigationTitle("TikTok Player")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showPicker = true
                    }) {
                        Image(systemName: "plus.circle")
                            .font(.title2)
                    }
                }
            }
            .photosPicker(isPresented: $showPicker,
                          selection: Binding(
                            get: { nil },
                            set: { newItem in
                                if let item = newItem {
                                    loadVideo(item: item)
                                }
                            }),
                          matching: .videos)
        }
    }

    func loadVideo(item: PhotosPickerItem) {
        item.loadTransferable(type: VideoTransferable.self) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let transferable):
                    if let transferable, let url = transferable.url {
                        self.selectedVideoURL = url
                    }
                case .failure(let error):
                    print("加载失败:", error)
                }
            }
        }
    }
}

// 支持从相册导入视频
struct VideoTransferable: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { exporting in
            SentTransferredFile(exporting.url)
        } importing: { received in
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("\(UUID().uuidString).mov")
            try FileManager.default.copyItem(at: received.file, to: tempURL)
            return VideoTransferable(url: tempURL)
        }
    }
}
