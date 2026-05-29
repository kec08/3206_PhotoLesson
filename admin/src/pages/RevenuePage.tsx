import { useState, useEffect } from 'react'
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts'
import api from '../api/client'

interface CourseRevenue {
  courseId: number; title: string; price: number; revenue: number; salesCount: number
}

export function RevenuePage() {
  const [totalRevenue, setTotalRevenue] = useState(0)
  const [courses, setCourses] = useState<CourseRevenue[]>([])
  const user = JSON.parse(localStorage.getItem('pl_user') || '{}')
  const isAdmin = user.role === 'ADMIN'

  useEffect(() => {
    if (isAdmin) {
      // 관리자: 전체 매출 (admin/stats + 전체 결제 내역에서 집계)
      Promise.all([
        api.get('/admin/stats'),
        api.get('/admin/payments', { params: { page: 0, size: 1000 } })
      ]).then(([statsRes, paymentsRes]) => {
        setTotalRevenue(statsRes.data.totalRevenue || 0)

        // 결제 내역에서 강좌별 매출 집계
        const payments = paymentsRes.data.content || []
        const courseMap = new Map<number, CourseRevenue>()

        for (const p of payments) {
          if (p.status !== 'SUCCESS') continue
          const existing = courseMap.get(p.courseId)
          if (existing) {
            existing.revenue += p.amount
            existing.salesCount += 1
          } else {
            courseMap.set(p.courseId, {
              courseId: p.courseId,
              title: p.courseTitle || `강좌 #${p.courseId}`,
              price: p.amount,
              revenue: p.amount,
              salesCount: 1
            })
          }
        }

        setCourses(Array.from(courseMap.values()))
      }).catch(() => {})
    } else {
      // 강사: 본인 매출
      api.get('/teacher/revenue').then(r => {
        setTotalRevenue(r.data.totalRevenue)
        setCourses(r.data.courses || [])
      }).catch(() => {})
    }
  }, [isAdmin])

  return (
    <div>
      <div className="page-header">
        <h2>매출 현황</h2>
        <p>{isAdmin ? '전체 서비스 매출을 확인합니다' : '강좌별 매출과 판매 현황을 확인합니다'}</p>
      </div>

      <div className="stats-grid" style={{ gridTemplateColumns: '1fr' }}>
        <div className="stat-card">
          <div className="label">{isAdmin ? '전체 매출' : '내 매출'}</div>
          <div className="value" style={{ color: 'var(--coral)', fontSize: '2.2rem' }}>
            ₩{totalRevenue.toLocaleString()}
          </div>
        </div>
      </div>

      {courses.length > 0 && (
        <div className="chart-card">
          <h3>강좌별 매출</h3>
          <ResponsiveContainer width="100%" height={300}>
            <BarChart data={courses} layout="vertical">
              <CartesianGrid strokeDasharray="3 3" stroke="#e8e8ee" />
              <XAxis type="number" fontSize={12} tickFormatter={(v: number) => `₩${(v/1000).toFixed(0)}k`} />
              <YAxis type="category" dataKey="title" width={180} fontSize={12} />
              <Tooltip formatter={(v: number) => `₩${v.toLocaleString()}`} />
              <Bar dataKey="revenue" fill="#FD8567" radius={[0, 6, 6, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>
      )}

      <div className="table-card">
        <div className="table-header">
          <h3>강좌별 상세</h3>
        </div>
        <table>
          <thead>
            <tr><th>강좌명</th><th>가격</th><th>판매 수</th><th>매출</th></tr>
          </thead>
          <tbody>
            {courses.map(c => (
              <tr key={c.courseId}>
                <td style={{ fontWeight: 500 }}>{c.title}</td>
                <td>₩{c.price.toLocaleString()}</td>
                <td>{c.salesCount}건</td>
                <td style={{ fontWeight: 600, color: 'var(--coral)' }}>₩{c.revenue.toLocaleString()}</td>
              </tr>
            ))}
            {courses.length === 0 && (
              <tr><td colSpan={4} style={{ textAlign: 'center', color: 'var(--text-dim)' }}>매출 데이터가 없습니다</td></tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  )
}
