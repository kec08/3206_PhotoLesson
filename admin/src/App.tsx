import { useState, useEffect } from 'react'
import { Routes, Route, Navigate } from 'react-router-dom'
import { Layout } from './components/Layout'
import { LoginPage } from './pages/LoginPage'
import { DashboardPage } from './pages/DashboardPage'
import { UsersPage } from './pages/UsersPage'
import { CoursesPage } from './pages/CoursesPage'
import { PaymentsPage } from './pages/PaymentsPage'
import { RevenuePage } from './pages/RevenuePage'
import { StudentsPage } from './pages/StudentsPage'

interface User { userId: number; email: string; fullName: string; role: string }

export function App() {
  const [user, setUser] = useState<User | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const token = localStorage.getItem('pl_token')
    const userData = localStorage.getItem('pl_user')
    if (token && userData) setUser(JSON.parse(userData))
    setLoading(false)
  }, [])

  const login = (u: User, token: string) => {
    localStorage.setItem('pl_token', token)
    localStorage.setItem('pl_user', JSON.stringify(u))
    setUser(u)
  }

  const logout = () => {
    localStorage.removeItem('pl_token')
    localStorage.removeItem('pl_user')
    setUser(null)
  }

  if (loading) return <div className="loading">로딩 중...</div>

  if (!user) return (
    <Routes>
      <Route path="/login" element={<LoginPage onLogin={login} />} />
      <Route path="*" element={<Navigate to="/login" />} />
    </Routes>
  )

  const isAdmin = user.role === 'ADMIN'
  const isTeacher = user.role === 'TEACHER' || isAdmin

  if (!isTeacher) return (
    <div className="login-page">
      <div className="login-card">
        <h1>접근 불가</h1>
        <p className="sub">강사 또는 관리자 계정으로 로그인해주세요</p>
        <button className="btn btn-coral" style={{ width: '100%' }} onClick={logout}>다시 로그인</button>
      </div>
    </div>
  )

  return (
    <Layout user={user} isAdmin={isAdmin} onLogout={logout}>
      <Routes>
        <Route path="/" element={isAdmin ? <DashboardPage /> : <RevenuePage />} />
        <Route path="/courses" element={<CoursesPage />} />
        <Route path="/students" element={<StudentsPage />} />
        <Route path="/revenue" element={<RevenuePage />} />
        {isAdmin && <Route path="/users" element={<UsersPage />} />}
        {isAdmin && <Route path="/payments" element={<PaymentsPage />} />}
        {isAdmin && <Route path="/dashboard" element={<DashboardPage />} />}
        <Route path="*" element={<Navigate to="/" />} />
      </Routes>
    </Layout>
  )
}
