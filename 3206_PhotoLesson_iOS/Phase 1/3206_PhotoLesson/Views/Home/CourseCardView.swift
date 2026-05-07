import SwiftUI

struct CourseCardView: View {
    let course: CourseListItem

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 썸네일
            ZStack(alignment: .topLeading) {
                if let fullUrl = APIService.shared.fullImageURL(course.thumbnailUrl),
                   let url = URL(string: fullUrl) {
                    AsyncImage(url: url, transaction: Transaction(animation: nil)) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().aspectRatio(16/9, contentMode: .fill)
                        default:
                            thumbnailPlaceholder
                        }
                    }
                } else {
                    thumbnailPlaceholder
                }

                // 레벨 뱃지
                if let lev = CourseLevel(rawValue: course.level) {
                    Text(lev.displayName)
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial)
                        .cornerRadius(6)
                        .padding(8)
                }
            }
            .aspectRatio(16/9, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // 정보
            VStack(alignment: .leading, spacing: 6) {
                // 카테고리 태그
                if let cat = CourseCategory(rawValue: course.category) {
                    Text(cat.displayName)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.mainCoral)
                }

                // 제목
                Text(course.title)
                    .font(.system(size: 14, weight: .bold))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(.primary)

                // 강사명
                Text(course.instructorName)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)

                // 하단 정보
                HStack(spacing: 4) {
                    Image(systemName: "play.rectangle")
                        .font(.system(size: 10))
                    Text("\(course.lectureCount)개 레슨")
                        .font(.system(size: 11))

                    Text("·")

                    Image(systemName: "folder")
                        .font(.system(size: 10))
                    Text("\(course.sectionCount)개 섹션")
                        .font(.system(size: 11))
                }
                .foregroundStyle(.tertiary)

                // 가격
                if let price = course.price, price > 0 {
                    Text("₩\(price.formatted())")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.mainCoral)
                } else {
                    Text("무료")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.green)
                }
            }
            .padding(.top, 10)
            .padding(.bottom, 6)
        }
        .background(Color(.systemBackground))
    }

    private var thumbnailPlaceholder: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [Color(.systemGray5), Color(.systemGray6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .aspectRatio(16/9, contentMode: .fill)
            .overlay {
                VStack(spacing: 6) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 28))
                    Text("PhotoLesson")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundStyle(.secondary)
            }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            CourseCardView(course: SampleData.course1)
            CourseCardView(course: SampleData.course2)
        }
        .padding()
    }
}
