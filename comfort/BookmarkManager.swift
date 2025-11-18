//
//  BookmarkManager.swift
//  first demo
//
//  Created by Kuro Gboun on 2025-11-10.
//
import Foundation
import Combine

@MainActor
class BookmarkManager: ObservableObject {
    
    @Published var bookmarkedIDs: Set<Int>
    
    private let userDefaultsKey = "ComfortMovieBookmarks"

    init() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey) {
            if let decoded = try? JSONDecoder().decode(Set<Int>.self, from: data) {
                self.bookmarkedIDs = decoded
                return
            }
        }
        
        self.bookmarkedIDs = []
    }
    
    func isBookmarked(movieID: Int) -> Bool {
        bookmarkedIDs.contains(movieID)
    }

    func toggleBookmark(movieID: Int) {
        if isBookmarked(movieID: movieID) {
            bookmarkedIDs.remove(movieID)
        } else {
            bookmarkedIDs.insert(movieID)
        }
        
        save()
    }
    
    // a private function to save the data to UserDefaults
    private func save() {
        if let encoded = try? JSONEncoder().encode(bookmarkedIDs) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
}
