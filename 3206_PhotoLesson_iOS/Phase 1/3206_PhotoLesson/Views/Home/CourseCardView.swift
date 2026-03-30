import SwiftUI

struct CourseCardView: View {
    let course: CourseListItem

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 썸네일
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
            .frame(height: 180)
            .clipped()
            .cornerRadius(12)

            VStack(alignment: .leading, spacing: 6) {
                // 카테고리 & 레벨 태그
                HStack(spacing: 6) {
                    if let cat = course.categoryEnum {
                        Text(cat.displayName)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(.blue.opacity(0.1))
                            .foregroundStyle(.blue)
                            .cornerRadius(4)
                    }
                    if let level = course.levelEnum {
                        Text(level.displayName)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(.orange.opacity(0.1))
                            .foregroundStyle(.orange)
                            .cornerRadius(4)
                    }
                }

                // 제목
                Text(course.title)
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                // 강사명
                Text(course.instructorName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                // 섹션 & 레슨 수
                HStack(spacing: 12) {
                    Label("\(course.sectionCount)개 섹션", systemImage: "folder")
                    Label("\(course.lectureCount)개 레슨", systemImage: "play.circle")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 4)
        }
        .background(Color(.systemBackground))
    }

    private var thumbnailPlaceholder: some View {
        Rectangle()
            .fill(Color(.systemGray5))
            .aspectRatio(16/9, contentMode: .fill)
            .overlay {
                Image(systemName: "camera")
                    .font(.system(size: 40))
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
