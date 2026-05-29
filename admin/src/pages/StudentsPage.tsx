import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import api from '../api/client'

interface CourseDashItem {
  courseId: number; title: string; category: string; instructorName: string;
  price: number; studentCount: number; lectureCount: number; revenue: number
}

export function StudentsPage() {
  const [courses, setCourses] = useState<CourseDashItem[]>([])
  const [loading, setLoading] = useState(true)
  const navigate = useNavigate()

  const user = JSON.parse(localStorage.getItem('pl_user') || '{}')
  const isAdmin = user.role === 'ADMIN'

  useEffect(() => {
    if (isAdmin) {
      api.get('/admin/courses/dashboard').then(r => setCourses(r.data)).catch(() => {})
        .finally(() => setLoading(false))
    } else {
      // 강사: teacher/revenue에서 매출 포함된 데이터 가져오기
      Promise.all([
        api.get('/teacher/dashboard'),
        api.get('/teacher/revenue')
      ]).then(([dashRes, revRes]) => {
        const dashCourses = dashRes.data.courses || []
        const revCourses = revRes.data.courses || []
        const revMap = new Map(revCourses.map((r: any) => [r.courseId, r]))

        setCourses(dashCourses.map((c: any) => {
          const rev = revMap.get(c.courseId)
          return {
            ...c,
            instructorName: user.fullName,
            price: rev?.price || 0,
            revenue: rev?.revenue || 0
          }
        }))
      }).catch(() => {}).finally(() => setLoading(false))
    }
  }, [isAdmin])

  const totalStudents = courses.reduce((s, c) => s + c.studentCount, 0)
  const totalLectures = courses.reduce((s, c) => s + c.lectureCount, 0)
  const totalRevenue = courses.reduce((s, c) => s + (c.revenue || 0), 0)

  return (
    <div>
      <div className="page-header">
        <h2>수강생 현황</h2>
        <p>{isAdmin ? '전체 강좌의 수강생 현황을 확인합니다' : '내 강좌별 수강생 현황을 확인합니다'}</p>
      </div>

      <div className="stats-grid">
        <div className="stat-card">
          <div className="icon coral">📚</div>
          <div className="label">{isAdmin ? '전체 강좌' : '내 강좌'}</div>
          <div className="value">{courses.length}</div>
        </div>
        <div className="stat-card">
          <div className="icon blue">🎓</div>
          <div className="label">총 수강생</div>
          <div className="value">{totalStudents}</div>
        </div>
        <div className="stat-card">
          <div className="icon green">🎬</div>
          <div className="label">총 레슨</div>
          <div className="value">{totalLectures}</div>
        </div>
        <div className="stat-card">
          <div className="icon orange">💰</div>
          <div className="label">총 매출</div>
          <div className="value" style={{ color: 'var(--coral)' }}>₩{totalRevenue.toLocaleString()}</div>
        </div>
      </div>

      <div className="table-card">
        <div className="table-header">
          <h3>강좌별 현황</h3>
        </div>
        <table>
          <thead>
            <tr><th>강좌명</th><th>강사</th><th>수강생</th><th>레슨</th><th>매출</th><th></th></tr>
          </thead>
          <tbody>
            {courses.map(c => (
              <tr key={c.courseId} onClick={() => navigate(`/courses/${c.courseId}/stats`)} style={{ cursor: 'pointer' }}>
                <td style={{ fontWeight: 500 }}>{c.title}</td>
                <td style={{ color: 'var(--text-dim)' }}>{c.instructorName || '-'}</td>
                <td>{c.studentCount}명</td>
                <td>{c.lectureCount}개</td>
                <td style={{ color: 'var(--coral)', fontWeight: 600 }}>₩{(c.revenue || 0).toLocaleString()}</td>
                <td style={{ color: 'var(--text-dim)' }}>상세 →</td>
              </tr>
            ))}
            {courses.length === 0 && !loading && (
              <tr><td colSpan={6} style={{ textAlign: 'center', color: 'var(--text-dim)' }}>등록된 강좌가 없습니다</td></tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  )
}
