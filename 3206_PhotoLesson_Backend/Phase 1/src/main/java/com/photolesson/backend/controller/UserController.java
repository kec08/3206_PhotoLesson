package com.photolesson.backend.controller;

import com.photolesson.backend.dto.user.UserDto;
import com.photolesson.backend.dto.user.UserUpdateRequest;
import com.photolesson.backend.service.UserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    @GetMapping("/{userId}")
    public ResponseEntity<UserDto> getUser(@PathVariable Long userId) {
        UserDto user = userService.getUserById(userId);
        return ResponseEntity.ok(user);
    }

    @PutMapping("/{userId}")
    public ResponseEntity<UserDto> updateUser(@PathVariable Long userId,
                                              @Valid @RequestBody UserUpdateRequest request) {
        UserDto user = userService.updateUser(userId, request);
        return ResponseEntity.ok(user);
    }

    @PostMapping("/{userId}/profile-image")
    public ResponseEntity<UserDto> uploadProfileImage(@PathVariable Long userId,
                                                      @RequestParam("file") MultipartFile file) {
        UserDto user = userService.uploadProfileImage(userId, file);
        return ResponseEntity.ok(user);
    }
}
