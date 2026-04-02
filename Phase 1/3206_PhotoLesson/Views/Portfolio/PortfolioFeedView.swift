import SwiftUI

/// 인스타 피드 스타일 - 포트폴리오 이미지를 좌우 스와이프로 볼 수 있음
struct PortfolioFeedView: View {
    let portfolio: Portfolio
    let images: [PortfolioImage]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // 이미지 슬라이더
                if !images.isEmpty {
                    TabView {
                        ForEach(images) { image in
                            if let urlStr = APIService.shared.fullImageURL(image.thumbnailUrl ?? image.imageUrl),
                               let url = URL(string: urlStr) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .success(let img):
                                        img.resizable().scaledToFill()
                                    default:
                                        Color(.systemGray5)
                                            .overlay { ProgressView() }
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 400)
                                .clipped()
                            }
                        }
                    }
                    .frame(height: 400)
                    .tabViewStyle(.page(indexDisplayMode: .always))
                }

                // 캡션
                VStack(alignment: .leading, spacing: 8) {
                    Text(portfolio.portfolioName)
                        .font(.system(size: 17, weight: .bold))

                    if let desc = portfolio.description, !desc.isEmpty {
                        Text(desc)
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)
                            .lineSpacing(4)
                    }

                    if let count = portfolio.imageCount {
                        Text("\(count)장의 사진")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
        }
        .navigationTitle(portfolio.portfolioName)
        .navigationBarTitleDisplayMode(.inline)
    }
}
