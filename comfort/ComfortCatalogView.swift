//
//  ComfortCatalogView.swift
//  first demo
//
//  Created by Kuro Gboun on 2025-11-10.
//
import SwiftUI

struct ComfortCatalogView: View {
    @EnvironmentObject var bookmarkManager: BookmarkManager

    var movieIDs: [Int] {
        Array(bookmarkManager.bookmarkedIDs).sorted()
    }
    
    // grid layout
    let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 15),
        GridItem(.flexible(), spacing: 15),
    ]

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            ScrollView {
                // check if the list is empty
                if movieIDs.isEmpty {
                    
                    Text("it's quiet here")
                        .font(.comfort(size: 18)) //custom font
                        .foregroundColor(.gray)
                        .padding(.top, 50)
                    
                } else {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(movieIDs, id: \.self) { movieID in
                            CatalogItemView(movieID: movieID)
                        }
                    }
                    .padding()
                }
            }
           // .toolbarBackgroundVisibility(.hidden, for: .navigationBar) // doesnt work
        }
//        .navigationTitle("comfort")
        .environment(\.colorScheme, .light) // Force light mode
    }
}

struct CatalogItemView: View {
    let movieID: Int
    
    @State private var movie: Movie?
    
    var body: some View {
        Group {
            if let movie = movie {
                NavigationLink(value: movie) {
                    MoviePoster(posterPath: movie.poster_path, movieID: movie.id)
                }
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .aspectRatio(2/3, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .task {
            do {
                self.movie = try await TMDBClient.getDetails(id: movieID, mediaType: "movie")
            } catch {
                print("Failed to fetch movie \(movieID): \(error)")
            }
        }
    }
}

struct MoviePoster: View {
    let posterPath: String?
    let movieID: Int
    
    @EnvironmentObject var bookmarkManager: BookmarkManager
    var body: some View {
        ZStack(alignment: .topTrailing) {
            
            AsyncImage(url: TMDBClient.imageURL(path: posterPath)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(2/3, contentMode: .fill)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                case .failure, .empty:
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .aspectRatio(2/3, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            Image(systemName: "film")
                                .font(.title)
                                .foregroundColor(.secondary)
                        )
                @unknown default:
                    EmptyView()
                }
            }
            //            if bookmarkManager.isBookmarked(movieID: movieID) {
            //                Image(systemName: "bookmark.fill")
            //                    .font(.title2)
            //                    .foregroundColor(.comfortBackground) // Your pink color
            //                    .padding(5) // Space from the edge
            //                // Offset to nudge it just off the corner
            //                    .offset(x: -5, y: 5)
            //                    .shadow(color: .white, radius: 0, x: 1)
            //                            .shadow(color: .white, radius: 0, x: -1)
            //                            .shadow(color: .white, radius: 0, y: 1)
            //                            .shadow(color: .white, radius: 0, y: -1)            }
            //        }
        }
    }
}
