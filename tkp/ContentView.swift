import SwiftUI
import AVKit
import PhotosUI

struct ContentView: View {

    @State private var selectedVideoURL: URL?
    @State private var showPicker = false
    @State private var pickerItem: PhotosPickerItem?

    var body: some View {
        NavigationView {
            VStack {

                if let url = selectedVideoURL {
                    VideoPlayer(player: AVPlayer(url: url))
                        .frame(height: 300)
                        .cornerRadius(12)
                        .padding()
                } else {
                    Text("无视频\n点击右上角选择视频")
                        .multilineTextAlignment(.center)
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
                          selection: $pickerItem,
                          matching: .videos)
            .onChange(of: pickerItem) { newItem in
                if let item = newItem {
                    loadVideo(from: item)
                }
            }
        }
    }

    private func loadVideo(from item: PhotosPickerItem) {
        item.loadTransferable(type: VideoTransfer.self) { result in
            switch result {
            case .success(let video):
                if let video = video {
                    DispatchQueue.main.async {
                        selectedVideoURL = video.url
                    }
                }
            case .failure(let error):
                print("读取失败:", error.localizedDescription)
            }
        }
    }
}

struct VideoTransfer: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { video in
            SentTransferredFile(video.url)
        } importing: { received in
            let temp = FileManager.default.temporaryDirectory
                .appendingPathComponent("\(UUID().uuidString).mov")
            try FileManager.default.copyItem(at: received.file, to: temp)
            return VideoTransfer(url: temp)
        }
    }
}
