package com.photolesson.backend.service;

import com.photolesson.backend.dto.user.UserDto;
import com.photolesson.backend.entity.Member;
import com.photolesson.backend.exception.CustomException;
import com.photolesson.backend.repository.MemberRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class UserService {

    private final MemberRepository memberRepository;

    public UserDto getUserById(Long userId) {
        Member member = memberRepository.findById(userId)
                .orElseThrow(() -> CustomException.notFound("사용자를 찾을 수 없습니다."));

        return UserDto.builder()
                .userId(member.getId())
                .email(member.getEmail())
                .fullName(member.getFullName())
                .profileImageUrl(member.getProfileImageUrl())
                .role(member.getRole())
                .createdAt(member.getCreatedAt())
                .build();
    }
}
