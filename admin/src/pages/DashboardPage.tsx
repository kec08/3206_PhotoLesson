import { useState, useEffect } from 'react'
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts'
import api from '../api/client'

interface Stats {
  totalUsers: number
  totalCourses: number
  totalPayments: number
  totalRevenue: number
  todayRevenue: number
  todayPayments: number
}

export function DashboardPage() {
  const [stats, setStats] = useState<Stats | null>(null)

  useEffect(() => {
    api.get('/admin/stats').then(r => setStats(r.data)).catch(() => {})
  }, [])

  const chartData = [
    { name: '전체 매출', value: stats?.totalRevenue ?? 0 },
    { name: '오늘 매출', value: stats?.todayRevenue ?? 0 },
  ]

  return (
    <div>
      <div className="page-header">
        <h2>관리자 대시보드</h2>
        <p>PhotoLesson 서비스 현황을 한눈에 확인하세요</p>
      </div>

      <div className="stats-grid">
        <div className="stat-card">
          <div className="icon coral">👥</div>
          <div className="label">전체 사용자</div>
          <div className="value">{stats?.totalUsers?.toLocaleString() ?? '-'}</div>
        </div>
        <div className="stat-card">
          <div className="icon blue">📚</div>
          <div className="label">전체 강좌</div>
          <div className="value">{stats?.totalCourses?.toLocaleString() ?? '-'}</div>
        </div>
        <div className="stat-card">
          <div className="icon green">💳</div>
          <div className="label">결제 완료</div>
          <div className="value">{stats?.totalPayments?.toLocaleString() ?? '-'}건</div>
        </div>
        <div className="stat-card">
          <div className="icon orange">💰</div>
          <div className="label">총 매출</div>
          <div className="value" style={{ color: 'var(--coral)' }}>₩{stats?.totalRevenue?.toLocaleString() ?? '0'}</div>
        </div>
      </div>

      <div className="stats-grid" style={{ gridTemplateColumns: '1fr 1fr' }}>
        <div className="stat-card">
          <div className="label">오늘 매출</div>
          <div className="value" style={{ color: 'var(--coral)' }}>₩{stats?.todayRevenue?.toLocaleString() ?? '0'}</div>
        </div>
        <div className="stat-card">
          <div className="label">오늘 결제</div>
          <div className="value">{stats?.todayPayments ?? 0}건</div>
        </div>
      </div>

      <div className="chart-card">
        <h3>매출 현황</h3>
        <ResponsiveContainer width="100%" height={250}>
          <BarChart data={chartData}>
            <CartesianGrid strokeDasharray="3 3" stroke="#e8e8ee" />
            <XAxis dataKey="name" fontSize={13} />
            <YAxis fontSize={12} tickFormatter={(v: number) => `₩${(v/1000).toFixed(0)}k`} />
            <Tooltip formatter={(v: number) => `₩${v.toLocaleString()}`} />
            <Bar dataKey="value" fill="#FD8567" radius={[6, 6, 0, 0]} />
          </BarChart>
        </ResponsiveContainer>
      </div>
    </div>
  )
}
