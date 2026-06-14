import SwiftUI

struct CircularProgressView: View {
    let progress: Double
    var lineWidth: CGFloat = 10

    var body: some View {
        ZStack {
            // 배경 원
            Circle()
                .stroke(Color(.systemGray5), lineWidth: lineWidth)

            // 진행 원
            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(
                    Color.mainCoral,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)

            // 퍼센트 텍스트
            GeometryReader { geo in
                let size = min(geo.size.width, geo.size.height)
                let fontSize = max(size * 0.28, 10)
                VStack(spacing: 1) {
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: fontSize, weight: .bold))
                        .foregroundStyle(Color.mainCoral)
                    if size > 60 {
                        Text("완료")
                            .font(.system(size: fontSize * 0.45))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

#Preview {
    VStack(spacing: 30) {
        CircularProgressView(progress: 0.75)
            .frame(width: 120, height: 120)
        CircularProgressView(progress: 0.3, lineWidth: 8)
            .frame(width: 80, height: 80)
    }
}
