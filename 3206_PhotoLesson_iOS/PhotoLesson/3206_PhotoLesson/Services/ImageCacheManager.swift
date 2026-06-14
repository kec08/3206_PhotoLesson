import SwiftUI
import UIKit

class ImageCacheManager {
    static let shared = ImageCacheManager()

    private let cache = NSCache<NSString, UIImage>()

    private init() {
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
    }

    func image(for url: URL) -> UIImage? {
        cache.object(forKey: url.absoluteString as NSString)
    }

    func setImage(_ image: UIImage, for url: URL) {
        cache.setObject(image, forKey: url.absoluteString as NSString)
    }
}

struct CachedAsyncImage<Placeholder: View>: View {
    let url: URL?
    let placeholder: () -> Placeholder

    @State private var image: UIImage?
    @State private var isLoading = false

    init(url: URL?, @ViewBuilder placeholder: @escaping () -> Placeholder) {
        self.url = url
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
            } else {
                placeholder()
                    .onAppear { loadImage() }
            }
        }
    }

    private func loadImage() {
        guard let url = url, !isLoading else { return }

        // 캐시 확인
        if let cached = ImageCacheManager.shared.image(for: url) {
            self.image = cached
            return
        }

        isLoading = true

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data, let uiImage = UIImage(data: data) else {
                DispatchQueue.main.async { isLoading = false }
                return
            }

            ImageCacheManager.shared.setImage(uiImage, for: url)

            DispatchQueue.main.async {
                self.image = uiImage
                isLoading = false
            }
        }.resume()
    }
}
