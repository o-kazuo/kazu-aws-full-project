import { Outlet, NavLink, useNavigate } from "react-router-dom";
import { clearTokens } from "./utils/auth";

export default function App() {
  const navigate = useNavigate();

  const handleLogout = () => {
    clearTokens();
    navigate("/login");
  };

  return (
    <div style={{ minHeight: "100vh", background: "#f0f2f5" }}>
      {/* ナビゲーションバー */}
      <nav style={{
        background: "#1a1a2e", color: "white", padding: "0 24px",
        display: "flex", alignItems: "center", justifyContent: "space-between", height: "60px"
      }}>
        <span style={{ fontSize: "20px", fontWeight: "bold", color: "#e94560" }}>
          🤖 KazuAI Platform
        </span>
        <div style={{ display: "flex", gap: "24px", alignItems: "center" }}>
          <NavLink to="/dashboard" style={({ isActive }) => ({
            color: isActive ? "#e94560" : "white", textDecoration: "none", fontWeight: "500"
          })}>
            ダッシュボード
          </NavLink>
          <NavLink to="/upload" style={({ isActive }) => ({
            color: isActive ? "#e94560" : "white", textDecoration: "none", fontWeight: "500"
          })}>
            AI処理
          </NavLink>
          <button onClick={handleLogout} style={{
            background: "#e94560", color: "white", border: "none",
            padding: "6px 16px", borderRadius: "6px", cursor: "pointer"
          }}>
            ログアウト
          </button>
        </div>
      </nav>

      {/* メインコンテンツ */}
      <main style={{ maxWidth: "1100px", margin: "0 auto", padding: "32px 16px" }}>
        <Outlet />
      </main>
    </div>
  );
}
