import UIKit
import AVKit
import PhotosUI

class VideoCell: UICollectionViewCell {
    static let identifier = "VideoCell"
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    private var label: UILabel?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
    }
    required init?(coder: NSCoder) { fatalError() }
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = contentView.bounds
        label?.frame = contentView.bounds.insetBy(dx: 20, dy: 20)
    }
    func configure(with url: URL?) {
        // clear
        player?.pause()
        playerLayer?.removeFromSuperlayer()
        label?.removeFromSuperview()
        label = nil
        guard let url = url else {
            let l = UILabel(frame: contentView.bounds)
            l.text = "无视频 - 点击右上角选择视频"
            l.textAlignment = .center
            l.numberOfLines = 2
            l.textColor = .white
            contentView.addSubview(l)
            label = l
            return
        }
        let item = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: item)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.videoGravity = .resizeAspectFill
        playerLayer?.frame = contentView.bounds
        if let pl = playerLayer { contentView.layer.addSublayer(pl) }
        player?.play()
        NotificationCenter.default.addObserver(self, selector: #selector(looped(_:)), name: .AVPlayerItemDidPlayToEndTime, object: item)
    }
    @objc private func looped(_ n: Notification) {
        player?.seek(to: .zero)
        player?.play()
    }
    override func prepareForReuse() {
        super.prepareForReuse()
        player?.pause()
        playerLayer?.removeFromSuperlayer()
        player = nil
        playerLayer = nil
        if let l = label { l.removeFromSuperview(); label = nil }
        NotificationCenter.default.removeObserver(self)
    }
}

class PlayerViewController: UIViewController {

    private var videos: [URL] = []
    private var collectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCollectionView()
        setupAddButton()
        loadVideosFromDocuments()
    }

    func setupAddButton() {
        let btn = UIBarButtonItem(title: "选择视频", style: .plain, target: self, action: #selector(selectVideos))
        navigationItem.rightBarButtonItem = btn
    }

    func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        layout.itemSize = view.bounds.size

        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.isPagingEnabled = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.backgroundColor = .black
        collectionView.register(VideoCell.self, forCellWithReuseIdentifier: VideoCell.identifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    @objc func selectVideos() {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.selectionLimit = 0
        config.filter = .videos
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    func loadVideosFromDocuments() {
        let fm = FileManager.default
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        let folder = docs.appendingPathComponent("tkp_videos")
        if !fm.fileExists(atPath: folder.path) {
            try? fm.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        let files = (try? fm.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? []
        videos = files.filter { ["mp4","mov","m4v"].contains($0.pathExtension.lowercased()) }
        DispatchQueue.main.async { self.collectionView.reloadData() }
    }
}

extension PlayerViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return max(videos.count, 1)
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: VideoCell.identifier, for: indexPath) as! VideoCell
        let url = videos.indices.contains(indexPath.row) ? videos[indexPath.row] : nil
        cell.configure(with: url)
        return cell
    }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let idx = Int(scrollView.contentOffset.y / view.frame.size.height)
        for c in collectionView.visibleCells {
            if let ip = collectionView.indexPath(for: c), ip.row != idx, let vc = c as? VideoCell {
                vc.player?.pause()
            }
        }
    }
}

extension PlayerViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        let fm = FileManager.default
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dest = docs.appendingPathComponent("tkp_videos")
        if !fm.fileExists(atPath: dest.path) { try? fm.createDirectory(at: dest, withIntermediateDirectories: true) }
        for item in results {
            if item.itemProvider.hasItemConformingToTypeIdentifier("public.movie") {
                item.itemProvider.loadFileRepresentation(forTypeIdentifier: "public.movie") { url, err in
                    guard let temp = url else { return }
                    let newName = UUID().uuidString + "_" + temp.lastPathComponent
                    let destURL = dest.appendingPathComponent(newName)
                    try? fm.removeItem(at: destURL)
                    do {
                        try fm.copyItem(at: temp, to: destURL)
                        DispatchQueue.main.async {
                            self.videos.append(destURL)
                            self.collectionView.reloadData()
                        }
                    } catch {
                        print("copy error", error)
                    }
                }
            }
        }
    }
}
