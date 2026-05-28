import { NavLink } from 'react-router-dom'
import type { ReactNode } from 'react'

interface Props {
  user: { fullName: string; role: string }
  isAdmin: boolean
  onLogout: () => void
  children: ReactNode
}

export function Layout({ user, isAdmin, onLogout, children }: Props) {
  return (
    <div className="layout">
      <aside className="sidebar">
        <div className="sidebar-logo">
          PhotoLesson <span>{isAdmin ? 'ADMIN' : 'TEACHER'}</span>
        </div>

        <nav className="sidebar-nav">
          {isAdmin && (
            <>
              <div className="sidebar-section-label">관리자</div>
              <NavLink to="/dashboard" className={({ isActive }) => isActive ? 'active' : ''}>
                <span>📊</span> <span>대시보드</span>
              </NavLink>
              <NavLink to="/users" className={({ isActive }) => isActive ? 'active' : ''}>
                <span>👥</span> <span>사용자 관리</span>
              </NavLink>
              <NavLink to="/payments" className={({ isActive }) => isActive ? 'active' : ''}>
                <span>💳</span> <span>결제 관리</span>
              </NavLink>
            </>
          )}

          <div className="sidebar-section-label">강사</div>
          <NavLink to="/courses" className={({ isActive }) => isActive ? 'active' : ''}>
            <span>📚</span> <span>강의 관리</span>
          </NavLink>
          <NavLink to="/students" className={({ isActive }) => isActive ? 'active' : ''}>
            <span>🎓</span> <span>수강생 현황</span>
          </NavLink>
          <NavLink to="/revenue" className={({ isActive }) => isActive ? 'active' : ''}>
            <span>💰</span> <span>매출 현황</span>
          </NavLink>
        </nav>

        <div className="sidebar-footer">
          <div className="user-info">
            <div className="user-name">{user.fullName}</div>
            <div className="user-role">{user.role}</div>
          </div>
          <button className="btn btn-sm btn-outline" style={{ color: '#fff', borderColor: 'rgba(255,255,255,0.2)' }} onClick={onLogout}>
            로그아웃
          </button>
        </div>
      </aside>

      <main className="main">{children}</main>
    </div>
  )
}
