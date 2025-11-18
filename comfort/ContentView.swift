//
//  ContentView.swift
//  first demo
//
//  Created by Kuro Gboun on 2025-10-20.
//

import SwiftUI

struct ContentView: View {
    @State private var path: NavigationPath = .init()
    @State private var searchText: String = ""
    @FocusState private var isKeyboardActive: Bool
    @FocusState private var isFocused: Bool     // internal keyboard tracking
    @State private var showComfortText = true
    @State private var showSearchScreen = false 
    @State private var isPressed = false        // acts like your flag
    @State private var isSearchActive = false // typin..
    @Namespace private var searchBarNamespace
    @StateObject private var bookmarkManager = BookmarkManager()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.white
                    .ignoresSafeArea()
                ComfortView(
                    isSearchActive: $isSearchActive,
                    namespace: searchBarNamespace
                )
            }
            .navigationDestination(for: Movie.self) { movie in
                // push a MovieDetailView onto the screen."
                MovieDetailView(movie: movie)
                    .environment(\.colorScheme, .light)
            }
        }
        .environmentObject(bookmarkManager)
    }
}
    
struct ComfortView: View {
        @Binding var isSearchActive: Bool
        let namespace: Namespace.ID
        @State private var searchText: String = ""
        @FocusState private var isKeyboardActive: Bool
        
        var body: some View {
            ZStack {
                // Your "comfort" text
                HStack{
                    // show ONLY the comfort text, then remove it completely
                    Text("let's get you")
                        .font(.comfort(size: 30))
                        .foregroundColor(.black)
                    
                    
                    Text("comfort.")
                        .font(.comfort(size: 30))
                        .foregroundColor(.comfortBackground)
                    
                    
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .opacity( !searchText.isEmpty ? 0 : 1) // Fades out
                
            if !searchText.isEmpty {
                    SearchView(searchText: $searchText)
                        .transition(.opacity) // Fades in
                }
        }
        .animation(.smooth(duration: 0.3), value: isKeyboardActive)
        .safeAreaInset(edge: .bottom) {
            HStack(alignment: .center, spacing: 2) {
                // 1. The SearchBar now shares space
                SearchBar(searchText: $searchText,
                          isKeyboardActive: $isKeyboardActive)
                Spacer()

                // 2. The "Cancel" button
                if isKeyboardActive || !searchText.isEmpty {
                    Button {
                        withAnimation(.smooth(duration: 0.3)) {
                            searchText = ""
                            isKeyboardActive = false
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill") // SF Symbol image
                            .font(.title2)
                            .foregroundColor(.gray)
                            .padding(10)
                    }
                    .glassCircle()
                    .environment(\.colorScheme, .light)
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
                } else {
                        NavigationLink(value: "ComfortCatalog") {
                            Image(systemName: "bookmark.fill")
                                .font(.title2)
                                .foregroundColor(.comfortBackground)
                                .padding(10)
                                .glassCapsule()
                        }
                        .foregroundStyle(.secondary) // here!
                        .environment(\.colorScheme, .light)
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                    }
                }
                .padding(.horizontal, 20) // Moved padding to the HStack
                .animation(.smooth(duration: 0.3), value: searchText.isEmpty)

        }
        .navigationDestination(for: String.self) { value in
            if value == "ComfortCatalog" {
                ComfortCatalogView() // This opens your page
            }
        }
    }
}
    
struct SearchBar: View {
    @Binding var searchText: String
    var isKeyboardActive: FocusState<Bool>.Binding
    
    var body: some View {
        
        HStack(spacing: 8){
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
            
            TextField("Search a comfort movie...", text: $searchText)
                .submitLabel(.search)
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .focused(isKeyboardActive)
                .textInputAutocapitalization(.never)
                .submitLabel(searchText.isEmpty ? .search : .done)
                .onSubmit {
                    print("OnSubmit fired!")
                    isKeyboardActive.wrappedValue = false
                }
            
            Spacer()
        }
        .padding(.horizontal, 30) // 2. Apply padding to the HStack
        .frame(height: 50)         // 3. Apply frame to the HStack
        .glassCapsule()           // 4. Apply the glass effect ONCE
        .environment(\.colorScheme, .light)
    }

    
}


struct SearchView: View {
    @Binding var searchText: String
    @State private var results: [SearchResult] = []
    @State private var isLoading = false
    @State private var errorText: String?
    @State private var searchTask: Task<Void, Never>?
    @EnvironmentObject var bookmarkManager: BookmarkManager
    
    var body: some View {
        
        VStack {
            let columns: [GridItem] = [
                GridItem(.flexible(), spacing: 16), // Spacing between columns
                GridItem(.flexible())
            ]
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) { // Spacing between rows
                
                // 4. Loop through all results
                    ForEach(results) { result in
                    // 5. Each poster is a NavigationLink
                    NavigationLink(value: result.asMovie()) {
                        
                        AsyncImage(url: TMDBClient.imageURL(path: result.poster_path)) { image in
                            image
                                .resizable()
                                .aspectRatio(2/3, contentMode: .fill) // Standard poster ratio
                                .cornerRadius(8)
                        } placeholder: {
                            ZStack {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.1))
                                    .aspectRatio(2/3, contentMode: .fit)
                                    .cornerRadius(8)
                                
                                Image(systemName: "film")
                                    .font(.largeTitle)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
                .padding(.horizontal) // Add padding to the sides of the grid
            }
        }
        .environment(\.colorScheme, .light) // ← forces light mode
        .onChange(of: searchText) { newValue in
            // Cancel the previous task to debounce typing
            searchTask?.cancel()
            searchTask = Task {
                do {                    
                    try await Task.sleep(nanoseconds: 800_000_000)
                                 
                    let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    guard q.count >= 3 else {
                        results = []
                        return
                    }
                    if q.isEmpty {
                        results = []
                    } else {
                
                        isLoading = true
                        errorText = nil
                        
                        let bookmarkTitles = await fetchBookmarkTitles(ids: bookmarkManager.bookmarkedIDs)
                                        
                        let searchResults = try await GeminiClient.performSearch(
                            for: q,
                            bookmarkTitles: bookmarkTitles
                        )
                        self.results = searchResults
                        isLoading = false
                    }
                } catch is CancellationError {
                } catch {
                    print("AI search failed: \(error.localizedDescription)")
                    self.errorText = "AI search failed. Please try again."
                    self.results = []
                    self.isLoading = false
                }
            }
        }
        
    }
    
    private func fetchBookmarkTitles(ids: Set<Int>) async -> [String] {
        await withTaskGroup(of: Movie?.self) { group in
            var titles: [String] = []
            
            for id in ids {
                group.addTask {
                    // We assume they are "movie" for this.
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
#Preview {
    //SearchView(searchText: .constant("spider"))
    ContentView()
}
