import { useState } from "react";
import { aiApi } from "../utils/api";

const SERVICES = [
  { id: "rekognition", label: "🖼️ 画像分析", desc: "画像からラベル・顔を検出", type: "file", accept: "image/*" },
  { id: "transcribe", label: "🎙️ 音声認識", desc: "音声ファイルをテキストに変換", type: "file", accept: "audio/*,video/mp4" },
  { id: "textract", label: "📄 文書抽出", desc: "PDF・画像からテキスト抽出", type: "file", accept: "image/*,application/pdf" },
  { id: "translate", label: "🌐 翻訳", desc: "テキストを多言語に翻訳", type: "text" },
  { id: "comprehend", label: "📊 テキスト分析", desc: "感情・キーフレーズ・エンティティ検出", type: "text" },
  { id: "bedrock", label: "🤖 生成AI", desc: "Claude Haiku 4.5でテキスト生成", type: "text" },
];

const LABEL_JA = {
  Vegetation: "植生", Nature: "自然", Outdoors: "屋外", Scenery: "景色",
  Jungle: "ジャングル", Land: "土地", Woodland: "森林", Rainforest: "熱帯雨林",
  Road: "道路", Green: "緑", Sky: "空", Cloud: "雲", Mountain: "山",
  River: "川", Lake: "湖", Ocean: "海", Beach: "ビーチ", Forest: "森",
  Tree: "木", Grass: "草", Flower: "花", Plant: "植物", Water: "水",
  Animal: "動物", Dog: "犬", Cat: "猫", Bird: "鳥", Fish: "魚",
  Person: "人物", Face: "顔", Man: "男性", Woman: "女性", Child: "子供",
  Crowd: "群衆", Clothing: "衣服", Building: "建物", Architecture: "建築",
  City: "都市", Urban: "市街地", House: "家", Office: "オフィス",
  Room: "部屋", Interior: "内装", Food: "食べ物", Fruit: "果物",
  Vegetable: "野菜", Meal: "食事", Car: "車", Vehicle: "乗り物",
  Truck: "トラック", Bus: "バス", Bicycle: "自転車", Motorcycle: "バイク",
  Airplane: "飛行機", Boat: "ボート", Electronics: "電子機器",
  Computer: "コンピュータ", Phone: "電話", Furniture: "家具",
  Table: "テーブル", Chair: "椅子", Sport: "スポーツ", Ball: "ボール",
  Night: "夜", Day: "昼", Sunset: "夕焼け", Sunrise: "日の出",
  Light: "光", Shadow: "影", Snow: "雪", Rain: "雨", Fire: "火",
  Smoke: "煙", Fog: "霧", Desert: "砂漠", Rock: "岩", Stone: "石",
  Sand: "砂", Soil: "土", Leaf: "葉", Branch: "枝", Root: "根",
  Rainbow: "虹", Storm: "嵐", Waterfall: "滝", Valley: "谷",
  Hill: "丘", Field: "畑・野原", Farm: "農場", Garden: "庭園",
  Park: "公園", Bridge: "橋", Tower: "塔", Castle: "城",
  Church: "教会", Temple: "寺院", Market: "市場", Shop: "店",
  Restaurant: "レストラン", Hotel: "ホテル", Hospital: "病院",
  School: "学校", Library: "図書館", Museum: "博物館",
  Stadium: "スタジアム", Airport: "空港", Station: "駅", Harbor: "港",
  Swimming: "水泳", Running: "ランニング", Cycling: "サイクリング",
  Hiking: "ハイキング", Camping: "キャンプ", Fishing: "釣り",
  Cooking: "料理", Eating: "食事", Drinking: "飲む", Reading: "読書",
  Writing: "書く", Drawing: "描く", Painting: "絵画", Music: "音楽",
  Dance: "ダンス", Performance: "パフォーマンス", Concert: "コンサート",
  Wedding: "結婚式", Party: "パーティー", Celebration: "お祝い",
  Twilight: "薄明かり",
};

const CATEGORY_JA = {
  "Nature and Outdoors": "自然・屋外",
  "Transport and Logistics": "交通・物流",
  "Colors and Visual Composition": "色・構図",
  "Animals and Pets": "動物・ペット",
  "People and Portraits": "人物・ポートレート",
  "Food and Drink": "食べ物・飲み物",
  "Architecture and Buildings": "建築・建物",
  "Electronics and Technology": "電子機器・テクノロジー",
  "Sports and Recreation": "スポーツ・レクリエーション",
  "Furniture and Household": "家具・家庭用品",
  "Urban and Street": "都市・街",
  "Fashion and Apparel": "ファッション・衣服",
  "Art and Entertainment": "アート・エンターテインメント",
  "Travel and Adventure": "旅行・冒険",
  "Science and Technology": "科学・テクノロジー",
  "Health and Medical": "健康・医療",
  "Education": "教育",
  "Business and Finance": "ビジネス・金融",
};

const EMOTION_JA = {
  HAPPY: "😊 幸福", SAD: "😢 悲しみ", ANGRY: "😠 怒り",
  CONFUSED: "😕 困惑", DISGUSTED: "🤢 嫌悪", SURPRISED: "😲 驚き",
  CALM: "😌 穏やか", FEAR: "😨 恐怖",
};

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
        case "rekognition": res = await aiApi.upload(file, analysisType); break;
        case "transcribe":  res = await aiApi.transcribe(file); break;
        case "textract":    res = await aiApi.textract(file); break;
        case "translate":   res = await aiApi.translate(text, targetLang); break;
        case "comprehend":  res = await aiApi.comprehend(text); break;
        case "bedrock":     res = await aiApi.bedrock(text); break;
        default: throw new Error("不明なサービスです");
      }
      setResult(res.data);
    } catch (err) {
      if (err.response?.status === 429) {
        setError("月間使用回数の上限に達しました。プレミアムにアップグレードしてください。");
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
      <h2 style={{ marginBottom: "24px", color: "#1a1a2e", fontSize: "20px" }}>AI処理</h2>

      <div style={{
        display: "grid",
        gridTemplateColumns: "minmax(0, 260px) 1fr",
        gap: "16px",
        alignItems: "start"
      }}>
        {/* サービス選択 */}
        <div style={{
          background: "white",
          borderRadius: "12px",
          padding: "16px",
          boxShadow: "0 2px 8px rgba(0,0,0,0.08)"
        }}>
          <p style={{ fontWeight: "700", marginBottom: "12px", color: "#1a1a2e", fontSize: "13px" }}>
            サービスを選択
          </p>
          {SERVICES.map((s) => (
            <div
              key={s.id}
              onClick={() => { setSelectedService(s.id); setResult(null); setError(""); }}
              style={{
                padding: "10px 12px",
                borderRadius: "8px",
                marginBottom: "6px",
                cursor: "pointer",
                background: selectedService === s.id ? "#fff0f3" : "transparent",
                border: selectedService === s.id ? "1px solid #e94560" : "1px solid transparent",
                transition: "all 0.15s"
              }}
            >
              <p style={{
                fontWeight: "600",
                fontSize: "13px",
                color: selectedService === s.id ? "#e94560" : "#1a1a2e",
                marginBottom: "2px"
              }}>
                {s.label}
              </p>
              <p style={{ fontSize: "11px", color: "#999" }}>{s.desc}</p>
            </div>
          ))}
        </div>

        {/* 入力・結果エリア */}
        <div style={{
          background: "white",
          borderRadius: "12px",
          padding: "24px",
          boxShadow: "0 2px 8px rgba(0,0,0,0.08)"
        }}>
          <h3 style={{ marginBottom: "20px", color: "#1a1a2e", fontSize: "16px" }}>
            {service?.label}
          </h3>

          {/* ファイル入力 */}
          {service?.type === "file" && (
            <div>
              {selectedService === "rekognition" && (
                <div style={{ marginBottom: "16px" }}>
                  <label style={{ fontSize: "13px", fontWeight: "600", marginBottom: "8px", display: "block", color: "#444" }}>
                    分析タイプ
                  </label>
                  <select
                    value={analysisType}
                    onChange={(e) => setAnalysisType(e.target.value)}
                    style={{
                      padding: "8px 12px",
                      borderRadius: "8px",
                      border: "1px solid #ddd",
                      fontSize: "14px",
                      background: "white",
                      cursor: "pointer"
                    }}
                  >
                    <option value="labels">ラベル検出（物体・シーン）</option>
                    <option value="faces">顔検出（感情・年齢）</option>
                  </select>
                </div>
              )}
              <div
                style={{
                  border: "2px dashed #ddd",
                  borderRadius: "10px",
                  padding: "40px 20px",
                  textAlign: "center",
                  cursor: "pointer",
                  background: file ? "#f0fff4" : "#fafafa",
                  transition: "all 0.2s"
                }}
                onClick={() => document.getElementById("file-input").click()}
              >
                <input
                  id="file-input"
                  type="file"
                  accept={service.accept}
                  style={{ display: "none" }}
                  onChange={(e) => setFile(e.target.files[0])}
                />
                {file ? (
                  <p style={{ color: "#22c55e", fontWeight: "600", fontSize: "14px" }}>
                    ✅ {file.name}
                  </p>
                ) : (
                  <>
                    <div style={{ fontSize: "32px", marginBottom: "8px" }}>📁</div>
                    <p style={{ color: "#666", marginBottom: "6px", fontSize: "14px" }}>
                      クリックしてファイルを選択
                    </p>
                    <p style={{ color: "#bbb", fontSize: "12px" }}>
                      対応形式: {service.accept}
                    </p>
                  </>
                )}
              </div>
            </div>
          )}

          {/* テキスト入力 */}
          {service?.type === "text" && (
            <div>
              <textarea
                value={text}
                onChange={(e) => setText(e.target.value)}
                placeholder="テキストを入力してください..."
                rows={6}
                style={{
                  width: "100%",
                  padding: "12px",
                  border: "1px solid #ddd",
                  borderRadius: "8px",
                  fontSize: "14px",
                  resize: "vertical",
                  boxSizing: "border-box",
                  fontFamily: "inherit",
                  outline: "none"
                }}
              />
              {selectedService === "translate" && (
                <div style={{ marginTop: "12px", display: "flex", alignItems: "center", gap: "12px" }}>
                  <label style={{ fontSize: "13px", fontWeight: "600", color: "#444", whiteSpace: "nowrap" }}>
                    翻訳先言語：
                  </label>
                  <select
                    value={targetLang}
                    onChange={(e) => setTargetLang(e.target.value)}
                    style={{
                      padding: "8px 12px",
                      borderRadius: "8px",
                      border: "1px solid #ddd",
                      fontSize: "14px",
                      background: "white",
                      cursor: "pointer"
                    }}
                  >
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
              background: "#fff0f0",
              border: "1px solid #e94560",
              color: "#e94560",
              padding: "10px 14px",
              borderRadius: "8px",
              marginTop: "16px",
              fontSize: "14px"
            }}>
              ⚠️ {error}
            </div>
          )}

          <button
            onClick={handleSubmit}
            disabled={!canSubmit || loading}
            style={{
              marginTop: "20px",
              padding: "12px 32px",
              background: !canSubmit || loading ? "#ccc" : "#e94560",
              color: "white",
              border: "none",
              borderRadius: "8px",
              fontSize: "15px",
              fontWeight: "bold",
              cursor: !canSubmit || loading ? "not-allowed" : "pointer",
              transition: "background 0.2s",
              width: "100%"
            }}
          >
            {loading ? "⏳ 処理中..." : "AI処理を実行"}
          </button>

          {/* 結果表示 */}
          {result && (
            <div style={{
              marginTop: "24px",
              background: "#f8faff",
              borderRadius: "10px",
              padding: "20px",
              border: "1px solid #e0e7ff"
            }}>
              <p style={{ fontWeight: "700", marginBottom: "16px", color: "#1a1a2e", fontSize: "14px" }}>
                ✅ 処理完了（{result.processing_time}秒）
                {result.usage_count && (
                  <span style={{ fontSize: "12px", color: "#999", marginLeft: "12px", fontWeight: "normal" }}>
                    今月の使用回数: {result.usage_count}回
                  </span>
                )}
              </p>

              {/* Rekognitionラベル検出 */}
              {selectedService === "rekognition" && analysisType === "labels" && Array.isArray(result.result) && (
                <div>
                  <p style={{ fontSize: "13px", fontWeight: "700", marginBottom: "12px", color: "#555" }}>
                    検出されたラベル
                  </p>
                  {result.result.map((label, i) => (
                    <div key={i} style={{ marginBottom: "12px" }}>
                      <div style={{ display: "flex", justifyContent: "space-between", marginBottom: "4px" }}>
                        <span style={{ fontSize: "14px", fontWeight: "600" }}>
                          {LABEL_JA[label.Name] || label.Name}
                        </span>
                        <span style={{ fontSize: "13px", color: "#666" }}>
                          {label.Confidence.toFixed(1)}%
                        </span>
                      </div>
                      <div style={{ background: "#e0e7ff", borderRadius: "4px", height: "8px" }}>
                        <div style={{
                          background: "#e94560",
                          height: "8px",
                          borderRadius: "4px",
                          width: `${label.Confidence}%`,
                          transition: "width 0.5s ease"
                        }} />
                      </div>
                      {label.Categories?.length > 0 && (
                        <span style={{ fontSize: "11px", color: "#999", marginTop: "2px", display: "block" }}>
                          カテゴリ: {label.Categories.map(c => CATEGORY_JA[c.Name] || c.Name).join(", ")}
                        </span>
                      )}
                    </div>
                  ))}
                </div>
              )}

              {/* Rekognition顔検出 */}
              {selectedService === "rekognition" && analysisType === "faces" && Array.isArray(result.result) && (
                <div>
                  <p style={{ fontSize: "13px", fontWeight: "700", marginBottom: "12px", color: "#555" }}>
                    検出された顔: {result.result.length}人
                  </p>
                  {result.result.map((face, i) => (
                    <div key={i} style={{
                      background: "white",
                      borderRadius: "8px",
                      padding: "16px",
                      marginBottom: "12px",
                      border: "1px solid #e0e7ff"
                    }}>
                      <p style={{ fontWeight: "700", marginBottom: "10px", fontSize: "14px" }}>顔 #{i + 1}</p>
                      <div style={{
                        display: "grid",
                        gridTemplateColumns: "repeat(auto-fit, minmax(180px, 1fr))",
                        gap: "8px",
                        fontSize: "13px",
                        color: "#444"
                      }}>
                        <div>{EMOTION_JA[face.Emotions?.[0]?.Type] || face.Emotions?.[0]?.Type} ({face.Emotions?.[0]?.Confidence.toFixed(1)}%)</div>
                        <div>🎂 推定年齢: {face.AgeRange?.Low}〜{face.AgeRange?.High}歳</div>
                        <div>👤 性別: {face.Gender?.Value === "Male" ? "男性" : "女性"} ({face.Gender?.Confidence.toFixed(1)}%)</div>
                        <div>😎 サングラス: {face.Sunglasses?.Value ? "あり" : "なし"}</div>
                        <div>🕶️ 眼鏡: {face.Eyeglasses?.Value ? "あり" : "なし"}</div>
                        <div>😄 笑顔: {face.Smile?.Value ? "あり" : "なし"}</div>
                      </div>
                    </div>
                  ))}
                </div>
              )}

              {/* Bedrock生成AI */}
              {selectedService === "bedrock" && (
                <div style={{
                  background: "white",
                  borderRadius: "8px",
                  padding: "16px",
                  border: "1px solid #e0e7ff",
                  fontSize: "14px",
                  lineHeight: "1.8",
                  whiteSpace: "pre-wrap",
                  color: "#1a1a2e"
                }}>
                  {result.result?.generated_text}
                </div>
              )}

              {/* Translate */}
              {selectedService === "translate" && (
                <div style={{ background: "white", borderRadius: "8px", padding: "16px", border: "1px solid #e0e7ff", fontSize: "14px", lineHeight: "1.8", color: "#1a1a2e" }}>
                  <p style={{ fontSize: "12px", color: "#999", marginBottom: "8px" }}>{result.result?.SourceLanguageCode} → {result.result?.TargetLanguageCode}</p>
                  <p>{result.result?.TranslatedText}</p>
                </div>
              )}

              {/* Transcribe */}
              {selectedService === "transcribe" && (
                <div style={{ background: "white", borderRadius: "8px", padding: "16px", border: "1px solid #e0e7ff", fontSize: "14px", lineHeight: "1.8", whiteSpace: "pre-wrap", color: "#1a1a2e" }}>
                  {result.result || "（音声が検出されませんでした）"}
                </div>
              )}

              {/* Comprehend */}
              {selectedService === "comprehend" && (
                <div style={{ background: "white", borderRadius: "8px", padding: "16px", border: "1px solid #e0e7ff" }}>
                  <p style={{ fontSize: "13px", fontWeight: "700", marginBottom: "12px", color: "#555" }}>感情分析</p>
                  <p style={{ fontSize: "14px", marginBottom: "8px" }}>
                    感情: <strong>{result.result?.sentiment === "POSITIVE" ? "😊 ポジティブ" : result.result?.sentiment === "NEGATIVE" ? "😢 ネガティブ" : result.result?.sentiment === "NEUTRAL" ? "😐 ニュートラル" : "😕 混在"}</strong>
                  </p>
                  {result.result?.entities?.length > 0 && (
                    <div>
                      <p style={{ fontSize: "13px", fontWeight: "700", marginBottom: "8px", color: "#555" }}>検出されたエンティティ</p>
                      {result.result.entities.map((e, i) => (
                        <span key={i} style={{ display: "inline-block", background: "#e0e7ff", borderRadius: "4px", padding: "2px 8px", marginRight: "6px", marginBottom: "6px", fontSize: "13px" }}>
                          {e.Text}（{e.Type}）
                        </span>
                      ))}
                    </div>
                  )}
                </div>
              )}

              {/* Textract */}
              {selectedService === "textract" && (
                <div style={{ background: "white", borderRadius: "8px", padding: "16px", border: "1px solid #e0e7ff" }}>
                  <p style={{ fontSize: "13px", fontWeight: "700", marginBottom: "8px", color: "#555" }}>抽出テキスト（{result.result?.line_count}行）</p>
                  <pre style={{ fontSize: "14px", lineHeight: "1.8", whiteSpace: "pre-wrap", color: "#1a1a2e", margin: 0 }}>
                    {result.result?.text || "（テキストが検出されませんでした）"}
                  </pre>
                </div>
              )}

              {/* その他サービスはJSON表示 */}
              {selectedService !== "rekognition" && selectedService !== "bedrock" && selectedService !== "translate" && selectedService !== "transcribe" && selectedService !== "comprehend" && selectedService !== "textract" && (
                <pre style={{
                  background: "#1a1a2e",
                  color: "#e2e8f0",
                  padding: "16px",
                  borderRadius: "8px",
                  overflow: "auto",
                  fontSize: "13px",
                  maxHeight: "400px",
                  whiteSpace: "pre-wrap",
                  wordBreak: "break-all"
                }}>
                  {JSON.stringify(result.result, null, 2)}
                </pre>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
