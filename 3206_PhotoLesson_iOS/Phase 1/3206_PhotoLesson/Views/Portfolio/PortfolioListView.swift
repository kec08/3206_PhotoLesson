import SwiftUI

struct PortfolioListView: View {
    @State private var portfolios: [Portfolio] = []
    @State private var isLoading = true
    @State private var showCreateSheet = false
    @State private var newName = ""
    @State private var newDescription = ""

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("포트폴리오를 불러오는 중...")
                } else if portfolios.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        Text("포트폴리오가 없습니다")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                        Text("새 포트폴리오를 만들어보세요")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(portfolios) { portfolio in
                                NavigationLink(destination: PortfolioDetailView(portfolio: portfolio)) {
                                    PortfolioCard(portfolio: portfolio)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("포트폴리오")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCreateSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .task { await loadPortfolios() }
            .refreshable { await loadPortfolios() }
            .sheet(isPresented: $showCreateSheet) {
                createPortfolioSheet
            }
        }
    }

    private var createPortfolioSheet: some View {
        NavigationStack {
            Form {
                SwiftUI.Section("포트폴리오 정보") {
                    TextField("이름", text: $newName)
                    TextField("설명 (선택)", text: $newDescription)
                }
            }
            .navigationTitle("새 포트폴리오")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        showCreateSheet = false
                        resetForm()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("생성") {
                        Task { await createPortfolio() }
                    }
                    .disabled(newName.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func loadPortfolios() async {
        isLoading = true
        do {
            let response = try await APIService.shared.getPortfolios()
            portfolios = response.content
        } catch {
            print("포트폴리오 로드 실패: \(error)")
        }
        isLoading = false
    }

    private func createPortfolio() async {
        do {
            let portfolio = try await APIService.shared.createPortfolio(
                name: newName,
                description: newDescription.isEmpty ? nil : newDescription
            )
            portfolios.insert(portfolio, at: 0)
            showCreateSheet = false
            resetForm()
        } catch {
            print("포트폴리오 생성 실패: \(error)")
        }
    }

    private func resetForm() {
        newName = ""
        newDescription = ""
    }
}

#Preview {
    PortfolioListView()
        .environmentObject(AuthManager())
}

#Preview("포트폴리오 카드") {
    VStack(spacing: 12) {
        PortfolioCard(portfolio: SampleData.portfolio1)
        PortfolioCard(portfolio: SampleData.portfolio2)
    }
    .padding()
}

struct PortfolioCard: View {
    let portfolio: Portfolio

    var body: some View {
        HStack(spacing: 16) {
            // 아이콘
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray5))
                .frame(width: 70, height: 70)
                .overlay {
                    Image(systemName: "photo.stack")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(portfolio.portfolioName)
                    .font(.headline)
                    .lineLimit(1)

                if let description = portfolio.description, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                if let count = portfolio.imageCount {
                    Label("\(count)장", systemImage: "photo")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
