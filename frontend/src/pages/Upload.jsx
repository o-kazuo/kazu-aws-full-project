import { useState } from "react";
import { aiApi } from "../utils/api";

const SERVICES = [
  { id: "rekognition", label: "🖼️ 画像分析", desc: "画像からラベル・顔を検出", type: "file", accept: "image/*" },
  { id: "transcribe", label: "🎙️ 音声認識", desc: "音声ファイルをテキストに変換", type: "file", accept: "audio/*,video/mp4" },
  { id: "textract", label: "📄 文書抽出", desc: "PDF・画像からテキスト抽出", type: "file", accept: "image/*,application/pdf" },
  { id: "translate", label: "🌐 翻訳", desc: "テキストを多言語に翻訳", type: "text" },
  { id: "comprehend", label: "📊 テキスト分析", desc: "感情・キーフレーズ・エンティティ検出", type: "text" },
  { id: "bedrock", label: "🤖 生成AI", desc: "Claude 3 Haikuでテキスト生成", type: "text" },
];

export default function Upload() {
  const [selectedService, setSelectedService] = useState("rekognition");
  const [file, setFile] = useState(null);
  const [text, setText] = useState("");
  const [targetLang, setTargetLang] = useState("en");
  const [analysisType, setAnalysisType] = useState("labels");
  const [loading, setLoading] = useState(false);
  const [result, setResult] = useState(null);
  const [error, setError] = useState("");

  const service = SERVICES.find((s) => s.id === selectedService);

  const handleSubmit = async () => {
    setError("");
    setResult(null);
    setLoading(true);

    try {
      let res;
      switch (selectedService) {
        case "rekognition":
          res = await aiApi.upload(file, analysisType);
          break;
        case "transcribe":
          res = await aiApi.transcribe(file);
          break;
        case "textract":
          res = await aiApi.textract(file);
          break;
        case "translate":
          res = await aiApi.translate(text, targetLang);
          break;
        case "comprehend":
          res = await aiApi.comprehend(text);
          break;
        case "bedrock":
          res = await aiApi.bedrock(text);
          break;
        default:
          throw new Error("不明なサービスです");
      }
      setResult(res.data);
    } catch (err) {
      if (err.response?.status === 429) {
        setError("月間使用回数の上限に達しました。Premiumにアップグレードしてください。");
      } else {
        setError(err.response?.data?.detail || "処理に失敗しました");
      }
    } finally {
      setLoading(false);
    }
  };

  const canSubmit = service?.type === "file" ? !!file : !!text.trim();

  return (
    <div>
      <h2 style={{ marginBottom: "24px", color: "#1a1a2e" }}>AI処理</h2>

      <div style={{ display: "grid", gridTemplateColumns: "280px 1fr", gap: "24px" }}>
        {/* サービス選択 */}
        <div style={{
          background: "white", borderRadius: "12px", padding: "16px",
          boxShadow: "0 2px 8px rgba(0,0,0,0.08)", height: "fit-content"
        }}>
          <p style={{ fontWeight: "600", marginBottom: "12px", color: "#1a1a2e" }}>サービスを選択</p>
          {SERVICES.map((s) => (
            <div key={s.id} onClick={() => { setSelectedService(s.id); setResult(null); setError(""); }}
              style={{
                padding: "12px", borderRadius: "8px", marginBottom: "8px", cursor: "pointer",
                background: selectedService === s.id ? "#fff0f3" : "transparent",
                border: selectedService === s.id ? "1px solid #e94560" : "1px solid transparent",
              }}>
              <p style={{ fontWeight: "500", fontSize: "14px", color: selectedService === s.id ? "#e94560" : "#1a1a2e" }}>
                {s.label}
              </p>
              <p style={{ fontSize: "12px", color: "#999", marginTop: "2px" }}>{s.desc}</p>
            </div>
          ))}
        </div>

        {/* 入力エリア */}
        <div style={{
          background: "white", borderRadius: "12px", padding: "24px",
          boxShadow: "0 2px 8px rgba(0,0,0,0.08)"
        }}>
          <h3 style={{ marginBottom: "20px", color: "#1a1a2e" }}>{service?.label}</h3>

          {/* ファイル入力 */}
          {service?.type === "file" && (
            <div>
              {selectedService === "rekognition" && (
                <div style={{ marginBottom: "16px" }}>
                  <label style={{ fontSize: "14px", fontWeight: "500", marginBottom: "8px", display: "block" }}>
                    分析タイプ
                  </label>
                  <select value={analysisType} onChange={(e) => setAnalysisType(e.target.value)}
                    style={{ padding: "8px 12px", borderRadius: "6px", border: "1px solid #ddd", fontSize: "14px" }}>
                    <option value="labels">ラベル検出（物体・シーン）</option>
                    <option value="faces">顔検出（感情・年齢）</option>
                  </select>
                </div>
              )}
              <div style={{
                border: "2px dashed #ddd", borderRadius: "8px", padding: "40px",
                textAlign: "center", cursor: "pointer",
                background: file ? "#f0fff4" : "#fafafa"
              }} onClick={() => document.getElementById("file-input").click()}>
                <input id="file-input" type="file" accept={service.accept}
                  style={{ display: "none" }} onChange={(e) => setFile(e.target.files[0])} />
                {file ? (
                  <p style={{ color: "#22c55e", fontWeight: "500" }}>✅ {file.name}</p>
                ) : (
                  <>
                    <p style={{ color: "#666", marginBottom: "8px" }}>クリックしてファイルを選択</p>
                    <p style={{ color: "#999", fontSize: "12px" }}>対応形式: {service.accept}</p>
                  </>
                )}
              </div>
            </div>
          )}

          {/* テキスト入力 */}
          {service?.type === "text" && (
            <div>
              <textarea value={text} onChange={(e) => setText(e.target.value)}
                placeholder="テキストを入力してください..."
                rows={6} style={{
                  width: "100%", padding: "12px", border: "1px solid #ddd",
                  borderRadius: "8px", fontSize: "14px", resize: "vertical",
                  boxSizing: "border-box", fontFamily: "inherit"
                }} />
              {selectedService === "translate" && (
                <div style={{ marginTop: "12px" }}>
                  <label style={{ fontSize: "14px", fontWeight: "500", marginRight: "12px" }}>
                    翻訳先言語：
                  </label>
                  <select value={targetLang} onChange={(e) => setTargetLang(e.target.value)}
                    style={{ padding: "8px 12px", borderRadius: "6px", border: "1px solid #ddd", fontSize: "14px" }}>
                    <option value="en">英語</option>
                    <option value="ja">日本語</option>
                    <option value="zh">中国語</option>
                    <option value="ko">韓国語</option>
                    <option value="fr">フランス語</option>
                    <option value="de">ドイツ語</option>
                  </select>
                </div>
              )}
            </div>
          )}

          {error && (
            <div style={{
              background: "#fff0f0", border: "1px solid #e94560", color: "#e94560",
              padding: "10px 14px", borderRadius: "6px", marginTop: "16px", fontSize: "14px"
            }}>
              {error}
            </div>
          )}

          <button onClick={handleSubmit} disabled={!canSubmit || loading} style={{
            marginTop: "20px", padding: "12px 32px",
            background: !canSubmit || loading ? "#ccc" : "#e94560",
            color: "white", border: "none", borderRadius: "6px",
            fontSize: "16px", fontWeight: "bold",
            cursor: !canSubmit || loading ? "not-allowed" : "pointer"
          }}>
            {loading ? "処理中..." : "AI処理を実行"}
          </button>

          {/* 結果表示 */}
          {result && (
            <div style={{
              marginTop: "24px", background: "#f8faff", borderRadius: "8px",
              padding: "20px", border: "1px solid #e0e7ff"
            }}>
              <p style={{ fontWeight: "600", marginBottom: "12px", color: "#1a1a2e" }}>
                ✅ 処理完了（{result.processing_time}秒）
                {result.usage_count && (
                  <span style={{ fontSize: "12px", color: "#999", marginLeft: "12px", fontWeight: "normal" }}>
                    今月の使用回数: {result.usage_count}回
                  </span>
                )}
              </p>
              <pre style={{
                background: "#1a1a2e", color: "#e2e8f0", padding: "16px",
                borderRadius: "6px", overflow: "auto", fontSize: "13px",
                maxHeight: "400px", whiteSpace: "pre-wrap", wordBreak: "break-all"
              }}>
                {JSON.stringify(result.result, null, 2)}
              </pre>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
