package com.photolesson.backend.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "lectures")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Lecture {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "section_id", nullable = false)
    private Section section;

    @Column(length = 255, nullable = false)
    private String title;

    @Column(name = "video_url", length = 500)
    private String videoUrl;

    @Column(name = "play_time")
    private Integer playTime;

    @Column(name = "sort_order")
    private Integer sortOrder;
}
