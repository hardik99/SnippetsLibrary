//
//  SnippetsLibraryViewModel.swift
//  SnippetsLibrary
//
//  Created by Krzysztof Łowiec on 08/09/2021.
//

import SwiftUI
import Combine

final class SnippetsLibraryViewModel: ObservableObject {
    
    // MARK: - Stored Properties

    @Published internal var snippets: [Snippet] = skeletonSnippets
    @Published internal var selectedSnippetId: SnippetId?
    @Published internal var shouldShowErrorAlert = false
    
    private let activeSnippetId: SnippetId?
    
    private let databaseService: DatabaseService
    private let userDefaultsService: UserDefaultsService
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(
        activeSnippetId: SnippetId? = nil,
        databaseService: DatabaseService = DIContainer.databaseService,
        userDefaultsService: UserDefaultsService = DIContainer.userDefaultsService
    ) {
        self.activeSnippetId = activeSnippetId
        self.databaseService = databaseService
        self.userDefaultsService = userDefaultsService
        
        fetchSnippets()
    }
    
    // MARK: - Methods

    internal func onRemove(_ snippetId: SnippetId?) {
        guard
            let snippetId = snippetId,
            let snippet = snippets.first(where: { $0.id == snippetId })
        else {
            shouldShowErrorAlert.toggle()
            return
        }
        
        removeSnippet(snippet)
    }
    
    internal func fetchSnippets() {
        databaseService.fetchSnippets()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .finished: return
                case .failure:
                    self?.shouldShowErrorAlert.toggle()
                    self?.snippets = []
                }
            } receiveValue: { [weak self] in
                self?.snippets = $0
            }
            .store(in: &cancellables)
    }
    
    internal func saveSnippetToRecentSnippets(_ snippet: Snippet) {
        userDefaultsService.saveRecentSnippet(snippet)
    }
    
    internal func showSnippetPreview() {
        guard let snippetId = activeSnippetId else { return }
        selectedSnippetId = snippetId
    }
    
    private func removeSnippet(_ snippet: Snippet) {
        databaseService.removeSnippet(snippet)
            .sink { [weak self] completion in
                switch completion {
                case .finished:
                    self?.snippets.removeAll { $0.id == snippet.id }
                case .failure:
                    self?.shouldShowErrorAlert.toggle()
                }
            }
            .store(in: &cancellables)
    }

}
