package com.photolesson.backend.service;

import com.photolesson.backend.dto.comment.CommentCreateRequest;
import com.photolesson.backend.dto.comment.CommentDto;
import com.photolesson.backend.entity.Comment;
import com.photolesson.backend.entity.Lecture;
import com.photolesson.backend.entity.Member;
import com.photolesson.backend.exception.CustomException;
import com.photolesson.backend.repository.CommentRepository;
import com.photolesson.backend.repository.LectureRepository;
import com.photolesson.backend.repository.MemberRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class CommentService {

    private final CommentRepository commentRepository;
    private final MemberRepository memberRepository;
    private final LectureRepository lectureRepository;

    @Transactional
    public CommentDto createComment(Long memberId, Long lectureId, CommentCreateRequest request) {
        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> CustomException.notFound("사용자를 찾을 수 없습니다."));

        Lecture lecture = lectureRepository.findById(lectureId)
                .orElseThrow(() -> CustomException.notFound("강의를 찾을 수 없습니다."));

        Comment comment = Comment.builder()
                .member(member)
                .lecture(lecture)
                .content(request.getContent())
                .build();

        comment = commentRepository.save(comment);

        return toDto(comment);
    }

    @Transactional(readOnly = true)
    public List<CommentDto> getCommentsByLecture(Long lectureId) {
        List<Comment> comments = commentRepository.findByLectureIdOrderByCreatedAtDesc(lectureId);
        return comments.stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    @Transactional
    public void deleteComment(Long memberId, Long commentId, String role) {
        Comment comment = commentRepository.findById(commentId)
                .orElseThrow(() -> CustomException.notFound("댓글을 찾을 수 없습니다."));

        // ADMIN can delete any comment; others can only delete their own
        if (!"ADMIN".equals(role) && !comment.getMember().getId().equals(memberId)) {
            throw CustomException.unauthorized("본인의 댓글만 삭제할 수 있습니다.");
        }

        commentRepository.delete(comment);
    }

    private CommentDto toDto(Comment comment) {
        return CommentDto.builder()
                .commentId(comment.getId())
                .lectureId(comment.getLecture().getId())
                .memberId(comment.getMember().getId())
                .memberName(comment.getMember().getFullName())
                .profileImageUrl(comment.getMember().getProfileImageUrl())
                .content(comment.getContent())
                .createdAt(comment.getCreatedAt())
                .build();
    }
}
