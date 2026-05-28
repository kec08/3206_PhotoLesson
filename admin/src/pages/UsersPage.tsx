import { useState, useEffect, useCallback } from 'react'
import api from '../api/client'

interface User {
  userId: number; email: string; fullName: string; role: string; profileImageUrl: string | null; createdAt: string
}

export function UsersPage() {
  const [users, setUsers] = useState<User[]>([])
  const [search, setSearch] = useState('')

  const fetchUsers = useCallback(async () => {
    try {
      const res = await api.get('/admin/users')
      setUsers(res.data)
    } catch { /* */ }
  }, [])

  useEffect(() => { fetchUsers() }, [fetchUsers])

  const changeRole = async (userId: number, role: string) => {
    await api.patch(`/admin/users/${userId}/role`, { role })
    fetchUsers()
  }

  const deleteUser = async (userId: number) => {
    if (!confirm('정말 삭제하시겠습니까?')) return
    await api.delete(`/admin/users/${userId}`)
    fetchUsers()
  }

  const filtered = users.filter(u =>
    u.fullName?.toLowerCase().includes(search.toLowerCase()) ||
    u.email.toLowerCase().includes(search.toLowerCase())
  )

  const roleBadge = (role: string) => {
    const map: Record<string, string> = { ADMIN: 'badge-coral', TEACHER: 'badge-info', STUDENT: 'badge-success' }
    return <span className={`badge ${map[role] || 'badge-info'}`}>{role}</span>
  }

  return (
    <div>
      <div className="page-header">
        <h2>사용자 관리</h2>
        <p>전체 사용자를 조회하고 권한을 관리합니다</p>
      </div>

      <div className="table-card">
        <div className="table-header">
          <h3>사용자 목록 ({filtered.length}명)</h3>
          <input className="search-input" placeholder="이름 또는 이메일 검색..." value={search} onChange={e => setSearch(e.target.value)} />
        </div>
        <table>
          <thead>
            <tr><th>이름</th><th>이메일</th><th>역할</th><th>가입일</th><th>액션</th></tr>
          </thead>
          <tbody>
            {filtered.map(u => (
              <tr key={u.userId}>
                <td style={{ fontWeight: 500 }}>{u.fullName || '-'}</td>
                <td>{u.email}</td>
                <td>{roleBadge(u.role)}</td>
                <td>{u.createdAt ? new Date(u.createdAt).toLocaleDateString('ko-KR') : '-'}</td>
                <td>
                  <select value={u.role} onChange={e => changeRole(u.userId, e.target.value)}
                    style={{ padding: '4px 8px', borderRadius: 6, border: '1px solid var(--border)', marginRight: 8, fontSize: '0.8rem' }}>
                    <option value="STUDENT">STUDENT</option>
                    <option value="TEACHER">TEACHER</option>
                    <option value="ADMIN">ADMIN</option>
                  </select>
                  <button className="btn btn-sm btn-danger" onClick={() => deleteUser(u.userId)}>삭제</button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}
