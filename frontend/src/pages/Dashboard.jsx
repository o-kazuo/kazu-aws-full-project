import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { aiApi } from "../utils/api";

const SERVICE_LABELS = {
  rekognition: "🖼️ 画像分析",
  transcribe: "🎙️ 音声認識",
  translate: "🌐 翻訳",
  comprehend: "📊 テキスト分析",
  textract: "📄 文書抽出",
  bedrock: "🤖 生成AI",
  macie: "🔒 PII検出",
};

const STATUS_COLORS = {
  completed: "#22c55e",
  processing: "#f59e0b",
  failed: "#ef4444",
};

export default function Dashboard() {
  const navigate = useNavigate();
  const [usage, setUsage] = useState(null);
  const [results, setResults] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchData = async () => {
      try {
        const [usageRes, resultsRes] = await Promise.all([
          aiApi.getUsage(),
          aiApi.getResults(10),
        ]);
        setUsage(usageRes.data);
        setResults(resultsRes.data.results);
      } catch (err) {
        console.error(err);
      } finally {
        setLoading(false);
      }
    };
    fetchData();
  }, []);

  if (loading) {
    return <div style={{ textAlign: "center", padding: "60px", color: "#666" }}>読み込み中...</div>;
  }

  const usagePercent = usage?.limit > 0
    ? Math.min(100, Math.round((usage.current / usage.limit) * 100))
    : 0;

  return (
    <div>
      <h2 style={{ marginBottom: "24px", color: "#1a1a2e" }}>ダッシュボード</h2>

      {/* 使用回数カード */}
      <div style={{
        display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(280px, 1fr))",
        gap: "20px", marginBottom: "32px"
      }}>
        <div style={{
          background: "white", borderRadius: "12px", padding: "24px",
          boxShadow: "0 2px 8px rgba(0,0,0,0.08)"
        }}>
          <p style={{ color: "#666", fontSize: "14px", marginBottom: "8px" }}>今月の使用回数</p>
          <p style={{ fontSize: "36px", fontWeight: "bold", color: "#1a1a2e", marginBottom: "12px" }}>
            {usage?.current ?? 0}
            <span style={{ fontSize: "16px", color: "#666", fontWeight: "normal" }}>
              {usage?.plan === "free" ? ` / ${usage?.limit}回` : " / 無制限"}
            </span>
          </p>
          {usage?.plan === "free" && (
            <>
              <div style={{ background: "#f0f2f5", borderRadius: "99px", height: "8px", marginBottom: "8px" }}>
                <div style={{
                  background: usagePercent >= 80 ? "#ef4444" : "#e94560",
                  width: `${usagePercent}%`, height: "100%", borderRadius: "99px",
                  transition: "width 0.3s"
                }} />
              </div>
              <p style={{ fontSize: "12px", color: "#999" }}>
                残り {usage?.remaining ?? 0} 回（Freeプラン）
              </p>
            </>
          )}
          {usage?.plan === "premium" && (
            <span style={{
              background: "#fef3c7", color: "#d97706", padding: "4px 12px",
              borderRadius: "99px", fontSize: "12px", fontWeight: "bold"
            }}>
              ⭐ Premiumプラン
            </span>
          )}
        </div>

        <div style={{
          background: "white", borderRadius: "12px", padding: "24px",
          boxShadow: "0 2px 8px rgba(0,0,0,0.08)"
        }}>
          <p style={{ color: "#666", fontSize: "14px", marginBottom: "8px" }}>アカウント</p>
          <p style={{ fontSize: "16px", fontWeight: "500", color: "#1a1a2e", marginBottom: "16px" }}>
            {usage?.user}
          </p>
          <button onClick={() => navigate("/upload")} style={{
            background: "#e94560", color: "white", border: "none",
            padding: "10px 20px", borderRadius: "6px", cursor: "pointer",
            fontWeight: "bold", fontSize: "14px"
          }}>
            AI処理を開始 →
          </button>
        </div>
      </div>

      {/* 最近の処理履歴 */}
      <div style={{
        background: "white", borderRadius: "12px", padding: "24px",
        boxShadow: "0 2px 8px rgba(0,0,0,0.08)"
      }}>
        <h3 style={{ marginBottom: "16px", color: "#1a1a2e" }}>最近の処理履歴</h3>
        {results.length === 0 ? (
          <p style={{ color: "#999", textAlign: "center", padding: "32px" }}>
            まだ処理履歴がありません。AI処理を試してみましょう！
          </p>
        ) : (
          <table style={{ width: "100%", borderCollapse: "collapse" }}>
            <thead>
              <tr style={{ borderBottom: "2px solid #f0f2f5" }}>
                {["サービス", "ステータス", "処理時間", "日時"].map((h) => (
                  <th key={h} style={{
                    textAlign: "left", padding: "8px 12px",
                    fontSize: "12px", color: "#999", fontWeight: "600"
                  }}>{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {results.map((r) => (
                <tr key={r.id} style={{ borderBottom: "1px solid #f0f2f5" }}>
                  <td style={{ padding: "12px" }}>
                    {SERVICE_LABELS[r.service] || r.service}
                  </td>
                  <td style={{ padding: "12px" }}>
                    <span style={{
                      color: STATUS_COLORS[r.status] || "#666",
                      fontWeight: "500", fontSize: "14px"
                    }}>
                      ● {r.status}
                    </span>
                  </td>
                  <td style={{ padding: "12px", color: "#666", fontSize: "14px" }}>
                    {r.processing_time ? `${r.processing_time}秒` : "-"}
                  </td>
                  <td style={{ padding: "12px", color: "#666", fontSize: "13px" }}>
                    {r.created_at ? new Date(r.created_at).toLocaleString("ja-JP") : "-"}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}
