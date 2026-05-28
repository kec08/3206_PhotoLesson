import { useState, type FormEvent } from 'react'
import api from '../api/client'

interface Props {
  onLogin: (user: { userId: number; email: string; fullName: string; role: string }, token: string) => void
}

export function LoginPage({ onLogin }: Props) {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault()
    setError('')
    setLoading(true)
    try {
      const res = await api.post('/auth/login', { email, password })
      const { userId, accessToken } = res.data

      // JWT payload에서 role 추출
      const payload = JSON.parse(atob(accessToken.split('.')[1]))
      const role = payload.role as string

      if (role !== 'TEACHER' && role !== 'ADMIN') {
        setError('강사 또는 관리자 계정만 접근 가능합니다.')
        return
      }

      // user 정보 조회
      localStorage.setItem('pl_token', accessToken)
      const userRes = await api.get(`/users/${userId}`)
      const fullName = userRes.data.fullName || email

      onLogin({ userId, email, fullName, role }, accessToken)
    } catch {
      setError('이메일 또는 비밀번호가 올바르지 않습니다.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="login-page">
      <form className="login-card" onSubmit={handleSubmit}>
        <h1>PhotoLesson</h1>
        <p className="sub">강사 · 관리자 대시보드</p>
        {error && <div className="error-msg">{error}</div>}
        <div className="form-group">
          <label>이메일</label>
          <input type="email" value={email} onChange={e => setEmail(e.target.value)} required placeholder="email@photolesson.com" />
        </div>
        <div className="form-group">
          <label>비밀번호</label>
          <input type="password" value={password} onChange={e => setPassword(e.target.value)} required placeholder="비밀번호" />
        </div>
        <button type="submit" className="btn btn-coral" style={{ width: '100%', padding: '12px', fontSize: '1rem', marginTop: '8px' }} disabled={loading}>
          {loading ? '로그인 중...' : '로그인'}
        </button>
      </form>
    </div>
  )
}
