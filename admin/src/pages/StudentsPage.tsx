import { useState, useEffect } from 'react'
import api from '../api/client'

interface DashboardData {
  totalCourses: number
  totalStudents: number
  totalLectures: number
  courses: Array<{
    courseId: number; title: string; category: string;
    studentCount: number; lectureCount: number; revenue: number
  }>
}

export function StudentsPage() {
  const [data, setData] = useState<DashboardData | null>(null)

  useEffect(() => {
    api.get('/teacher/dashboard').then(r => setData(r.data)).catch(() => {})
  }, [])

  return (
    <div>
      <div className="page-header">
        <h2>수강생 현황</h2>
        <p>내 강좌별 수강생과 진도 현황을 확인합니다</p>
      </div>

      <div className="stats-grid">
        <div className="stat-card">
          <div className="icon coral">📚</div>
          <div className="label">내 강좌</div>
          <div className="value">{data?.totalCourses ?? 0}</div>
        </div>
        <div className="stat-card">
          <div className="icon blue">🎓</div>
          <div className="label">총 수강생</div>
          <div className="value">{data?.totalStudents ?? 0}</div>
        </div>
        <div className="stat-card">
          <div className="icon green">🎬</div>
          <div className="label">총 레슨</div>
          <div className="value">{data?.totalLectures ?? 0}</div>
        </div>
      </div>

      <div className="table-card">
        <div className="table-header">
          <h3>강좌별 현황</h3>
        </div>
        <table>
          <thead>
            <tr><th>강좌명</th><th>카테고리</th><th>수강생</th><th>레슨</th></tr>
          </thead>
          <tbody>
            {data?.courses?.map(c => (
              <tr key={c.courseId}>
                <td style={{ fontWeight: 500 }}>{c.title}</td>
                <td><span className="badge badge-coral">{c.category || '-'}</span></td>
                <td>{c.studentCount}명</td>
                <td>{c.lectureCount}개</td>
              </tr>
            ))}
            {(!data?.courses || data.courses.length === 0) && (
              <tr><td colSpan={4} style={{ textAlign: 'center', color: 'var(--text-dim)' }}>등록된 강좌가 없습니다</td></tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  )
}
