//
//  AdminUserListView.swift
//  3206_PhotoLesson
//

import SwiftUI

struct AdminUserListView: View {
    @State private var users: [User] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("유저 목록 로딩 중...")
                } else if users.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "person.3")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("유저가 없습니다")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    List(users) { user in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.fullName)
                                    .font(.headline)
                                Text(user.email)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Menu {
                                Button("학생") { Task { await changeRole(user: user, role: "STUDENT") } }
                                Button("선생님") { Task { await changeRole(user: user, role: "TEACHER") } }
                                Button("관리자") { Task { await changeRole(user: user, role: "ADMIN") } }
                            } label: {
                                Text(user.role ?? "STUDENT")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(roleColor(user.role).opacity(0.15))
                                    .foregroundStyle(roleColor(user.role))
                                    .cornerRadius(6)
                            }
                        }
                    }
                }
            }
            .navigationTitle("유저 관리")
            .task { await loadUsers() }
            .refreshable { await loadUsers() }
        }
    }

    private func loadUsers() async {
        isLoading = true
        do {
            users = try await APIService.shared.getAdminUsers()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func changeRole(user: User, role: String) async {
        do {
            let updated = try await APIService.shared.changeUserRole(userId: user.id, role: role)
            if let idx = users.firstIndex(where: { $0.id == user.id }) {
                users[idx] = updated
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func roleColor(_ role: String?) -> Color {
        switch role {
        case "ADMIN": return .red
        case "TEACHER": return .blue
        default: return .green
        }
    }
}
