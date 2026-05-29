import { useState, useEffect } from 'react'
import api from '../api/client'

interface Course {
  courseId: number; title: string; category: string; level: string;
  instructorName: string; price: number; thumbnailUrl: string | null;
  sectionCount: number; lectureCount: number
}

export function CoursesPage() {
  const [courses, setCourses] = useState<Course[]>([])
  const [page, setPage] = useState(0)
  const [totalPages, setTotalPages] = useState(0)

  useEffect(() => {
    // 전체 강의 목록 (페이징)
    api.get('/courses', { params: { page, size: 50 } }).then(r => {
      const data = r.data
      setCourses(data.content || data)
      setTotalPages(data.totalPages || 1)
    }).catch(() => {})
  }, [page])

  return (
    <div>
      <div className="page-header">
        <h2>강의 관리</h2>
        <p>등록된 전체 강좌를 확인합니다</p>
      </div>

      <div className="table-card">
        <div className="table-header">
          <h3>강좌 목록 ({courses.length}개)</h3>
        </div>
        <table>
          <thead>
            <tr><th>강좌명</th><th>카테고리</th><th>레벨</th><th>가격</th><th>섹션</th><th>레슨</th><th>강사</th></tr>
          </thead>
          <tbody>
            {courses.map(c => (
              <tr key={c.courseId}>
                <td style={{ fontWeight: 500, maxWidth: 250, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{c.title}</td>
                <td><span className="badge badge-coral">{c.category || '-'}</span></td>
                <td><span className="badge badge-info">{c.level || '-'}</span></td>
                <td>{c.price ? `₩${c.price.toLocaleString()}` : '무료'}</td>
                <td>{c.sectionCount ?? 0}</td>
                <td>{c.lectureCount ?? 0}</td>
                <td>{c.instructorName || '-'}</td>
              </tr>
            ))}
            {courses.length === 0 && (
              <tr><td colSpan={7} style={{ textAlign: 'center', color: 'var(--text-dim)' }}>등록된 강좌가 없습니다</td></tr>
            )}
          </tbody>
        </table>

        {totalPages > 1 && (
          <div className="pagination">
            <button disabled={page === 0} onClick={() => setPage(p => p - 1)}>이전</button>
            <span className="page-info">{page + 1} / {totalPages}</span>
            <button disabled={page >= totalPages - 1} onClick={() => setPage(p => p + 1)}>다음</button>
          </div>
        )}
      </div>
    </div>
  )
}
