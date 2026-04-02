import SwiftUI

struct CourseCardView: View {
    let course: CourseListItem

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 썸네일 - 직각, 풀 너비
            ZStack {
                if let urlStr = course.thumbnailUrl, let url = URL(string: urlStr) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(16/9, contentMode: .fill)
                    } placeholder: {
                        thumbnailPlaceholder
                    }
                } else {
                    thumbnailPlaceholder
                }
            }
            .frame(height: 200)
            .clipped()

            // 정보 영역
            HStack(alignment: .top, spacing: 12) {
                // 프로필 아이콘
                Circle()
                    .fill(Color.mainCoral.opacity(0.15))
                    .frame(width: 40, height: 40)
                    .overlay {
                        Text(String(course.instructorName.prefix(1)))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color.mainCoral)
                    }

                VStack(alignment: .leading, spacing: 4) {
                    Text(course.title)
                        .font(.system(size: 15, weight: .semibold))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(.primary)

                    Text("\(course.instructorName) · \(course.sectionCount)개 섹션 · \(course.lectureCount)개 레슨")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
        }
    }

    private var thumbnailPlaceholder: some View {
        Rectangle()
            .fill(Color(.systemGray5))
            .aspectRatio(16/9, contentMode: .fill)
            .overlay {
                VStack(spacing: 8) {
                    Image(systemName: "play.rectangle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.secondary)
                }
            }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 0) {
            CourseCardView(course: SampleData.course1)
            CourseCardView(course: SampleData.course2)
        }
    }
}
