import SwiftUI
import PhotosUI

struct AdminMyPageView: View {
    @EnvironmentObject var authManager: AuthManager

    @State private var user: User?
    @State private var isLoading = true
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isUploadingPhoto = false
    @State private var showEditProfile = false
    @State private var editName = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if isLoading {
                    ProgressView()
                        .frame(maxHeight: .infinity)
                } else {
                    Spacer().frame(height: 20)

                    // 프로필 이미지
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        ZStack(alignment: .bottomTrailing) {
                            if isUploadingPhoto {
                                Circle()
                                    .fill(Color(.systemGray5))
                                    .frame(width: 100, height: 100)
                                    .overlay { ProgressView() }
                            } else if let urlStr = user?.profileImageUrl,
                                      let fullUrl = APIService.shared.fullImageURL(urlStr),
                                      let url = URL(string: fullUrl) {
                                AsyncImage(url: url) { image in
                                    image.resizable().scaledToFill()
                                } placeholder: {
                                    profilePlaceholder
                                }
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                            } else {
                                profilePlaceholder
                            }

                            Circle()
                                .fill(Color.mainCoral)
                                .frame(width: 28, height: 28)
                                .overlay {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.white)
                                }
                        }
                    }

                    // 이름 + 이메일
                    VStack(spacing: 6) {
                        Text(user?.fullName ?? "관리자")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(user?.email ?? "")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("ADMIN")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.red.opacity(0.15))
                            .foregroundStyle(.red)
                            .cornerRadius(6)
                    }

                    // 프로필 편집 버튼
                    Button {
                        editName = user?.fullName ?? ""
                        showEditProfile = true
                    } label: {
                        Text("프로필 편집")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color.mainCoral)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.mainCoral, lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 40)

                    Spacer()

                    // 로그아웃 버튼
                    Button {
                        authManager.logout()
                    } label: {
                        Text("로그아웃")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.red)
                            .cornerRadius(14)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("마이페이지")
            .task { await loadUser() }
            .sheet(isPresented: $showEditProfile) {
                editProfileSheet
            }
            .onChange(of: selectedPhotoItem) { _, newValue in
                if let item = newValue {
                    Task { await uploadProfileImage(item: item) }
                }
            }
        }
    }

    private var profilePlaceholder: some View {
        Circle()
            .fill(Color(.systemGray5))
            .frame(width: 100, height: 100)
            .overlay {
                Image(systemName: "person.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)
            }
    }

    private var editProfileSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("이름")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                    TextField("이름을 입력해주세요", text: $editName)
                        .font(.system(size: 17))
                        .padding(.bottom, 8)
                    Rectangle()
                        .fill(editName.isEmpty ? Color(.systemGray4) : Color.mainCoral)
                        .frame(height: 1.5)
                }
                .padding(.horizontal, 28)
                .padding(.top, 24)
                Spacer()
            }
            .navigationTitle("프로필 수정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { showEditProfile = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        Task { await saveProfile() }
                    }
                    .disabled(editName.isEmpty)
                    .foregroundStyle(Color.mainCoral)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func loadUser() async {
        guard let userId = authManager.currentUserId else {
            isLoading = false
            return
        }
        do {
            user = try await APIService.shared.getUser(userId: userId)
        } catch { }
        isLoading = false
    }

    private func saveProfile() async {
        guard let userId = authManager.currentUserId else { return }
        do {
            user = try await APIService.shared.updateUser(userId: userId, fullName: editName, profileImageUrl: nil)
            showEditProfile = false
        } catch { }
    }

    private func uploadProfileImage(item: PhotosPickerItem) async {
        isUploadingPhoto = true
        guard let userId = authManager.currentUserId else {
            isUploadingPhoto = false
            return
        }
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                let jpegData: Data
                if let uiImage = UIImage(data: data),
                   let converted = uiImage.jpegData(compressionQuality: 0.8) {
                    jpegData = converted
                } else {
                    jpegData = data
                }
                user = try await APIService.shared.uploadProfileImage(userId: userId, imageData: jpegData)
            }
        } catch { }
        selectedPhotoItem = nil
        isUploadingPhoto = false
    }
}
