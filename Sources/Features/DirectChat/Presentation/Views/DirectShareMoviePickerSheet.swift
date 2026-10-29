import SwiftUI

/// Modal minimalista para buscar y compartir una película en el chat directo 1 a 1
public struct DirectShareMoviePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable public var viewModel: DirectChatViewModel
    public let currentUser: User?
    
    @State private var selectedMovie: Movie?
    @State private var noteText: String = ""
    
    public init(viewModel: DirectChatViewModel, currentUser: User?) {
        self.viewModel = viewModel
        self.currentUser = currentUser
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.WhatsApp.chatBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 14) {
                    // Campo de búsqueda de película
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Theme.Colors.WhatsApp.messageTime)
                        
                        TextField("Buscar película por título...", text: $viewModel.movieSearchQuery)
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .onSubmit {
                                Task {
                                    await viewModel.searchMovies()
                                }
                            }
                        
                        if !viewModel.movieSearchQuery.isEmpty {
                            Button {
                                viewModel.movieSearchQuery = ""
                                viewModel.movieSearchResults = []
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(10)
                    .background(Theme.Colors.WhatsApp.inputFieldBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    
                    if let movie = selectedMovie {
                        // Tarjeta de película seleccionada
                        selectedMoviePreview(movie)
                            .padding(.horizontal, 16)
                    } else {
                        // Resultados de búsqueda
                        searchResultsList
                    }
                }
            }
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("COMPARTIR PELÍCULA")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                    .foregroundColor(Theme.Colors.WhatsApp.messageTime)
                }
            }
            .task {
                if viewModel.movieSearchResults.isEmpty && !viewModel.movieSearchQuery.isEmpty {
                    await viewModel.searchMovies()
                }
            }
        }
    }
    
    // MARK: - Selected Movie Preview & Send
    
    private func selectedMoviePreview(_ movie: Movie) -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                if let poster = movie.posterURL {
                    AsyncImage(url: poster) { img in
                        img.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle().fill(Color.gray.opacity(0.3))
                    }
                    .frame(width: 60, height: 90)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 60, height: 90)
                        .overlay(Image(systemName: "film").foregroundColor(.gray))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(movie.title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("\(movie.releaseYear)")
                        .font(.subheadline)
                        .foregroundColor(Theme.Colors.WhatsApp.messageTime)
                    
                    if let rt = movie.ratings.rottenTomatoesCritics {
                        Text("Rotten Tomatoes: \(rt)%")
                            .font(.caption)
                            .foregroundColor(Theme.Colors.rottenTomatoesCritics)
                    }
                }
                
                Spacer()
                
                Button {
                    withAnimation {
                        selectedMovie = nil
                    }
                } label: {
                    Image(systemName: "xmark.circle")
                        .font(.title3)
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .background(Color(red: 20/255, green: 29/255, blue: 35/255))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Nota opcional
            VStack(alignment: .leading, spacing: 6) {
                Text("AÑADIR UN COMENTARIO (OPCIONAL)")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.Colors.WhatsApp.accentGreen)
                
                TextField("¿Por qué recomiendas esta película?", text: $noteText, axis: .vertical)
                    .lineLimit(2...4)
                    .padding(10)
                    .background(Theme.Colors.WhatsApp.inputFieldBackground)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            // Botón de Enviar
            Button {
                guard let user = currentUser else { return }
                Task {
                    _ = await viewModel.shareMovieInChat(movie: movie, note: noteText, currentUser: user)
                    dismiss()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "paperplane.fill")
                    Text("Compartir en este Chat 1 a 1")
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Theme.Colors.WhatsApp.accentGreen)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
    }
    
    // MARK: - Search Results
    
    private var searchResultsList: some View {
        Group {
            if viewModel.isSearchingMovies {
                ProgressView()
                    .tint(.white)
                    .padding(.top, 40)
            } else if viewModel.movieSearchResults.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "film")
                        .font(.system(size: 36))
                        .foregroundColor(Theme.Colors.WhatsApp.messageTime.opacity(0.6))
                        .padding(.top, 40)
                    
                    Text("Busca una película para recomendar en este chat")
                        .font(.subheadline)
                        .foregroundColor(Theme.Colors.WhatsApp.messageTime)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 30)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.movieSearchResults) { movie in
                            Button {
                                withAnimation {
                                    selectedMovie = movie
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    if let poster = movie.posterURL {
                                        AsyncImage(url: poster) { img in
                                            img.resizable().aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            Rectangle().fill(Color.gray.opacity(0.3))
                                        }
                                        .frame(width: 44, height: 66)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                    } else {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.white.opacity(0.1))
                                            .frame(width: 44, height: 66)
                                            .overlay(Image(systemName: "film").foregroundColor(.gray))
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(movie.title)
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.white)
                                            .multilineTextAlignment(.leading)
                                        
                                        Text("\(movie.releaseYear)")
                                            .font(.system(size: 12))
                                            .foregroundColor(Theme.Colors.WhatsApp.messageTime)
                                        
                                        if let imdb = movie.ratings.formattedIMDb {
                                            Text("IMDb: \(imdb)")
                                                .font(.system(size: 11, weight: .semibold))
                                                .foregroundColor(Theme.Colors.imdb)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(Theme.Colors.WhatsApp.accentGreen)
                                }
                                .padding(10)
                                .background(Color(red: 20/255, green: 29/255, blue: 35/255))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
        }
    }
}
