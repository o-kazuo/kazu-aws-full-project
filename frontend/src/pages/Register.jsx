import { useState } from "react";
import { useNavigate, Link } from "react-router-dom";
import { authApi } from "../utils/api";

export default function Register() {
  const navigate = useNavigate();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  const handleRegister = async (e) => {
    e.preventDefault();
    setError("");
    setLoading(true);
    try {
      await authApi.register(email, password);
      navigate("/login");
    } catch (err) {
      setError(err.response?.data?.detail || "登録に失敗しました");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{
      minHeight: "100vh", background: "#1a1a2e",
      display: "flex", alignItems: "center", justifyContent: "center"
    }}>
      <div style={{
        background: "white", borderRadius: "12px", padding: "40px",
        width: "100%", maxWidth: "400px", boxShadow: "0 4px 24px rgba(0,0,0,0.3)"
      }}>
        <h1 style={{ textAlign: "center", color: "#1a1a2e", marginBottom: "8px" }}>
          🤖 KazuAI Platform
        </h1>
        <p style={{ textAlign: "center", color: "#666", marginBottom: "32px" }}>
          新規登録
        </p>

        {error && (
          <div style={{
            background: "#fff0f0", border: "1px solid #e94560", color: "#e94560",
            padding: "10px 14px", borderRadius: "6px", marginBottom: "16px", fontSize: "14px"
          }}>
            {error}
          </div>
        )}

        <form onSubmit={handleRegister}>
          <div style={{ marginBottom: "16px" }}>
            <label style={{ display: "block", marginBottom: "6px", fontWeight: "500", fontSize: "14px" }}>
              メールアドレス
            </label>
            <input
              type="email" value={email} onChange={(e) => setEmail(e.target.value)}
              required placeholder="example@email.com"
              style={{
                width: "100%", padding: "10px 12px", border: "1px solid #ddd",
                borderRadius: "6px", fontSize: "14px", boxSizing: "border-box"
              }}
            />
          </div>
          <div style={{ marginBottom: "8px" }}>
            <label style={{ display: "block", marginBottom: "6px", fontWeight: "500", fontSize: "14px" }}>
              パスワード
            </label>
            <input
              type="password" value={password} onChange={(e) => setPassword(e.target.value)}
              required placeholder="8文字以上・大文字・数字・記号を含む"
              style={{
                width: "100%", padding: "10px 12px", border: "1px solid #ddd",
                borderRadius: "6px", fontSize: "14px", boxSizing: "border-box"
              }}
            />
          </div>
          <p style={{ fontSize: "12px", color: "#999", marginBottom: "24px" }}>
            ※ Cognitoのパスワードポリシー：8文字以上・大文字・小文字・数字・記号を含む
          </p>
          <button type="submit" disabled={loading} style={{
            width: "100%", padding: "12px", background: loading ? "#ccc" : "#e94560",
            color: "white", border: "none", borderRadius: "6px",
            fontSize: "16px", fontWeight: "bold", cursor: loading ? "not-allowed" : "pointer"
          }}>
            {loading ? "登録中..." : "アカウント作成"}
          </button>
        </form>

        <p style={{ textAlign: "center", marginTop: "20px", fontSize: "14px", color: "#666" }}>
          すでにアカウントをお持ちの方は{" "}
          <Link to="/login" style={{ color: "#e94560" }}>ログイン</Link>
        </p>
      </div>
    </div>
  );
}
