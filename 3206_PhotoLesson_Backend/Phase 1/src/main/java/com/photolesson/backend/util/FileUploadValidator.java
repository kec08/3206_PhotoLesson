package com.photolesson.backend.util;

import com.photolesson.backend.exception.CustomException;
import org.springframework.web.multipart.MultipartFile;

import java.util.Set;

public class FileUploadValidator {

    private static final Set<String> ALLOWED_EXTENSIONS = Set.of(
            "jpg", "jpeg", "png", "gif", "webp"
    );

    private static final Set<String> ALLOWED_CONTENT_TYPES = Set.of(
            "image/jpeg", "image/png", "image/gif", "image/webp"
    );

    public static void validateImageFile(MultipartFile file) {
        if (file.isEmpty()) {
            throw CustomException.badRequest("파일이 비어있습니다.");
        }

        String originalFilename = file.getOriginalFilename();
        if (originalFilename == null || !originalFilename.contains(".")) {
            throw CustomException.badRequest("파일 확장자가 필요합니다.");
        }

        String extension = originalFilename.substring(
                originalFilename.lastIndexOf(".") + 1).toLowerCase();
        if (!ALLOWED_EXTENSIONS.contains(extension)) {
            throw CustomException.badRequest(
                    "허용되지 않는 파일 형식입니다. (jpg, jpeg, png, gif, webp만 가능)");
        }

        String contentType = file.getContentType();
        if (contentType == null || !ALLOWED_CONTENT_TYPES.contains(contentType)) {
            throw CustomException.badRequest("유효하지 않은 이미지 파일입니다.");
        }
    }
}
