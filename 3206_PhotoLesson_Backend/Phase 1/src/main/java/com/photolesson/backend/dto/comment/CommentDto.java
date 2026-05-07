package com.photolesson.backend.dto.comment;

import lombok.*;

import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CommentDto {
    private Long commentId;
    private Long lectureId;
    private Long memberId;
    private String memberName;
    private String profileImageUrl;
    private String content;
    private LocalDateTime createdAt;
}
