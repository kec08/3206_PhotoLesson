import { useState, useEffect } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts'
import api from '../api/client'

interface StudentDetail {
  memberId: number; fullName: string; email: string;
  completedLectures: number; totalLectures: number; progressPercent: number; enrolledAt: string
}

interface CourseStats {
  courseId: number; title: string; category: string; instructorName: string; price: number;
  totalStudents: number; totalLectures: number; avgProgress: number;
  revenue: number; salesCount: number; students: StudentDetail[]
}

export function CourseStatsPage() {
  const { courseId } = useParams()
  const navigate = useNavigate()
  const [stats, setStats] = useState<CourseStats | null>(null)
  const [loading, setLoading] = useState(true)

  const user = JSON.parse(localStorage.getItem('pl_user') || '{}')
  const isAdmin = user.role === 'ADMIN'

  useEffect(() => {
    const endpoint = isAdmin
      ? `/admin/courses/${courseId}/stats`
      : `/teacher/courses/${courseId}/stats`
    api.get(endpoint)
      .then(r => setStats(r.data))
      .catch(() => {})
      .finally(() => setLoading(false))
  }, [courseId, isAdmin])

  if (loading) return <div className="loading">로딩 중...</div>
  if (!stats) return <div className="loading">데이터를 불러올 수 없습니다</div>

  const progressData = stats.students.map(s => ({
    name: s.fullName,
    progress: s.progressPercent
  }))

  return (
    <div>
      <div className="page-header">
        <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
          <button className="btn btn-outline" onClick={() => navigate(-1)}>← 뒤로</button>
          <div>
            <h2>{stats.title}</h2>
            <p>{stats.instructorName} · {stats.category}</p>
          </div>
        </div>
      </div>

      {/* KPI 카드 */}
      <div className="stats-grid">
        <div className="stat-card">
          <div className="icon blue">🎓</div>
          <div className="label">수강생</div>
          <div className="value">{stats.totalStudents}명</div>
        </div>
        <div className="stat-card">
          <div className="icon coral">📈</div>
          <div className="label">평균 진도율</div>
          <div className="value" style={{ color: 'var(--coral)' }}>{stats.avgProgress}%</div>
        </div>
        <div className="stat-card">
          <div className="icon green">💳</div>
          <div className="label">판매</div>
          <div className="value">{stats.salesCount}건</div>
        </div>
        <div className="stat-card">
          <div className="icon orange">💰</div>
          <div className="label">매출</div>
          <div className="value" style={{ color: 'var(--coral)' }}>₩{stats.revenue.toLocaleString()}</div>
        </div>
      </div>

      {/* 수강생 진도 차트 */}
      {progressData.length > 0 && (
        <div className="chart-card">
          <h3>수강생별 진도율</h3>
          <ResponsiveContainer width="100%" height={Math.max(200, progressData.length * 50)}>
            <BarChart data={progressData} layout="vertical">
              <CartesianGrid strokeDasharray="3 3" stroke="#e8e8ee" />
              <XAxis type="number" domain={[0, 100]} fontSize={12} tickFormatter={(v: number) => `${v}%`} />
              <YAxis type="category" dataKey="name" width={100} fontSize={13} />
              <Tooltip formatter={(v: number) => `${v}%`} />
              <Bar dataKey="progress" fill="#FD8567" radius={[0, 6, 6, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>
      )}

      {/* 수강생 테이블 */}
      <div className="table-card">
        <div className="table-header">
          <h3>수강생 목록 ({stats.totalStudents}명)</h3>
        </div>
        {stats.students.length === 0 ? (
          <div style={{ textAlign: 'center', color: 'var(--text-dim)', padding: '48px 0' }}>
            <div style={{ fontSize: '2rem', marginBottom: '8px' }}>🎓</div>
            아직 수강생이 없습니다
          </div>
        ) : (
          <table>
            <thead>
              <tr><th>이름</th><th>이메일</th><th>진도율</th><th>완료 레슨</th><th>수강일</th></tr>
            </thead>
            <tbody>
              {stats.students.map(s => (
                <tr key={s.memberId}>
                  <td style={{ fontWeight: 500 }}>{s.fullName}</td>
                  <td style={{ color: 'var(--text-dim)', fontSize: '0.85rem' }}>{s.email}</td>
                  <td>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                      <div style={{ width: '80px', height: '8px', background: 'var(--border)', borderRadius: '4px', overflow: 'hidden' }}>
                        <div style={{
                          width: `${s.progressPercent}%`, height: '100%',
                          background: s.progressPercent >= 80 ? 'var(--success)' : s.progressPercent >= 40 ? 'var(--warning)' : 'var(--coral)',
                          borderRadius: '4px', transition: 'width 0.3s'
                        }} />
                      </div>
                      <span style={{ fontWeight: 600, fontSize: '0.9rem' }}>{s.progressPercent}%</span>
                    </div>
                  </td>
                  <td>{s.completedLectures} / {s.totalLectures}</td>
                  <td style={{ fontSize: '0.85rem', color: 'var(--text-dim)' }}>
                    {s.enrolledAt ? new Date(s.enrolledAt).toLocaleDateString('ko-KR') : '-'}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  )
}
