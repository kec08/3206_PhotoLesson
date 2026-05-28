import { useState, useEffect, useCallback } from 'react'
import api from '../api/client'

interface Payment {
  paymentId: number; memberId: number; memberName: string; courseId: number; courseTitle: string;
  orderId: string; amount: number; status: string; method: string | null; createdAt: string
}

export function PaymentsPage() {
  const [payments, setPayments] = useState<{ content: Payment[]; totalElements: number; totalPages: number } | null>(null)
  const [page, setPage] = useState(0)

  const fetchPayments = useCallback(async () => {
    try {
      const res = await api.get('/admin/payments', { params: { page, size: 20 } })
      setPayments(res.data)
    } catch { /* */ }
  }, [page])

  useEffect(() => { fetchPayments() }, [fetchPayments])

  const refund = async (paymentId: number) => {
    if (!confirm('정말 환불하시겠습니까?')) return
    try {
      await api.post(`/admin/payments/${paymentId}/refund`)
      fetchPayments()
    } catch { /* */ }
  }

  const statusBadge = (s: string) => {
    const map: Record<string, string> = { SUCCESS: 'badge-success', FAILED: 'badge-danger', PENDING: 'badge-warning', REFUNDED: 'badge-info' }
    return <span className={`badge ${map[s] || ''}`}>{s}</span>
  }

  return (
    <div>
      <div className="page-header">
        <h2>결제 관리</h2>
        <p>결제 내역을 조회하고 환불을 처리합니다</p>
      </div>

      <div className="table-card">
        <div className="table-header">
          <h3>결제 내역 ({payments?.totalElements ?? 0}건)</h3>
        </div>
        <table>
          <thead>
            <tr><th>수강생</th><th>강좌</th><th>금액</th><th>상태</th><th>결제수단</th><th>일시</th><th>액션</th></tr>
          </thead>
          <tbody>
            {payments?.content?.map(p => (
              <tr key={p.paymentId}>
                <td>{p.memberName || '-'}</td>
                <td style={{ maxWidth: 200, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{p.courseTitle || '-'}</td>
                <td style={{ fontWeight: 600 }}>₩{p.amount.toLocaleString()}</td>
                <td>{statusBadge(p.status)}</td>
                <td>{p.method || '-'}</td>
                <td>{p.createdAt ? new Date(p.createdAt).toLocaleString('ko-KR') : '-'}</td>
                <td>
                  {p.status === 'SUCCESS' && (
                    <button className="btn btn-sm btn-danger" onClick={() => refund(p.paymentId)}>환불</button>
                  )}
                </td>
              </tr>
            ))}
            {(!payments?.content || payments.content.length === 0) && (
              <tr><td colSpan={7} style={{ textAlign: 'center', color: 'var(--text-dim)' }}>결제 내역이 없습니다</td></tr>
            )}
          </tbody>
        </table>

        {payments && payments.totalPages > 1 && (
          <div className="pagination">
            <button disabled={page === 0} onClick={() => setPage(p => p - 1)}>이전</button>
            <span className="page-info">{page + 1} / {payments.totalPages}</span>
            <button disabled={page >= payments.totalPages - 1} onClick={() => setPage(p => p + 1)}>다음</button>
          </div>
        )}
      </div>
    </div>
  )
}
