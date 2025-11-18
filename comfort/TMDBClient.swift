//
//  TMDBClient.swift (or Untitled 2.swift)
//  first demo
//
//  Created by Kuro Gboun on 2025-10-25.
//
import Foundation

//  add 'media_type' to track what kind of item it is
struct Movie: Decodable, Identifiable, Hashable {
    let id: Int
    let media_type: String?
    let title: String?
    let release_date: String?
    var year: String? {
            guard let date = release_date, date.count >= 4 else { return nil }
            // "2025-10-29" -> "2025"
            return String(date.prefix(4))
        }
    let poster_path: String?
    let backdrop_path: String?
    var backdropURL: URL? {
        guard let path = backdrop_path else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w1280\(path)")
    }
    var posterURL: URL? {
        guard let path = poster_path else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w500\(path)")
    }
    let vote_average: Double?
    let vote_count: Int?
    let popularity: Double?
    let overview: String?
}

struct MovieResponse: Decodable {
    let results: [Movie]
}
struct VideoResponse: Decodable {
    let id: Int
    let results: [Video]
}

struct Video: Decodable, Identifiable {
    let id: String
    let key: String
    let site: String
    let type: String
    let name: String
}
// This "unifies" movies, TV, and people into one object
struct SearchResult: Identifiable, Decodable, Hashable {
    
    let id: Int
    let media_type: String? // "movie", "tv", or "person"
    
    // Unified properties
    let title: String? // Will hold 'title' OR 'name'
    let overview: String?
    let poster_path: String? // Will hold 'poster_path' OR 'profile_path'
    let backdrop_path: String?
    
    // Movie-specific properties (needed for detail view)
    let release_date: String?
    var year: String? {
            guard let date = release_date, date.count >= 4 else { return nil }
            // "2025-10-29" -> "2025"
            return String(date.prefix(4))
        }
    let vote_average: Double?
    let vote_count: Int?
    let popularity: Double?

    // Custom logic to map different JSON keys
    enum CodingKeys: String, CodingKey {
        case id, media_type, overview, popularity
        case title = "title" // Movie title
        case name = "name" // TV/Person name
        case poster_path = "poster_path"
        case backdrop_path = "backdrop_path"
        case profile_path = "profile_path" // Person poster
        case release_date, vote_average, vote_count
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        media_type = try container.decodeIfPresent(String.self, forKey: .media_type)
        overview = try container.decodeIfPresent(String.self, forKey: .overview)
        popularity = try container.decodeIfPresent(Double.self, forKey: .popularity)
        
        // 1. Title
        if let title = try? container.decodeIfPresent(String.self, forKey: .title) {
            self.title = title
        } else {
            self.title = try container.decodeIfPresent(String.self, forKey: .name)
        }
        backdrop_path = try container.decodeIfPresent(String.self, forKey: .backdrop_path)

        // 2. Poster
        if let poster = try? container.decodeIfPresent(String.self, forKey: .poster_path) {
            self.poster_path = poster
        } else {
            self.poster_path = try container.decodeIfPresent(String.self, forKey: .profile_path)
        }
        
        // 3. Movie-only data
        release_date = try container.decodeIfPresent(String.self, forKey: .release_date)
        vote_average = try container.decodeIfPresent(Double.self, forKey: .vote_average)
        vote_count = try container.decodeIfPresent(Int.self, forKey: .vote_count)

    }
    
    // for your 'MovieDetailView'
    func asMovie() -> Movie {
        return Movie(
            id: self.id,
            media_type: self.media_type,
            title: self.title,
            release_date: self.release_date,
            poster_path: self.poster_path,
            backdrop_path: self.backdrop_path,
            vote_average: self.vote_average,
            vote_count: self.vote_count,
            popularity: self.popularity,
            overview: self.overview

        )
    }
}

struct MultiSearchResponse: Decodable {
    let results: [SearchResult]
}



enum TMDBClient {
    static let apiKey = "8c8ffd8b4da204638ca40808d7211069"
    static let base = URL(string: "https://api.themoviedb.org/3")!
    private static let baseURL = "https://api.themoviedb.org/3"

    static func searchMulti(query: String, page: Int = 1) async throws -> [SearchResult] {
        guard !query.isEmpty else { return [] }
        
        var comps = URLComponents(url: base.appendingPathComponent("search/multi"), resolvingAgainstBaseURL: false)!
        
        comps.queryItems = [
            .init(name: "api_key", value: apiKey),
            .init(name: "query", value: query),
            .init(name: "language", value: "en-US"),
            .init(name: "include_adult", value: "false"),
            .init(name: "page", value: "\(page)") // <--- ADDED
        ]
        
        let (data, _) = try await URLSession.shared.data(from: comps.url!)
        
        let response = try JSONDecoder().decode(MultiSearchResponse.self, from: data)
        
        return response.results.filter { $0.poster_path != nil }
    }
    // This function is no longer used by search, but is here if you need it
    static func popularMovies() async throws -> [Movie] {
        var comps = URLComponents(url: base.appendingPathComponent("movie/popular"), resolvingAgainstBaseURL: false)!
        comps.queryItems = [
            .init(name: "api_key", value: apiKey),
            .init(name: "language", value: "en-US"),
            .init(name: "page", value: "1")
        ]
        let (data, _) = try await URLSession.shared.data(from: comps.url!)
        return try JSONDecoder().decode(MovieResponse.self, from: data).results
    }
    
    static func getSimilarMovies(movieID: Int, page: Int) async throws -> [Movie] {
        let urlString = "\(baseURL)/movie/\(movieID)/similar?api_key=\(apiKey)&language=en-US&page=\(page)"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(MovieResponse.self, from: data)
        return response.results
    }
        
    // Image URL helper
    static func imageURL(path: String?) -> URL? {
        guard let path = path else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w500\(path)")
    }
    
    static func backdropURL(path: String?) -> URL? {
        guard let path = path else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w1280\(path)")
    }
    
    static func getDetails(id: Int, mediaType: String) async throws -> Movie {
            
        let urlString = "\(baseURL)/\(mediaType)/\(id)?api_key=\(apiKey)&language=en-US"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
   
        let result = try JSONDecoder().decode(SearchResult.self, from: data)
        
        return result.asMovie()
    }
    static func getMovieTrailerURL(movieID: Int) async throws -> URL? {
            let urlString = "\(baseURL)/movie/\(movieID)/videos?api_key=\(apiKey)&language=en-US"
            guard let url = URL(string: urlString) else {
                throw URLError(.badURL)
            }
            
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(VideoResponse.self, from: data)
            let videos = response.results
            
            // Find the best trailer:
            // 1. "Official Trailer" on "YouTube"
            // 2. Any "Trailer" on "YouTube"
            // 3. Any "Teaser" on "YouTube"
            let trailer = videos.first(where: { $0.site == "YouTube" && $0.type == "Trailer" && $0.name.contains("Official") })
                ?? videos.first(where: { $0.site == "YouTube" && $0.type == "Trailer" })
                ?? videos.first(where: { $0.site == "YouTube" && $0.type == "Teaser" })
            
            // Get the key from the trailer, or return nil
            guard let trailerKey = trailer?.key else {
                return nil
            }
            
            // Build the special auto-play embed URL.
            // autoplay=1 (plays automatically)
            // playsinline=1 (plays inside the view, not fullscreen)
            // mute=1 (REQUIRED by browsers for autoplay)
            return URL(string: "https://www.youtube.com/embed/\(trailerKey)?autoplay=1&playsinline=1&mute=1")
        }
}
