import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TranslationRecord.createdAt, order: .reverse) private var records: [TranslationRecord]

    @State private var searchText = ""
    @State private var showFavoritesOnly = false

    var filteredRecords: [TranslationRecord] {
        var result = records

        if showFavoritesOnly {
            result = result.filter { $0.isFavorite }
        }

        if !searchText.isEmpty {
            result = result.filter {
                $0.sourceText.localizedCaseInsensitiveContains(searchText) ||
                $0.translatedText.localizedCaseInsensitiveContains(searchText)
            }
        }

        return result
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                Text("History")
                    .font(.appTitle1)
                    .foregroundColor(.appTextPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, AppSpacing.xl)
                    .padding(.top, AppSpacing.xl)

                SearchBar(text: $searchText)
                    .padding(.horizontal, AppSpacing.xl)
                    .padding(.vertical, AppSpacing.lg)

                Picker("Filter", selection: $showFavoritesOnly) {
                    Text("All").tag(false)
                    Text("Favorites").tag(true)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, AppSpacing.xl)
                .padding(.bottom, AppSpacing.lg)

                if filteredRecords.isEmpty {
                    Spacer()
                    EmptyHistoryView(showFavoritesOnly: showFavoritesOnly)
                    Spacer()
                } else {
                    List {
                        ForEach(filteredRecords) { record in
                            HistoryRecordRow(record: record)
                                .listRowBackground(Color.appBackground)
                                .listRowSeparator(.hidden)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        deleteRecord(record)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .leading) {
                                    Button {
                                        toggleFavorite(record)
                                    } label: {
                                        Label(
                                            record.isFavorite ? "Unfavorite" : "Favorite",
                                            systemImage: record.isFavorite ? "star.slash" : "star.fill"
                                        )
                                    }
                                    .tint(.appWarning)
                                }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
        }
    }

    private func deleteRecord(_ record: TranslationRecord) {
        modelContext.delete(record)
    }

    private func toggleFavorite(_ record: TranslationRecord) {
        record.isFavorite.toggle()
    }
}

struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.appTextMuted)

            TextField("Search translations...", text: $text)
                .font(.appCallout)
                .foregroundColor(.appTextPrimary)

            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.appTextMuted)
                }
            }
        }
        .padding(AppSpacing.lg)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium))
    }
}

struct HistoryRecordRow: View {
    let record: TranslationRecord

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text(record.sourceLanguage)
                    .font(.appCaption)
                    .foregroundColor(.appTextMuted)

                Image(systemName: "arrow.right")
                    .font(.system(size: 10))
                    .foregroundColor(.appTextMuted)

                Text(record.targetLanguage)
                    .font(.appCaption)
                    .foregroundColor(.appTextMuted)

                Spacer()

                if record.isFavorite {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.appWarning)
                }

                Text(record.createdAt.formatted(date: .omitted, time: .shortened))
                    .font(.appCaption)
                    .foregroundColor(.appTextMuted)
            }

            Text(record.sourceText)
                .font(.appBody)
                .foregroundColor(.appTextSecondary)
                .lineLimit(2)

            Text(record.translatedText)
                .font(.appBody)
                .foregroundColor(.appTextPrimary)
                .lineLimit(2)
        }
        .padding(AppSpacing.xl)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.large))
        .padding(.horizontal, AppSpacing.xl)
        .padding(.vertical, AppSpacing.sm)
    }
}

struct EmptyHistoryView: View {
    let showFavoritesOnly: Bool

    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Image(systemName: showFavoritesOnly ? "star" : "clock")
                .font(.system(size: 48))
                .foregroundColor(.appTextMuted)

            Text(showFavoritesOnly ? "No favorites yet" : "No translation history")
                .font(.appHeadline)
                .foregroundColor(.appTextSecondary)

            Text(showFavoritesOnly ? "Star translations to save them here" : "Your translations will appear here")
                .font(.appCallout)
                .foregroundColor(.appTextMuted)
        }
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: TranslationRecord.self, inMemory: true)
}
