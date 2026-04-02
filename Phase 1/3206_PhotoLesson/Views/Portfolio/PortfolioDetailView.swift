import SwiftUI
import PhotosUI

struct PortfolioDetailView: View {
    let portfolio: Portfolio

    @State private var images: [PortfolioImage] = []
    @State private var isLoading = true
    @State private var selectedItem: PhotosPickerItem?
    @State private var isUploading = false
    @State private var showDeleteAlert = false
    @State private var imageToDelete: PortfolioImage?

    private let columns = [
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 포트폴리오 정보
                VStack(alignment: .leading, spacing: 8) {
                    if let description = portfolio.description, !description.isEmpty {
                        Text(description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Text("\(images.count)장의 사진")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)

                if isUploading {
                    HStack {
                        ProgressView()
                        Text("업로드 중...")
                            .font(.subheadline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }

                // 이미지 그리드
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                } else if images.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 50))
                            .foregroundStyle(.secondary)
                        Text("사진을 추가해보세요")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                } else {
                    LazyVGrid(columns: columns, spacing: 4) {
                        ForEach(images) { image in
                            imageCell(image)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .navigationTitle(portfolio.portfolioName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Image(systemName: "plus.circle")
                }
            }
        }
        .task { await loadImages() }
        .onChange(of: selectedItem) { _, newValue in
            if let item = newValue {
                Task { await uploadImage(item: item) }
            }
        }
        .alert("사진 삭제", isPresented: $showDeleteAlert) {
            Button("삭제", role: .destructive) {
                if let image = imageToDelete {
                    Task { await deleteImage(image) }
                }
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("이 사진을 삭제하시겠습니까?")
        }
    }

    @ViewBuilder
    private func imageCell(_ image: PortfolioImage) -> some View {
        if let urlStr = APIService.shared.fullImageURL(image.thumbnailUrl ?? image.imageUrl),
           let url = URL(string: urlStr) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let img):
                    img
                        .resizable()
                        .scaledToFill()
                case .failure:
                    Color(.systemGray5)
                        .overlay {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundStyle(.secondary)
                        }
                default:
                    Color(.systemGray5)
                        .overlay { ProgressView() }
                }
            }
            .frame(height: 120)
            .frame(maxWidth: .infinity)
            .clipped()
            .contextMenu {
                Button(role: .destructive) {
                    imageToDelete = image
                    showDeleteAlert = true
                } label: {
                    Label("삭제", systemImage: "trash")
                }
            }
        }
    }

    private func loadImages() async {
        do {
            images = try await APIService.shared.getPortfolioImages(portfolioId: portfolio.portfolioId)
        } catch {
            print("이미지 로드 실패: \(error)")
        }
        isLoading = false
    }

    private func uploadImage(item: PhotosPickerItem) async {
        isUploading = true
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                let filename = "photo_\(Int(Date().timeIntervalSince1970)).jpg"
                let newImage = try await APIService.shared.uploadPortfolioImage(
                    portfolioId: portfolio.portfolioId,
                    imageData: data,
                    filename: filename
                )
                images.insert(newImage, at: 0)
            }
        } catch {
            print("업로드 실패: \(error)")
        }
        selectedItem = nil
        isUploading = false
    }

    private func deleteImage(_ image: PortfolioImage) async {
        do {
            try await APIService.shared.deletePortfolioImage(
                portfolioId: portfolio.portfolioId,
                imageId: image.imageId
            )
            images.removeAll { $0.imageId == image.imageId }
        } catch {
            print("삭제 실패: \(error)")
        }
    }
}

#Preview {
    NavigationStack {
        PortfolioDetailView(portfolio: SampleData.portfolio1)
    }
}
