import Foundation

enum DestinationCatalog {
    // Durations are suggested time at the destination, excluding travel.
    // Budget tiers are illustrative planning bands, never entrance-fee quotes.
    static let all: [Destination] = [
        .init(id: "pidurangala", name: "Pidurangala Rock", district: "Matale", locality: "Sigiriya", category: .hiking, moods: [.adventure, .romantic], summary: "A rocky climb above the forest, with wide views toward Sigiriya. Take your time on the final boulders, wear grippy shoes and respect the temple at the start of the trail.", coordinate: .init(latitude: 7.9658, longitude: 80.7615), minutes: 150, budget: .easy, image: "pidurangala", tags: ["Scenic views", "Photography", "Temple trail"], experienceTags: [.active]),
        .init(id: "ravana", name: "Ravana Falls", district: "Badulla", locality: "Ella", category: .waterfalls, moods: [.chill, .adventure], summary: "A dramatic cascade beside the road south of Ella. Enjoy the spray and surrounding greenery from established viewpoints; wet rocks and changing currents make climbing or swimming unsafe.", coordinate: .init(latitude: 6.8407, longitude: 81.0545), minutes: 60, budget: .pocket, image: "ravana", tags: ["Waterfall", "Nature", "Viewpoint"], experienceTags: [.greenery]),
        .init(id: "hiriketiya", name: "Hiriketiya Beach", district: "Matara", locality: "Dikwella", category: .beaches, moods: [.chill, .romantic, .food], summary: "A small palm-fringed bay near Dikwella. Settle into the shade, wander the shore and discover the cafés nearby. Check local sea conditions before entering the water.", coordinate: .init(latitude: 5.9633, longitude: 80.7065), minutes: 150, budget: .easy, image: "hiriketiya", tags: ["Beach", "Slow afternoons", "Cafés"], experienceTags: [.seaside, .wander]),
        .init(id: "bridge", name: "Nine Arches Bridge", district: "Badulla", locality: "Ella", category: .culture, moods: [.adventure, .chill], summary: "An elegant stone railway viaduct surrounded by green hills near Ella and Demodara. See the arches from the paths and viewpoints, keeping clear of the active railway tracks.", coordinate: .init(latitude: 6.8768, longitude: 81.0608), minutes: 120, budget: .pocket, image: "bridge", tags: ["Iconic", "Photography", "Heritage"], experienceTags: [.greenery, .wander]),
        .init(id: "diyaluma", name: "Diyaluma Falls", district: "Badulla", locality: "Koslanda", category: .waterfalls, moods: [.adventure], summary: "A soaring ribbon of water near Koslanda, framed by rocky slopes and forest. Start with the roadside view. Upper trails need local guidance and suitable conditions; keep well away from edges and fast water.", coordinate: .init(latitude: 6.7332, longitude: 81.0313), minutes: 180, budget: .easy, image: "diyaluma", tags: ["Waterfall", "Scenic views", "Outdoors"], experienceTags: [.greenery, .active]),
        .init(id: "bambarakanda", name: "Bambarakanda Falls", district: "Badulla", locality: "Kalupahana", category: .waterfalls, moods: [.adventure, .chill], summary: "A slender waterfall dropping through the pine-covered hills near Kalupahana. Follow marked access paths to enjoy the valley and the cascade, and check local trail conditions before setting out.", coordinate: .init(latitude: 6.7734, longitude: 80.8313), minutes: 150, budget: .easy, image: "bambarakanda", tags: ["Pine forest", "Waterfall", "Nature"], experienceTags: [.greenery, .wander]),
        .init(id: "dunhinda", name: "Dunhinda Falls", district: "Badulla", locality: "Badulla", category: .waterfalls, moods: [.adventure], summary: "Walk through the wooded valley to a viewpoint over a misty cascade near Badulla. Allow time for the return walk and take care on uneven, slippery sections of the path.", coordinate: .init(latitude: 7.0173, longitude: 81.0634), minutes: 150, budget: .easy, image: "dunhinda", tags: ["Forest walk", "Waterfall", "Viewpoint"], experienceTags: [.greenery, .active]),
        .init(id: "mirissa", name: "Mirissa Beach", district: "Matara", locality: "Mirissa", category: .beaches, moods: [.chill, .romantic, .food], summary: "A curving stretch of sand on the south coast. Watch the changing light, stroll beside the bay and find a spot for a relaxed meal. Follow local guidance on currents and swimming conditions.", coordinate: .init(latitude: 5.9447, longitude: 80.4590), minutes: 60, budget: .pocket, image: "mirissa", tags: ["Sunset", "Beach", "Cafés"], experienceTags: [.seaside, .wander]),
        .init(id: "unawatuna", name: "Unawatuna Beach", district: "Galle", locality: "Unawatuna", category: .beaches, moods: [.chill, .romantic, .food], summary: "A lively bay close to Galle, with palms, sandy walks and plenty of small places to eat. Come for an easy shore-side escape and check sea conditions locally.", coordinate: .init(latitude: 6.0097, longitude: 80.2497), minutes: 120, budget: .easy, image: "unawatuna", tags: ["Beach", "Local food", "Coastal walk"], experienceTags: [.seaside, .wander]),
        .init(id: "galle", name: "Galle Fort", district: "Galle", locality: "Galle", category: .culture, moods: [.chill, .romantic, .food], summary: "Explore lanes, old buildings and ocean-facing ramparts in Galle’s historic fort. Pause for a café stop and enjoy the sea breeze, taking care on exposed rampart edges.", coordinate: .init(latitude: 6.0269, longitude: 80.2170), minutes: 180, budget: .easy, image: "galle", tags: ["Heritage", "Ocean views", "Café stops"], experienceTags: [.wander, .food]),
        .init(id: "kandy", name: "Kandy Lake", district: "Kandy", locality: "Kandy", category: .nature, moods: [.chill, .romantic], summary: "Slow down beside the lake at the heart of Kandy. Follow the public lakeside paths, watch the reflections and enjoy a gentle break from the busy streets.", coordinate: .init(latitude: 7.2906, longitude: 80.6413), minutes: 60, budget: .pocket, image: "kandy", tags: ["Lakeside", "Easy walk", "City escape"], experienceTags: [.greenery, .wander]),
        .init(id: "horton", name: "Horton Plains", district: "Nuwara Eliya", locality: "Ohiya", category: .hiking, moods: [.adventure], summary: "An open highland landscape of grassland and cloud forest. Plan a proper trail day, carry layers for changing weather and stay on marked paths, especially near exposed viewpoints.", coordinate: .init(latitude: 6.8028, longitude: 80.8070), minutes: 300, budget: .flexible, image: "horton", tags: ["Highlands", "Hiking", "Cloud forest"], experienceTags: [.greenery, .active]),
        .init(id: "adamspeak", name: "Little Adam’s Peak", district: "Badulla", locality: "Ella", category: .hiking, moods: [.adventure, .romantic], summary: "A popular walk above Ella with views across tea-covered hills. The steps and exposed ridge call for good footwear, water and care in hot or wet weather.", coordinate: .init(latitude: 6.8652, longitude: 81.0624), minutes: 150, budget: .pocket, image: "adamspeak", tags: ["Mountain views", "Hiking", "Tea country"], experienceTags: [.active, .greenery]),
        .init(id: "colombo", name: "Galle Face Green", district: "Colombo", locality: "Colombo", category: .nature, moods: [.chill, .romantic, .food], summary: "A breezy oceanfront promenade in Colombo. Walk beside the sea, watch the kites and explore the food stalls when they are open. Food purchases are optional and prices vary.", coordinate: .init(latitude: 6.9245, longitude: 79.8436), minutes: 60, budget: .pocket, image: "colombo", tags: ["Ocean breeze", "Street snacks", "City walk"], experienceTags: [.seaside, .wander, .food]),
        .init(id: "pettah", name: "Pettah Market Walk", district: "Colombo", locality: "Colombo", category: .food, moods: [.food, .adventure], summary: "Explore Colombo’s energetic market streets and discover fruit stalls, small eateries and everyday city life. Bring water, keep to public streets and ask vendors about ingredients and current prices.", coordinate: .init(latitude: 6.9382, longitude: 79.8516), minutes: 120, budget: .easy, image: "pettah", tags: ["Local flavours", "Market", "City life"], experienceTags: [.food, .wander]),
        .init(id: "peradeniya", name: "Peradeniya Gardens", district: "Kandy", locality: "Peradeniya", category: .nature, moods: [.chill, .romantic], summary: "Wander the tree-lined avenues and lawns of the Royal Botanic Gardens near Kandy. Leave time to explore at your own pace and check current admission details before travelling.", coordinate: .init(latitude: 7.2710, longitude: 80.5958), minutes: 180, budget: .flexible, image: "peradeniya", tags: ["Botanical garden", "Nature", "Easy walks"], experienceTags: [.greenery, .wander]),
        .init(id: "gangaramaya", name: "Gangaramaya Temple", district: "Colombo", locality: "Colombo", category: .culture, moods: [.chill, .adventure], summary: "A Buddhist temple complex in Colombo with shrines and distinctive architecture. Plan a respectful visit, dress appropriately and follow posted guidance. Check current access and admission details with the temple before setting out.", coordinate: .init(latitude: 6.91638889, longitude: 79.85638889), minutes: 60, budget: .easy, image: "gangaramaya", tags: ["Temple", "Culture", "Reflective visit"], website: URL(string: "https://gangaramaya.com/"), experienceTags: [.temple]),
        .init(id: "dalada", name: "Temple of the Sacred Tooth Relic", district: "Kandy", locality: "Kandy", category: .culture, moods: [.chill, .adventure], summary: "Sri Dalada Maligawa is a Buddhist place of worship beside the historic royal palace complex in Kandy. Leave time for a respectful visit, follow the dress code and confirm current access, ceremonies and admission arrangements with the temple.", coordinate: .init(latitude: 7.2936, longitude: 80.6414), minutes: 60, budget: .easy, image: "dalada", tags: ["Temple", "Heritage", "Reflective visit"], website: URL(string: "https://sridaladamaligawa.lk/"), experienceTags: [.temple])
    ]
    static func find(_ id: String) -> Destination? { all.first { $0.id == id } }
}

struct AdventureConstraints {
    var moods: Set<Mood> = [.chill]
    var budget: BudgetTier = .easy
    var duration: AdventureDuration = .unhurried
    var origin: Coordinate?
    var radiusKilometers: Double = 120
    var personalization: PersonalizationContext = .none
}

enum DestinationMatcher {
    static func eligible(in destinations: [Destination], for criteria: AdventureConstraints) -> [Destination] {
        criteria.personalization.ranked(destinations.filter { place in
            (criteria.moods.isEmpty || !place.moods.isDisjoint(with: criteria.moods)) &&
            place.budget.rawValue <= criteria.budget.rawValue && place.minutes <= criteria.duration.rawValue &&
            (criteria.origin.map { origin in place.coordinate.map { origin.kilometers(to: $0) <= criteria.radiusKilometers } ?? false } ?? true)
        })
    }
    static func select<R: RandomNumberGenerator>(from candidates: [Destination], recentIDs: [String], personalization: PersonalizationContext = .none, using generator: inout R) -> Destination? {
        let candidates = candidates.filter(personalization.accepts)
        let fresh = candidates.filter { !recentIDs.contains($0.id) }
        let pool = fresh.isEmpty ? candidates.filter { $0.id != recentIDs.last } : fresh
        let available = pool.isEmpty ? candidates : pool
        let bestScore = available.map(personalization.score).max() ?? 0
        return available.filter { personalization.score($0) == bestScore }.randomElement(using: &generator)
    }
    static func search(_ places: [Destination], text: String, category: PlaceCategory? = nil) -> [Destination] {
        let query = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return places.filter { place in
            (category == nil || place.category == category) && (query.isEmpty ||
                ([place.name, place.district, place.locality, place.category.rawValue] + place.tags)
                    .contains { $0.localizedCaseInsensitiveContains(query) })
        }
    }
}
