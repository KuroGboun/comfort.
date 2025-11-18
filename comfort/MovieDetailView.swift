//
//  MovieDetailView.swift
//  first demo
//
//  Created by Kuro Gboun on 2025-10-28.
//

import SwiftUI

enum DetailTab {
    case similar
    case details
}

struct MovieDetailView: View {
    // movie/tvshow that was clicked on
    let movie: Movie
    
    @State private var relatedMovies: [Movie] = []
    @State private var currentPage = 1
    @State private var isLoading = false
    @State private var canLoadMore = true
    //@State private var isBookmarked = false
    @State private var isWatchlist = false
    @State private var selectedTab: DetailTab = .similar
    @EnvironmentObject var bookmarkManager: BookmarkManager
    
    @Namespace private var tabNamespace
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            ScrollView { // Assuming this is inside a ScrollView for details
                VStack(alignment: .leading) {
                                        Group {
                        if let backdropPath = movie.backdrop_path {
                            AsyncImage(url: TMDBClient.backdropURL(path: backdropPath)) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .frame(maxWidth: .infinity, minHeight: 200) // Ensure it takes up space
                                        .background(Color.gray.opacity(0.3))
                                        .cornerRadius(0) // No corner radius for top
                                case .success(let image):
                                    ZStack(alignment: .bottom) { // Layer for gradient
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill) // Fill the width
                                            .frame(maxWidth: .infinity)     // Ensure it expands
                                            .clipped()
                                        
                                    }
                                    .frame(height: 250) // Adjust the overall height of the backdrop section
                                    .cornerRadius(0) // No corner radius for the main backdrop
                                    
                                case .failure:
                                    // Error placeholder
                                    Image(systemName: "photo")
                                        .font(.largeTitle)
                                        .foregroundColor(.gray)
                                        .frame(maxWidth: .infinity, minHeight: 200)
                                        .background(Color.gray.opacity(0.3))
                                        .cornerRadius(0)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        } else {
                            Color.gray.opacity(0.3)
                                .frame(maxWidth: .infinity, minHeight: 200)
                                .overlay(Text("No Backdrop Available").foregroundColor(.white))
                                .cornerRadius(0)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    //VSTACK THIS
                    
                    HStack{
                        
                        Text(movie.title ?? "Unknown Title") // fix text overflow
                            .font(.comfort(size: 25))
                            .foregroundColor(.black)
                            .lineLimit(1)
                            .padding(.leading, 40)
                        
                        
                        Text(movie.year ?? "??")
                            .font(.comfort(size: 12))
                            .foregroundColor(.black)
                            .padding(.top, 8.7)
                        
                        Image(systemName: "4k.tv.fill")
                            .foregroundColor(.black)
                            .padding(.top, 8.7)
                            .font(.system(size: 15))
                        
                    }
                    .frame(maxWidth: 400, alignment: .leading)
                    .padding(.top, 10)
                    
                    Text(movie.overview ?? "Unknown Overview")
                        .font(.comfort(size: 12))
                        .foregroundColor(.black)
                        .padding(.top, 1)
                        .padding(.leading, 40)
                        .padding(.trailing, 40)
                    
                    
                    VStack{
                        HStack {
                            Spacer()
                            Button(action: {
                                bookmarkManager.toggleBookmark(movieID: movie.id)
                            }) {
                                if bookmarkManager.isBookmarked(movieID: movie.id) {
                                    HStack {
                                        Spacer()
                                        Image(systemName: "bookmark.fill")
                                            .foregroundColor(.comfortBackground)
                                        //Spacer()
                                        
                                        Text("comfort")
                                            .font(.comfort(size: 15))
                                            .foregroundColor(.black)
                                        
                                        
                                        Spacer()
                                        Spacer()
                                        
                                    }
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                } else {
                                    HStack {
                                        Spacer()
                                        Image(systemName: "bookmark")
                                            .foregroundColor(.comfortBackground)
                                        //Spacer()
                                        
                                        Text("comfort")
                                            .font(.comfort(size: 15))
                                            .foregroundColor(.black)
                                        
                                        
                                        Spacer()
                                        Spacer()
                                        
                                    }
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)     // centers the HStack content
                                    
                                }
                            }
                            .padding(.horizontal, 40)
                            .padding(.vertical, 20)
                            .padding(.leading, 40)
                            
                            .frame(width: 370, height: 50) // Give a fixed width
                            .foregroundColor(.black.opacity(0.8))
                            .glassCapsule()
                            //.environment(\.colorScheme, .light)
                            Spacer()
                        }
                        HStack {
                            Spacer()
                            Button(action: {
                                isWatchlist.toggle()
                            }) {
                                if isWatchlist {
                                    HStack {
                                        Spacer()
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.black)
                                        //Spacer()
                                        
                                        Text("watchlist")
                                            .font(.comfort(size: 15))
                                            .foregroundColor(.black)
                                        
                                        
                                        Spacer()
                                        Spacer()
                                        
                                    }
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                } else {
                                    HStack {
                                        Spacer()
                                        Image(systemName: "plus")
                                            .foregroundColor(.black)
                                        //Spacer()
                                        
                                        Text("watchlist")
                                            .font(.comfort(size: 15))
                                            .foregroundColor(.black)
                                        
                                        
                                        Spacer()
                                        Spacer()
                                        
                                    }
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)     // centers the HStack content
                                    
                                }
                            }
                            .padding(.horizontal, 40)
                            .padding(.vertical, 20)
                            .padding(.leading, 40)
                            
                            .frame(width: 370, height: 50) // Give a fixed width
                            .foregroundColor(.black.opacity(0.8))
                            .glassCapsule()
                            //.environment(\.colorScheme, .light)
                            Spacer()
                        }
                        
                    }
                    .padding(.top, 17)
                    .padding(.bottom, 37)
                    // ... rest of your movie details
                    
                    
                    
                    
                    HStack(spacing: 30){
                        Button(action: {
                            selectedTab = .similar
                            
                        }) {
                            TabButton(
                                title: "comfort movies",
                                isSelected: selectedTab == .similar,
                                namespace: tabNamespace
                            )
                        }
                        
                        // "More Details" Button
                        Button(action: {
                            selectedTab = .details
                            
                        }) {
                            TabButton(
                                title: "details",
                                isSelected: selectedTab == .details,
                                namespace: tabNamespace
                            )
                        }
                    }
                    .padding(.vertical, 10)
                    .padding(.leading, 40)
                    
                    // This pushes your buttons to the left
                    .frame(width: 370, alignment: .leading)
                    VStack {
                        if selectedTab == .similar {
                            SimilarMoviesView(
                                movieID: movie.id,
                                movieTitle: movie.title ?? ""
                            )
                        } else {
                            MoreDetailsView(movie: movie)
                        }
                    }
                    
                }
            }
            .ignoresSafeArea(.container, edges: .top)
            //.edgesIgnoringSafeArea(.top)
            .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            // If you want the backdrop to truly extend to the top safe area:
            //            .edgesIgnoringSafeArea(.top) // Apply this to the ScrollView or the containing view
                      
            .task {
                guard relatedMovies.isEmpty else { return }
                
                do {
                    let bookmarkTitles = await fetchBookmarkTitles(ids: bookmarkManager.bookmarkedIDs)
                    
                    let searchResults = try await GeminiClient.performAISearch(
                        for: movie.title ?? "", // Use the main movie's title
                        bookmarkTitles: bookmarkTitles
                    )
                    
                    let allSimilarMovies = searchResults.map { $0.asMovie() }
                    self.relatedMovies = allSimilarMovies.filter { $0.id != movie.id }
                    
                } catch {
                    print("Error loading related movies: \(error)")
                }
            }
        }
    }
            
            private func fetchBookmarkTitles(ids: Set<Int>) async -> [String] {
                await withTaskGroup(of: Movie?.self) { group in
                    var titles: [String] = []
                    
                    for id in ids {
                        group.addTask {
                            return try? await TMDBClient.getDetails(id: id, mediaType: "movie")
                        }
                    }
                    
                    for await movie in group {
                        if let title = movie?.title {
                            titles.append(title)
                        }
                    }
                    
                    return titles
                }
            }
        
    
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let namespace: Namespace.ID
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 1. The Text
            Text(title)
                .font(.comfort(size: 18)) // Use your font
                .fontWeight(.semibold)
                .foregroundColor(isSelected ? (title == "comfort movies" ? .comfortBackground : .black) : .gray.opacity(0.7))
            
            // 2. The Underline
            if isSelected {
                Rectangle()
                    .frame(height: 2)
                    .foregroundColor(.comfortBackground)
                    // This tells the underline where to animate from/to
                    .matchedGeometryEffect(id: "underline", in: namespace)
            } else {
                // 3. A clear bar to hold the space
                Rectangle()
                    .frame(height: 2)
                    .foregroundColor(.clear)
            }
        }
        .fixedSize()
    }
}

struct SimilarMoviesView: View {
    let movieID: Int
    let movieTitle: String
    @State private var relatedMovies: [Movie] = []
    
    // Define grid columns
    let columns = [
        GridItem(.flexible(), spacing: 15),
        GridItem(.flexible(), spacing: 15)
    ]

    var body: some View {
        // This grid scrolls *with* the main view
        LazyVGrid(columns: columns, spacing: 20) {
            ForEach(relatedMovies) { movie in
                NavigationLink(destination: MovieDetailView(movie: movie)) {
                    VStack {
                        // Movie Poster
                        AsyncImage(url: movie.posterURL) { phase in
                            if let image = phase.image {
                                image.resizable()
                            } else {
                                Color.gray.opacity(0.3) // Placeholder
                            }
                        }
                        .aspectRatio(2/3, contentMode: .fill)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        
                
                    }
                }
            }
        }
        .padding(.leading, 40)
        .frame(width: 400, alignment: .leading)
        .task {
            // Load movies when this tab appears
            do {
                let searchResults = try await GeminiClient.performAISearch(
                    for: "\(movieTitle)",
                    bookmarkTitles: [] // <-- Pass an empty array here
                )
                let allSimilarMovies = searchResults.map { $0.asMovie() }
                            
                            // 2. Filter out the original movie using its ID
                self.relatedMovies = allSimilarMovies.filter { $0.id != movieID }
            } catch {
                print("Error loading related movies: \(error)")
            }
        }
    }

}

struct MoreDetailsView: View {
    let movie: Movie
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            DetailRow(title: "Release Date", value: movie.release_date ?? "N/A")
            DetailRow(title: "Vote Average", value: String(format: "%.1f", movie.vote_average ?? 0.0))
            DetailRow(title: "Vote Count", value: "\(movie.vote_count ?? 0)")
            DetailRow(title: "Popularity", value: String(format: "%.2f", movie.popularity ?? 0.0))
        }
        .padding(.leading, 40)
        .frame(width: 400, alignment: .leading)
    }
}

// Helper view for details
struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.black)
            Spacer()
            Text(value)
                .font(.body)
                .foregroundColor(.gray)
        }
    }
}
//

