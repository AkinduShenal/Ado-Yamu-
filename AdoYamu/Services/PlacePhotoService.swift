import Foundation

@MainActor protocol PlacePhotoSearching {
    func enrich(_ places: [Destination], near origin: Coordinate) async throws -> [Destination]
}

struct PhotoArticle: Decodable {
    struct Point: Decodable { let lat: Double; let lon: Double }
    let title: String
    let pageimage: String?
    let coordinates: [Point]?
}

enum PhotoPlaceMatcher {
    static func landmarkCategory(_ name: String) -> PlaceCategory? {
        let value = name.lowercased()
        guard !["bombing", "attack", "assassination", "battle", "college", "school", "hospital", "ministry", "railway", "station"].contains(where: value.contains) else { return nil }
        if Destination.isTempleName(name) { return .culture }
        let words = Set(value.components(separatedBy: CharacterSet.alphanumerics.inverted))
        if !words.isDisjoint(with: ["beach", "bay"]) { return .beaches }
        if !words.isDisjoint(with: ["waterfall", "falls"]) { return .waterfalls }
        if !words.isDisjoint(with: ["park", "gardens", "garden", "lake"]) { return .nature }
        if !words.isDisjoint(with: ["museum", "temple", "fort", "bridge", "market"]) { return .culture }
        return nil
    }
    static func matches(name: String, point: Coordinate, article: PhotoArticle) -> Bool {
        guard let location = article.coordinates?.first,
              point.kilometers(to: Coordinate(latitude: location.lat, longitude: location.lon)) <= 1 else { return false }
        let lhs = tokens(name), rhs = tokens(article.title)
        let overlap = lhs.intersection(rhs)
        guard !overlap.isEmpty, !lhs.isEmpty, !rhs.isEmpty else { return false }
        let coverage = Double(overlap.count) / Double(max(lhs.count, rhs.count))
        return coverage >= 0.75 && (overlap.count >= 2 || overlap.contains { $0.count >= 7 })
    }
    private static func tokens(_ value: String) -> Set<String> {
        let generic: Set<String> = ["the", "of", "and", "sri", "lanka", "colombo"]
        let normalized = value.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en"))
        return Set(normalized.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { $0.count > 1 && !generic.contains($0) })
    }
    static func bundledPhoto(for place: Destination) -> String? {
        guard let point = place.coordinate else { return nil }
        return DestinationCatalog.all.first { candidate in
            guard let coordinate = candidate.coordinate else { return false }
            let article = PhotoArticle(title: candidate.name, pageimage: nil, coordinates: [.init(lat: coordinate.latitude, lon: coordinate.longitude)])
            return matches(name: place.name, point: point, article: article)
        }?.image
    }
    static func isReusableLicense(_ license: String) -> Bool {
        let value = license.lowercased()
        return value.hasPrefix("cc by") || value.hasPrefix("cc-by") || value.hasPrefix("cc0") || value == "public domain" || value == "pdm"
    }
    static func plainText(_ html: String) -> String {
        html.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&amp;", with: "&").replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'").replacingOccurrences(of: "&nbsp;", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

@MainActor final class WikimediaPhotoService: PlacePhotoSearching {
    private struct Cache { let date: Date; let photo: PlacePhoto? }
    private var cache: [String: Cache] = [:]
    private static var nextRequest = Date.distantPast

    func enrich(_ places: [Destination], near origin: Coordinate) async throws -> [Destination] {
        cache = cache.filter { Date.now.timeIntervalSince($0.value.date) < 86_400 }
        var result = places.map { place in
            var value = place
            if value.image.isEmpty, let bundled = PhotoPlaceMatcher.bundledPhoto(for: place) { value.image = bundled }
            if let cached = cache[place.id], Date.now.timeIntervalSince(cached.date) < 86_400 { value.photo = cached.photo }
            return value
        }
        // One bounded geographic lookup, followed by small batches of file credits.
        // A nearby article is only accepted when its name ALSO matches the venue.
        let response: ArticleResponse = try await request(host: "en.wikipedia.org", parameters: [
            "generator": "geosearch", "ggscoord": "\(origin.latitude)|\(origin.longitude)", "ggsradius": "10000",
            "ggslimit": "50", "ggsnamespace": "0", "prop": "pageimages|coordinates", "piprop": "name",
            "pilicense": "free", "pilimit": "50", "colimit": "max"
        ])
        // Discover image-backed landmarks as well as enriching MapKit venues.
        // Titles classify the broad category only; fees/access/hours stay unknown.
        let articles = response.query?.pages ?? []
        for article in articles {
            guard let category = PhotoPlaceMatcher.landmarkCategory(article.title), let point = article.coordinates?.first,
                  article.pageimage != nil else { continue }
            let coordinate = Coordinate(latitude: point.lat, longitude: point.lon)
            guard coordinate.isInSriLanka, !result.contains(where: { place in
                place.coordinate.map { PhotoPlaceMatcher.matches(name: place.name, point: $0, article: article) } ?? false
            }) else { continue }
            let moods: Set<Mood> = Destination.isTempleName(article.title) ? [.chill, .adventure] : category == .beaches ? [.chill, .romantic] : category == .waterfalls ? [.adventure, .chill] : [.chill, .adventure, .romantic]
            var source = URLComponents(); source.scheme = "https"; source.host = "en.wikipedia.org"
            source.path = "/wiki/" + article.title.replacingOccurrences(of: " ", with: "_")
            let id = "wiki|" + (article.title.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? article.title.replacingOccurrences(of: ",", with: " "))
            result.append(Destination(id: id, name: article.title, district: "", locality: "Sri Lanka", category: category, moods: moods,
                summary: "A nearby landmark listed on Wikipedia. Explore its source page for background, and confirm local access, admission and conditions before travelling.",
                coordinate: coordinate, minutes: 60, budget: .easy, image: "", tags: [category.rawValue, "Nearby landmark"], source: .wikipedia, sourceURL: source.url, fetchedAt: .now))
        }
        // Keep lookup/credit work bounded even in a dense city centre.
        let photoCandidates = Array(result.filter { $0.image.isEmpty && $0.photo == nil }.prefix(24))
        var matches: [String: PhotoArticle] = [:]
        for place in photoCandidates {
            guard let point = place.coordinate else { continue }
            matches[place.id] = articles.first { article in
                guard let file = article.pageimage?.lowercased(), ![".svg", "logo", "flag", "coat_of", "locator", "map."].contains(where: file.contains) else { return false }
                return PhotoPlaceMatcher.matches(name: place.name, point: point, article: article)
            }
        }
        let names = Array(Set(matches.values.compactMap(\.pageimage))).sorted().prefix(12)
        let fileNames = Array(names)
        var credits: [String: PlacePhoto] = [:]
        for offset in stride(from: 0, to: fileNames.count, by: 6) {
            try Task.checkCancellation()
            let batch = Array(fileNames.dropFirst(offset).prefix(6))
            let files: FileResponse = try await request(host: "commons.wikimedia.org", parameters: [
                "prop": "imageinfo", "titles": batch.map { "File:\($0)" }.joined(separator: "|"),
                "iiprop": "url|extmetadata|mime", "iiurlwidth": "960",
                "iiextmetadatafilter": "Artist|LicenseShortName|LicenseUrl", "iiextmetadatalanguage": "en"
            ])
            for page in files.query?.pages ?? [] {
                guard let info = page.imageinfo?.first,
                      ["image/jpeg", "image/png", "image/webp"].contains(info.mime ?? ""),
                      let authorHTML = info.extmetadata?["Artist"]?.value,
                      let license = info.extmetadata?["LicenseShortName"]?.value,
                      PhotoPlaceMatcher.isReusableLicense(license),
                      let source = URL(string: info.descriptionurl ?? ""), source.host == "commons.wikimedia.org",
                      let image = URL(string: info.thumburl ?? info.url ?? ""), image.scheme == "https",
                      ["upload.wikimedia.org", "thumb.wikimedia.org"].contains(image.host ?? "") else { continue }
                let author = PhotoPlaceMatcher.plainText(authorHTML)
                guard !author.isEmpty else { continue }
                var licenseValue = info.extmetadata?["LicenseUrl"]?.value ?? ""
                if licenseValue.hasPrefix("//") { licenseValue = "https:" + licenseValue }
                guard let licenseURL = URL(string: licenseValue), ["http", "https"].contains(licenseURL.scheme ?? "") else { continue }
                let title = page.title.replacingOccurrences(of: "File:", with: "").replacingOccurrences(of: "_", with: " ")
                credits[title] = PlacePhoto(url: image, sourceURL: source, author: author, license: license, licenseURL: licenseURL)
            }
        }
        for index in result.indices where result[index].image.isEmpty {
            let key = matches[result[index].id]?.pageimage?.replacingOccurrences(of: "_", with: " ") ?? ""
            if let photo = credits[key] { result[index].photo = photo }
            cache[result[index].id] = Cache(date: .now, photo: result[index].photo)
        }
        result.removeAll { $0.source == .wikipedia && $0.photo == nil }
        if cache.count > 200 { cache = Dictionary(uniqueKeysWithValues: cache.sorted { $0.value.date > $1.value.date }.prefix(150).map { ($0.key, $0.value) }) }
        return result
    }
    private func request<T: Decodable>(host: String, parameters: [String: String]) async throws -> T {
        let now = Date.now, slot = max(Date.now, Self.nextRequest)
        Self.nextRequest = slot.addingTimeInterval(1)
        if slot > now { try await Task.sleep(for: .seconds(slot.timeIntervalSince(now))) }
        try Task.checkCancellation()
        var components = URLComponents(); components.scheme = "https"; components.host = host; components.path = "/w/api.php"
        components.queryItems = (parameters.merging(["action": "query", "format": "json", "formatversion": "2", "maxlag": "5"], uniquingKeysWith: { _, new in new })).sorted { $0.key < $1.key }.map { URLQueryItem(name: $0.key, value: $0.value) }
        guard let url = components.url else { throw NearbyServiceError.invalidResponse }
        var request = URLRequest(url: url, timeoutInterval: 9)
        request.setValue("AdoYamu/1.0 (native iOS exploration app; Wikimedia place photos)", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200, data.count <= 2_000_000 else { throw NearbyServiceError.unavailable }
        return try JSONDecoder().decode(T.self, from: data)
    }
    private struct ArticleResponse: Decodable { struct Query: Decodable { let pages: [PhotoArticle]? }; let query: Query? }
    private struct FileResponse: Decodable {
        struct Query: Decodable { let pages: [Page]? }
        struct Page: Decodable { let title: String; let imageinfo: [Info]? }
        struct Info: Decodable {
            struct Metadata: Decodable { let value: String }
            let url: String?; let thumburl: String?; let descriptionurl: String?; let mime: String?
            let extmetadata: [String: Metadata]?
        }
        let query: Query?
    }
}
