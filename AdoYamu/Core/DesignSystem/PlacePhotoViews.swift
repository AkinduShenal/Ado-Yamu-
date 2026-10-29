import SwiftUI
import ImageIO

@MainActor private enum PlaceImageCache {
    static let images: NSCache<NSURL, UIImage> = {
        let result = NSCache<NSURL, UIImage>(); result.totalCostLimit = 24_000_000; return result
    }()
    static let session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = URLCache(memoryCapacity: 12_000_000, diskCapacity: 60_000_000, diskPath: "AdoYamuPlacePhotos")
        configuration.timeoutIntervalForRequest = 12
        return URLSession(configuration: configuration)
    }()
    static func load(_ url: URL) async throws -> UIImage {
        if let image = images.object(forKey: url as NSURL) { return image }
        var request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
        request.setValue("AdoYamu/1.0 (native iOS exploration app)", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await session.data(for: request)
        try Task.checkCancellation()
        guard (response as? HTTPURLResponse)?.statusCode == 200, data.count <= 8_000_000,
              let source = CGImageSourceCreateWithData(data as CFData, nil),
              let cg = CGImageSourceCreateThumbnailAtIndex(source, 0, [kCGImageSourceCreateThumbnailFromImageAlways: true,
                   kCGImageSourceThumbnailMaxPixelSize: 1_200, kCGImageSourceCreateThumbnailWithTransform: true] as CFDictionary) else { throw NearbyServiceError.invalidResponse }
        let image = UIImage(cgImage: cg); images.setObject(image, forKey: url as NSURL, cost: cg.bytesPerRow * cg.height)
        return image
    }
}

struct RemotePlacePhoto: View {
    let place: Destination
    let photo: PlacePhoto
    var contentMode: ContentMode = .fill
    @State private var image: UIImage?
    @State private var failed = false
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                YamuTheme.gradient.opacity(0.18)
                if let image { Image(uiImage: image).resizable().aspectRatio(contentMode: contentMode).frame(width: geometry.size.width, height: geometry.size.height).clipped() }
                else if failed { OnlinePlaceMapPreview(place: place) }
                else { ProgressView().tint(YamuTheme.purple).accessibilityLabel("Loading photo of \(place.name)") }
            }
        }.clipped().contentShape(Rectangle())
            .accessibilityElement(children: .ignore).accessibilityLabel("\(place.name) photograph")
            .accessibilityIdentifier(image == nil ? "loading-photo-\(place.id)" : "loaded-photo-\(place.id)")
            .accessibilityValue(image != nil ? "Photo loaded" : failed ? "Photo unavailable, showing map" : "Loading photo")
            .task(id: photo.url) {
            image = nil; failed = false
            do { image = try await PlaceImageCache.load(photo.url) }
            catch { if !Task.isCancelled { failed = true } }
        }
    }
}

struct PlacePhotoCredit: View {
    let photo: PlacePhoto
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Link("Photo: \(photo.credit)", destination: photo.sourceURL).font(.caption2).foregroundStyle(YamuTheme.muted)
            Link("Photo license · cropped to fit", destination: photo.licenseURL).font(.caption2).foregroundStyle(YamuTheme.purple)
        }
    }
}
