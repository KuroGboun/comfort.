//
//  GeminiClient.swift
//  first demo
//
//  Created by Kuro Gboun on 2025-10-28.
//
import SwiftUI
import Foundation

struct GeminiResponse: Decodable {
    let candidates: [Candidate]
}

struct Candidate: Decodable {
    let content: Content
}

struct Content: Decodable {
    let parts: [Part]
}

struct Part: Decodable {
    let text: String
}

// This is the struct we send TO the API
struct GeminiRequest: Encodable {
    let contents: [ContentRequest]
}

struct ContentRequest: Encodable {
    let parts: [PartRequest]
}

struct PartRequest: Encodable {
    let text: String
}

enum GeminiClient {
    private static let apiKey = "AIzaSyBVltent2Muwf8UTpF21qsZDPWAIfITDNE"
    private static let urlString = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=\(apiKey)"
    // In your GeminiClient.swift file, inside the enum...
    
    static func performAISearch(for query: String, bookmarkTitles: [String]) async throws -> [SearchResult] {
        if query.isEmpty {
            return [] // Just return an empty array
        }
        
        do {
            let movieTitles = try await GeminiClient.getRecommendations(
                for: query,
                bookmarkTitles: bookmarkTitles
            )
            try Task.checkCancellation()
            
            let searchResults = try await withThrowingTaskGroup(of: (Int, SearchResult)?.self) { group in
                var indexedResults: [(Int, SearchResult)] = []
                
                for (index, title) in movieTitles.enumerated() {
                    group.addTask {
                        let results = try? await TMDBClient.searchMulti(query: title)
                        if let firstResult = results?.first {
                            return (index, firstResult)
                        }
                        return nil
                    }
                }
                
                for try await result in group {
                    if let result = result {
                        indexedResults.append(result)
                    }
                }
                
                indexedResults.sort { $0.0 < $1.0 }
                return indexedResults.map { $0.1 }
            }
            
            try Task.checkCancellation()
            
            // 6. Deduplicate the list
            var uniqueResults: [SearchResult] = []
            var seenIDs = Set<Int>()
            for result in searchResults {
                if !seenIDs.contains(result.id) {
                    uniqueResults.append(result)
                    seenIDs.insert(result.id)
                }
            }
            
            return uniqueResults
            
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw error
        }
    }
    static func performSearch(for query: String, bookmarkTitles: [String]) async throws -> [SearchResult] {
        if query.isEmpty {
            return [] // Just return an empty array
        }
        
        do {
            let movieTitles = try await GeminiClient.getSearchSuggestions(
                for: query,
                bookmarkTitles: bookmarkTitles
            )
            try Task.checkCancellation()
            
            let searchResults = try await withThrowingTaskGroup(of: (Int, SearchResult)?.self) { group in
                var indexedResults: [(Int, SearchResult)] = []
                
                for (index, title) in movieTitles.enumerated() {
                    group.addTask {
                        let results = try? await TMDBClient.searchMulti(query: title)
                        if let firstResult = results?.first {
                            return (index, firstResult)
                        }
                        return nil
                    }
                }
                
                for try await result in group {
                    if let result = result {
                        indexedResults.append(result)
                    }
                }
                
                indexedResults.sort { $0.0 < $1.0 }
                return indexedResults.map { $0.1 }
            }
            
            try Task.checkCancellation()
            
            // 6. Deduplicate the list
            var uniqueResults: [SearchResult] = []
            var seenIDs = Set<Int>()
            for result in searchResults {
                if !seenIDs.contains(result.id) {
                    uniqueResults.append(result)
                    seenIDs.insert(result.id)
                }
            }
            
            return uniqueResults
            
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw error
        }
    }
    
    static func getRecommendations(for query: String, bookmarkTitles: [String]) async throws -> [String] {
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let context: String
        if bookmarkTitles.isEmpty {
            context = "The user has not added any comfort movies yet."
        } else {
            context = "The user's comfort movies are: \(bookmarkTitles.joined(separator: ", "))."
        }
        // "magic"
        let prompt = """
            Act like “Cortex,” an expert English-language movie and TV recommendation engine modeled on Google’s “What to Watch” and Netflix-style personalization.
        
            Objective:
            Analyze the user’s query and the Comfort Movies context to generate a curated, hyper-relevant set of recommendations.
        
            Task:
            Return ONLY a comma-separated list of exactly 70 distinct English titles (movies and/or TV). No numbers, no explanations, no newlines, no quotes, no bullet points.
        
            Inputs:
            Context = \(context)
            Query = \(query)
        
            Process (follow in order):
            1) Classify the query type: Specific Title, Genre/Mood/Trope, or Actor/Director.
            2) Extract constraints implied by the query (format if stated, tone, era, rating, intensity, family-friendliness).
            3) Build a preference vector from the Comfort Movies: themes, tone, pacing, genres, key cast/creators, studios, and “vibe.” Use this as critical context; do not include Comfort titles unless they genuinely fit the query.
            4) Candidate generation:
               - If Specific Title: begin the list with the direct match and its immediate sequels/spin-offs from the same franchise grouped together at the very start (e.g., Cars, Cars 2, Cars 3). After these, DO NOT group other franchises’ entries consecutively (e.g., avoid Shrek, Shrek 2, Shrek the Third back-to-back); interleave them naturally with other relevant titles to prevent a clunky cluster.
               - If Genre/Mood/Trope: source well-known, popular, critically acclaimed titles that match tone and trope; include a balanced mix of classics and trending hits.
               - If Actor/Director: prioritize the person’s best-known works; then add topically similar titles aligned with the Comfort Movies vibe.
            5) Quality curation: prefer titles with broad recognition and solid reception (e.g., TMDB popularity > 10.0 or comparable renown). Avoid obscure or irrelevant foreign-language titles; keep language consistent with the query (default English).
            6) Diversity and coherence: vary decades, subgenres, and services while preserving the requested vibe; avoid near-duplicates and redundant sequels unless strongly value-adding.
            7) Finalize ordering: start with strongest matches, then broaden while staying on-theme; ensure exactly 70 unique items; interleave multi-film franchises (except the initial query’s franchise block).
            8) Self-check: English titles only, zero duplicates, zero extra text, comma-only separation, high relevance to query and Comfort Movies vibe.
        
            Constraints:
            Output: single line, 70 titles, comma-separated, nothing else.
        
            Take a deep breath and work on this problem step-by-step.
        """
        
        let requestBody = GeminiRequest(
            contents: [ContentRequest(parts: [PartRequest(text: prompt)])]
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try JSONEncoder().encode(requestBody)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        do {
            let response = try JSONDecoder().decode(GeminiResponse.self, from: data)
            guard let aiText = response.candidates.first?.content.parts.first?.text else {
                throw URLError(.cannotParseResponse)
            }
            
            let titles = aiText.split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            return titles
            
        } catch {
            print(String(data: data, encoding: .utf8) ?? "No data")
            throw error
        }
    }
    
    static func getSearchSuggestions(for query: String, bookmarkTitles: [String]) async throws -> [String] {
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let context: String
        if bookmarkTitles.isEmpty {
            context = "The user has not added any comfort movies yet."
        } else {
            context = "The user's comfort movies are: \(bookmarkTitles.joined(separator: ", "))."
        }
        // "magic"
        let prompt = """
        Act like a high-precision, ultra-fast search suggestion engine for film and television titles.

        Your objective is to output exactly 10 relevant movie or TV show titles that begin with the user’s current input string.

        Task: Given a raw user keystream, return only a single comma-separated line of 10 distinct, correctly spelled titles that start with that input (case-insensitive), with no extra tokens.

        Requirements:
        1) Output format: one line, comma-separated, exactly 10 titles, no numbering, no quotes, no years, no commentary.
        2) Matching rule: each title must start with the normalized user input (ignore leading “The”, “A”, “An” only if needed to reach 10; otherwise prefer strict begins-with). Match case-insensitively.
        3) Data integrity: suggest only real, widely released titles (films or TV series). No fabrications, placeholders, or upcoming rumors.
        4) Ranking: prioritize cultural prominence + recency + global recognition, then fill with relevant long-tail matches. Avoid duplicates across franchises with identical names unless they are distinct works.
        5) De-duplication & cleanup: remove exact/near duplicates, normalize whitespace, strip trailing/leading spaces, and ensure ASCII commas separate items.
        6) Edge handling: if the input is fewer than 2 characters, still follow all rules; if safe matching yields fewer than 10 strict begins-with results, relax articles (“The/A/An”) next, then allow localized vs. original titles as variants; if still short, expand by credible franchise installments that begin with the input.

        Context:
        User input (raw): \(query)
        Example (do not echo in output): if query = spi → Spider-Man, Spirited Away, Spies in Disguise, Spinal Tap, Spirit: Stallion of the Cimarron, Spider-Man 2, Spider-Man: Homecoming, Spirited, Spiral, Spiderman (1977)

        Constraints:
        - Format: one-line CSV (titles only)
        - Style: terse, search-suggest
        - Scope: movies and TV series only; exclude episodes, fan edits, and non-title strings
        - Reasoning: silently perform retrieval + filtering; do not explain
        - Self-check: verify count==10, all start with input per rules, no extra text

        Take a deep breath and work on this problem step-by-step.

        """
        
        let requestBody = GeminiRequest(
            contents: [ContentRequest(parts: [PartRequest(text: prompt)])]
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try JSONEncoder().encode(requestBody)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        do {
            let response = try JSONDecoder().decode(GeminiResponse.self, from: data)
            guard let aiText = response.candidates.first?.content.parts.first?.text else {
                throw URLError(.cannotParseResponse)
            }
            
            let titles = aiText.split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            return titles
            
        } catch {
            print(String(data: data, encoding: .utf8) ?? "No data")
            throw error
        }
    }
    
}
