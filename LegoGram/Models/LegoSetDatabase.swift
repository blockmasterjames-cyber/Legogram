import Foundation

/// A local database of 60 popular LEGO sets used for:
/// • Auto-complete while typing a set number in the New Post screen
/// • Powering the Search screen results
/// Data covers 10 major LEGO themes as required by Sprint 3.
struct LegoSetDatabase {

    // MARK: - All 60 Sets (10 themes × 6 sets each)

    static let allSets: [LegoSet] =
        starWars + technic + city + creator + ideas +
        icons + harryPotter + marvel + speedChampions + architecture

    // MARK: - Star Wars (6 sets)

    static let starWars: [LegoSet] = [
        LegoSet(id: "75192", setNumber: "75192", name: "Millennium Falcon",
                theme: "Star Wars", pieceCount: 7541, retailPrice: 849.99,
                buyLink: "https://www.lego.com/en-us/product/millennium-falcon-75192",
                imageURL: "", releaseYear: 2017),
        LegoSet(id: "75313", setNumber: "75313", name: "AT-AT",
                theme: "Star Wars", pieceCount: 6785, retailPrice: 849.99,
                buyLink: "https://www.lego.com/en-us/product/at-at-75313",
                imageURL: "", releaseYear: 2021),
        LegoSet(id: "75252", setNumber: "75252", name: "Imperial Star Destroyer",
                theme: "Star Wars", pieceCount: 4784, retailPrice: 699.99,
                buyLink: "https://www.lego.com/en-us/product/imperial-star-destroyer-75252",
                imageURL: "", releaseYear: 2019),
        LegoSet(id: "75309", setNumber: "75309", name: "Republic Gunship",
                theme: "Star Wars", pieceCount: 3292, retailPrice: 349.99,
                buyLink: "https://www.lego.com/en-us/product/republic-gunship-75309",
                imageURL: "", releaseYear: 2021),
        LegoSet(id: "75290", setNumber: "75290", name: "Mos Eisley Cantina",
                theme: "Star Wars", pieceCount: 3187, retailPrice: 349.99,
                buyLink: "https://www.lego.com/en-us/product/mos-eisley-cantina-75290",
                imageURL: "", releaseYear: 2020),
        LegoSet(id: "75341", setNumber: "75341", name: "Luke Skywalker's Landspeeder",
                theme: "Star Wars", pieceCount: 1890, retailPrice: 199.99,
                buyLink: "https://www.lego.com/en-us/product/luke-skywalker-s-landspeeder-75341",
                imageURL: "", releaseYear: 2022),
    ]

    // MARK: - Technic (6 sets)

    static let technic: [LegoSet] = [
        LegoSet(id: "42115", setNumber: "42115", name: "Lamborghini Sián FKP 37",
                theme: "Technic", pieceCount: 3696, retailPrice: 379.99,
                buyLink: "https://www.lego.com/en-us/product/lamborghini-sian-fkp-37-42115",
                imageURL: "", releaseYear: 2020),
        LegoSet(id: "42083", setNumber: "42083", name: "Bugatti Chiron",
                theme: "Technic", pieceCount: 3599, retailPrice: 349.99,
                buyLink: "https://www.lego.com/en-us/product/bugatti-chiron-42083",
                imageURL: "", releaseYear: 2018),
        LegoSet(id: "42110", setNumber: "42110", name: "Land Rover Defender",
                theme: "Technic", pieceCount: 2573, retailPrice: 199.99,
                buyLink: "https://www.lego.com/en-us/product/land-rover-defender-42110",
                imageURL: "", releaseYear: 2019),
        LegoSet(id: "42151", setNumber: "42151", name: "Bugatti Bolide",
                theme: "Technic", pieceCount: 905, retailPrice: 69.99,
                buyLink: "https://www.lego.com/en-us/product/bugatti-bolide-42151",
                imageURL: "", releaseYear: 2023),
        LegoSet(id: "42154", setNumber: "42154", name: "Ford GT 2022",
                theme: "Technic", pieceCount: 1466, retailPrice: 129.99,
                buyLink: "https://www.lego.com/en-us/product/ford-gt-2022-42154",
                imageURL: "", releaseYear: 2023),
        LegoSet(id: "42096", setNumber: "42096", name: "Porsche 911 RSR",
                theme: "Technic", pieceCount: 1580, retailPrice: 149.99,
                buyLink: "https://www.lego.com/en-us/product/porsche-911-rsr-42096",
                imageURL: "", releaseYear: 2018),
    ]

    // MARK: - City (6 sets)

    static let city: [LegoSet] = [
        LegoSet(id: "60380", setNumber: "60380", name: "Downtown",
                theme: "City", pieceCount: 2010, retailPrice: 199.99,
                buyLink: "https://www.lego.com/en-us/product/downtown-60380",
                imageURL: "", releaseYear: 2023),
        LegoSet(id: "60350", setNumber: "60350", name: "Arctic Explorer Base Camp",
                theme: "City", pieceCount: 507, retailPrice: 59.99,
                buyLink: "https://www.lego.com/en-us/product/arctic-explorer-base-camp-60350",
                imageURL: "", releaseYear: 2022),
        LegoSet(id: "60228", setNumber: "60228", name: "Deep Space Rocket and Launch Control",
                theme: "City", pieceCount: 837, retailPrice: 99.99,
                buyLink: "https://www.lego.com/en-us/product/deep-space-rocket-and-launch-control-60228",
                imageURL: "", releaseYear: 2019),
        LegoSet(id: "60197", setNumber: "60197", name: "Passenger Train",
                theme: "City", pieceCount: 677, retailPrice: 119.99,
                buyLink: "https://www.lego.com/en-us/product/passenger-train-60197",
                imageURL: "", releaseYear: 2018),
        LegoSet(id: "60316", setNumber: "60316", name: "Police Station",
                theme: "City", pieceCount: 668, retailPrice: 79.99,
                buyLink: "https://www.lego.com/en-us/product/police-station-60316",
                imageURL: "", releaseYear: 2022),
        LegoSet(id: "60293", setNumber: "60293", name: "City Fun Park",
                theme: "City", pieceCount: 269, retailPrice: 39.99,
                buyLink: "https://www.lego.com/en-us/product/city-fun-park-60293",
                imageURL: "", releaseYear: 2021),
    ]

    // MARK: - Creator 3-in-1 (6 sets)

    static let creator: [LegoSet] = [
        LegoSet(id: "31120", setNumber: "31120", name: "Medieval Castle",
                theme: "Creator 3-in-1", pieceCount: 1426, retailPrice: 99.99,
                buyLink: "https://www.lego.com/en-us/product/medieval-castle-31120",
                imageURL: "", releaseYear: 2021),
        LegoSet(id: "31119", setNumber: "31119", name: "Ferris Wheel",
                theme: "Creator 3-in-1", pieceCount: 1002, retailPrice: 89.99,
                buyLink: "https://www.lego.com/en-us/product/ferris-wheel-31119",
                imageURL: "", releaseYear: 2021),
        LegoSet(id: "31109", setNumber: "31109", name: "Pirate Ship",
                theme: "Creator 3-in-1", pieceCount: 1260, retailPrice: 99.99,
                buyLink: "https://www.lego.com/en-us/product/pirate-ship-31109",
                imageURL: "", releaseYear: 2020),
        LegoSet(id: "31140", setNumber: "31140", name: "Magical Unicorn",
                theme: "Creator 3-in-1", pieceCount: 145, retailPrice: 14.99,
                buyLink: "https://www.lego.com/en-us/product/magical-unicorn-31140",
                imageURL: "", releaseYear: 2023),
        LegoSet(id: "31127", setNumber: "31127", name: "Street Racer",
                theme: "Creator 3-in-1", pieceCount: 258, retailPrice: 19.99,
                buyLink: "https://www.lego.com/en-us/product/street-racer-31127",
                imageURL: "", releaseYear: 2022),
        LegoSet(id: "31128", setNumber: "31128", name: "Dolphin and Turtle",
                theme: "Creator 3-in-1", pieceCount: 137, retailPrice: 14.99,
                buyLink: "https://www.lego.com/en-us/product/dolphin-and-turtle-31128",
                imageURL: "", releaseYear: 2022),
    ]

    // MARK: - Ideas (6 sets)

    static let ideas: [LegoSet] = [
        LegoSet(id: "21325", setNumber: "21325", name: "Medieval Blacksmith",
                theme: "Ideas", pieceCount: 2164, retailPrice: 179.99,
                buyLink: "https://www.lego.com/en-us/product/medieval-blacksmith-21325",
                imageURL: "", releaseYear: 2021),
        LegoSet(id: "21335", setNumber: "21335", name: "Motorized Lighthouse",
                theme: "Ideas", pieceCount: 2065, retailPrice: 199.99,
                buyLink: "https://www.lego.com/en-us/product/motorized-lighthouse-21335",
                imageURL: "", releaseYear: 2022),
        LegoSet(id: "21333", setNumber: "21333", name: "Vincent van Gogh - The Starry Night",
                theme: "Ideas", pieceCount: 2316, retailPrice: 169.99,
                buyLink: "https://www.lego.com/en-us/product/vincent-van-gogh-the-starry-night-21333",
                imageURL: "", releaseYear: 2022),
        LegoSet(id: "21326", setNumber: "21326", name: "Winnie the Pooh",
                theme: "Ideas", pieceCount: 1265, retailPrice: 99.99,
                buyLink: "https://www.lego.com/en-us/product/winnie-the-pooh-21326",
                imageURL: "", releaseYear: 2021),
        LegoSet(id: "21330", setNumber: "21330", name: "Home Alone",
                theme: "Ideas", pieceCount: 3955, retailPrice: 249.99,
                buyLink: "https://www.lego.com/en-us/product/home-alone-21330",
                imageURL: "", releaseYear: 2021),
        LegoSet(id: "21334", setNumber: "21334", name: "Jazz Quartet",
                theme: "Ideas", pieceCount: 1671, retailPrice: 179.99,
                buyLink: "https://www.lego.com/en-us/product/jazz-quartet-21334",
                imageURL: "", releaseYear: 2022),
    ]

    // MARK: - Icons (6 sets)

    static let icons: [LegoSet] = [
        LegoSet(id: "10317", setNumber: "10317", name: "Classic Land Rover Defender 90",
                theme: "Icons", pieceCount: 2336, retailPrice: 199.99,
                buyLink: "https://www.lego.com/en-us/product/classic-land-rover-defender-90-10317",
                imageURL: "", releaseYear: 2023),
        LegoSet(id: "10300", setNumber: "10300", name: "Back to the Future Time Machine",
                theme: "Icons", pieceCount: 1872, retailPrice: 169.99,
                buyLink: "https://www.lego.com/en-us/product/back-to-the-future-time-machine-10300",
                imageURL: "", releaseYear: 2022),
        LegoSet(id: "10281", setNumber: "10281", name: "Bonsai Tree",
                theme: "Icons", pieceCount: 878, retailPrice: 49.99,
                buyLink: "https://www.lego.com/en-us/product/bonsai-tree-10281",
                imageURL: "", releaseYear: 2021),
        LegoSet(id: "10280", setNumber: "10280", name: "Flower Bouquet",
                theme: "Icons", pieceCount: 756, retailPrice: 49.99,
                buyLink: "https://www.lego.com/en-us/product/flower-bouquet-10280",
                imageURL: "", releaseYear: 2021),
        LegoSet(id: "10307", setNumber: "10307", name: "Eiffel Tower",
                theme: "Icons", pieceCount: 10001, retailPrice: 629.99,
                buyLink: "https://www.lego.com/en-us/product/eiffel-tower-10307",
                imageURL: "", releaseYear: 2022),
        LegoSet(id: "10295", setNumber: "10295", name: "Porsche 911",
                theme: "Icons", pieceCount: 1458, retailPrice: 149.99,
                buyLink: "https://www.lego.com/en-us/product/porsche-911-10295",
                imageURL: "", releaseYear: 2021),
    ]

    // MARK: - Harry Potter (6 sets)

    static let harryPotter: [LegoSet] = [
        LegoSet(id: "76419", setNumber: "76419", name: "Hogwarts Castle and Grounds",
                theme: "Harry Potter", pieceCount: 2660, retailPrice: 229.99,
                buyLink: "https://www.lego.com/en-us/product/hogwarts-castle-and-grounds-76419",
                imageURL: "", releaseYear: 2023),
        LegoSet(id: "71043", setNumber: "71043", name: "Hogwarts Castle",
                theme: "Harry Potter", pieceCount: 6020, retailPrice: 469.99,
                buyLink: "https://www.lego.com/en-us/product/hogwarts-castle-71043",
                imageURL: "", releaseYear: 2018),
        LegoSet(id: "75969", setNumber: "75969", name: "Hogwarts Astronomy Tower",
                theme: "Harry Potter", pieceCount: 971, retailPrice: 99.99,
                buyLink: "https://www.lego.com/en-us/product/hogwarts-astronomy-tower-75969",
                imageURL: "", releaseYear: 2020),
        LegoSet(id: "76405", setNumber: "76405", name: "Hogwarts Express Collectors' Edition",
                theme: "Harry Potter", pieceCount: 5129, retailPrice: 499.99,
                buyLink: "https://www.lego.com/en-us/product/hogwarts-express-collectors-edition-76405",
                imageURL: "", releaseYear: 2022),
        LegoSet(id: "76388", setNumber: "76388", name: "Hogsmeade Village Visit",
                theme: "Harry Potter", pieceCount: 851, retailPrice: 89.99,
                buyLink: "https://www.lego.com/en-us/product/hogsmeade-village-visit-76388",
                imageURL: "", releaseYear: 2021),
        LegoSet(id: "76391", setNumber: "76391", name: "Hogwarts Icons Collectors' Edition",
                theme: "Harry Potter", pieceCount: 3010, retailPrice: 249.99,
                buyLink: "https://www.lego.com/en-us/product/hogwarts-icons-collectors-edition-76391",
                imageURL: "", releaseYear: 2021),
    ]

    // MARK: - Marvel (6 sets)

    static let marvel: [LegoSet] = [
        LegoSet(id: "76261", setNumber: "76261", name: "Spider-Man Final Battle",
                theme: "Marvel", pieceCount: 900, retailPrice: 99.99,
                buyLink: "https://www.lego.com/en-us/product/spider-man-final-battle-76261",
                imageURL: "", releaseYear: 2023),
        LegoSet(id: "76210", setNumber: "76210", name: "Hulkbuster",
                theme: "Marvel", pieceCount: 4049, retailPrice: 549.99,
                buyLink: "https://www.lego.com/en-us/product/hulkbuster-76210",
                imageURL: "", releaseYear: 2022),
        LegoSet(id: "76243", setNumber: "76243", name: "Rocket Mech Armor",
                theme: "Marvel", pieceCount: 98, retailPrice: 9.99,
                buyLink: "https://www.lego.com/en-us/product/rocket-mech-armor-76243",
                imageURL: "", releaseYear: 2023),
        LegoSet(id: "76218", setNumber: "76218", name: "Sanctum Sanctorum",
                theme: "Marvel", pieceCount: 2708, retailPrice: 269.99,
                buyLink: "https://www.lego.com/en-us/product/sanctum-sanctorum-76218",
                imageURL: "", releaseYear: 2022),
        LegoSet(id: "76215", setNumber: "76215", name: "Black Panther",
                theme: "Marvel", pieceCount: 2961, retailPrice: 349.99,
                buyLink: "https://www.lego.com/en-us/product/black-panther-76215",
                imageURL: "", releaseYear: 2022),
        LegoSet(id: "76223", setNumber: "76223", name: "Nano Gauntlet",
                theme: "Marvel", pieceCount: 590, retailPrice: 69.99,
                buyLink: "https://www.lego.com/en-us/product/nano-gauntlet-76223",
                imageURL: "", releaseYear: 2022),
    ]

    // MARK: - Speed Champions (6 sets)

    static let speedChampions: [LegoSet] = [
        LegoSet(id: "76916", setNumber: "76916", name: "Porsche 963",
                theme: "Speed Champions", pieceCount: 280, retailPrice: 24.99,
                buyLink: "https://www.lego.com/en-us/product/porsche-963-76916",
                imageURL: "", releaseYear: 2023),
        LegoSet(id: "76914", setNumber: "76914", name: "Ferrari 812 Competizione",
                theme: "Speed Champions", pieceCount: 261, retailPrice: 24.99,
                buyLink: "https://www.lego.com/en-us/product/ferrari-812-competizione-76914",
                imageURL: "", releaseYear: 2023),
        LegoSet(id: "76906", setNumber: "76906", name: "1970 Ferrari 512 M",
                theme: "Speed Champions", pieceCount: 291, retailPrice: 24.99,
                buyLink: "https://www.lego.com/en-us/product/1970-ferrari-512-m-76906",
                imageURL: "", releaseYear: 2022),
        LegoSet(id: "76920", setNumber: "76920", name: "Fast & Furious 1970 Dodge Charger",
                theme: "Speed Champions", pieceCount: 345, retailPrice: 29.99,
                buyLink: "https://www.lego.com/en-us/product/fast-furious-1970-dodge-charger-76920",
                imageURL: "", releaseYear: 2023),
        LegoSet(id: "76917", setNumber: "76917", name: "Nissan Skyline GT-R (R34)",
                theme: "Speed Champions", pieceCount: 319, retailPrice: 29.99,
                buyLink: "https://www.lego.com/en-us/product/nissan-skyline-gt-r-r34-76917",
                imageURL: "", releaseYear: 2023),
        LegoSet(id: "76911", setNumber: "76911", name: "007 Aston Martin DB5",
                theme: "Speed Champions", pieceCount: 298, retailPrice: 24.99,
                buyLink: "https://www.lego.com/en-us/product/007-aston-martin-db5-76911",
                imageURL: "", releaseYear: 2022),
    ]

    // MARK: - Architecture (6 sets)

    static let architecture: [LegoSet] = [
        LegoSet(id: "21044", setNumber: "21044", name: "Paris",
                theme: "Architecture", pieceCount: 649, retailPrice: 59.99,
                buyLink: "https://www.lego.com/en-us/product/paris-21044",
                imageURL: "", releaseYear: 2019),
        LegoSet(id: "21056", setNumber: "21056", name: "Taj Mahal",
                theme: "Architecture", pieceCount: 2022, retailPrice: 119.99,
                buyLink: "https://www.lego.com/en-us/product/taj-mahal-21056",
                imageURL: "", releaseYear: 2021),
        LegoSet(id: "21057", setNumber: "21057", name: "Singapore",
                theme: "Architecture", pieceCount: 827, retailPrice: 69.99,
                buyLink: "https://www.lego.com/en-us/product/singapore-21057",
                imageURL: "", releaseYear: 2022),
        LegoSet(id: "21058", setNumber: "21058", name: "Great Pyramid of Giza",
                theme: "Architecture", pieceCount: 1476, retailPrice: 119.99,
                buyLink: "https://www.lego.com/en-us/product/great-pyramid-of-giza-21058",
                imageURL: "", releaseYear: 2022),
        LegoSet(id: "21060", setNumber: "21060", name: "Himeji Castle",
                theme: "Architecture", pieceCount: 2125, retailPrice: 119.99,
                buyLink: "https://www.lego.com/en-us/product/himeji-castle-21060",
                imageURL: "", releaseYear: 2023),
        LegoSet(id: "21043", setNumber: "21043", name: "San Francisco",
                theme: "Architecture", pieceCount: 565, retailPrice: 59.99,
                buyLink: "https://www.lego.com/en-us/product/san-francisco-21043",
                imageURL: "", releaseYear: 2019),
    ]

    // MARK: - Search & Lookup

    /// Returns sets whose number starts with OR whose name/theme contains the query.
    /// Works for both set number searches and name searches.
    static func search(_ query: String) -> [LegoSet] {
        let q = query.lowercased().trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return [] }
        return allSets.filter {
            $0.setNumber.hasPrefix(q) ||
            $0.name.lowercased().contains(q) ||
            $0.theme.lowercased().contains(q)
        }
    }

    /// Returns up to 5 auto-complete suggestions based on the typed set number prefix.
    static func autocomplete(setNumber: String) -> [LegoSet] {
        let q = setNumber.trimmingCharacters(in: .whitespaces)
        guard q.count >= 2 else { return [] }
        return Array(allSets.filter { $0.setNumber.hasPrefix(q) }.prefix(5))
    }

    /// Returns the single set matching the exact set number, or nil.
    static func set(for number: String) -> LegoSet? {
        allSets.first { $0.setNumber == number }
    }
}

// MARK: - LegoSet Convenience

extension LegoSet {
    /// The official LEGO store URL for this set.
    /// Aliases buyLink so all Sprint 3 code can use the descriptive field name.
    var legoStoreURL: String { buyLink }
}
