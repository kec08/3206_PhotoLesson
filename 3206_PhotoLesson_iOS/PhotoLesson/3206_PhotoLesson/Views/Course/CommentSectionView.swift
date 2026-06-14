//
//  CommentSectionView.swift
//  3206_PhotoLesson
//

import SwiftUI

struct CommentSectionView: View {
    let lectureId: Int
    @State private var comments: [Comment] = []
    @State private var newComment = ""
    @State private var isLoading = false
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("댓글 \(comments.count)")
                .font(.headline)

            // 댓글 입력
            HStack(spacing: 10) {
                TextField("댓글을 입력하세요...", text: $newComment)
                    .textFieldStyle(.roundedBorder)

                Button {
                    Task { await postComment() }
                } label: {
                    Image(systemName: "paperplane.fill")
                        .foregroundStyle(newComment.isEmpty ? .secondary : Color.mainCoral)
                }
                .disabled(newComment.isEmpty)
            }

            Divider()

            // 댓글 목록
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if comments.isEmpty {
                Text("아직 댓글이 없습니다. 첫 댓글을 남겨보세요!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                ForEach(comments) { comment in
                    CommentRow(
                        comment: comment,
                        isMine: comment.memberId == authManager.currentUserId,
                        onDelete: {
                            Task { await deleteComment(comment) }
                        }
                    )
                }
            }
        }
        .padding()
        .task {
            await loadComments()
        }
    }

    private func loadComments() async {
        isLoading = true
        do {
            comments = try await APIService.shared.getComments(lectureId: lectureId)
        } catch {
            // 에러 처리
        }
        isLoading = false
    }

    private func postComment() async {
        let content = newComment.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }

        do {
            let comment = try await APIService.shared.createComment(lectureId: lectureId, content: content)
            comments.insert(comment, at: 0)
            newComment = ""
        } catch {
            // 에러 처리
        }
    }

    private func deleteComment(_ comment: Comment) async {
        do {
            try await APIService.shared.deleteComment(commentId: comment.id)
            withAnimation {
                comments.removeAll { $0.id == comment.id }
            }
        } catch {
            // 에러 처리
        }
    }
}

struct CommentRow: View {
    let comment: Comment
    let isMine: Bool
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(Color.mainCoral.opacity(0.15))
                .frame(width: 32, height: 32)
                .overlay {
                    Text(String(comment.memberName.prefix(1)))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.mainCoral)
                }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(comment.memberName)
                        .font(.system(size: 13, weight: .semibold))
                    Text(formatDate(comment.createdAt))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Spacer()
                    if isMine {
                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .font(.system(size: 12))
                                .foregroundStyle(.red.opacity(0.7))
                        }
                    }
                }

                Text(comment.content)
                    .font(.system(size: 14))
                    .foregroundStyle(.primary)
            }
        }
        .padding(.vertical, 6)
    }

    private func formatDate(_ dateString: String) -> String {
        // "2026-04-15T10:30:00" → "04.15"
        let parts = dateString.split(separator: "T")
        if let datePart = parts.first {
            let components = datePart.split(separator: "-")
            if components.count >= 3 {
                return "\(components[1]).\(components[2])"
            }
        }
        return dateString
    }
}
