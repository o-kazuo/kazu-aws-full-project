import axios from "axios";
import { getAccessToken, clearTokens } from "./auth";

const API_BASE_URL = import.meta.env.VITE_API_URL || "http://localhost:8000";

const api = axios.create({
  baseURL: API_BASE_URL,
});

// リクエスト毎にAuthorizationヘッダーを自動付与
api.interceptors.request.use((config) => {
  const token = getAccessToken();
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// 401エラー時は自動ログアウト
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      clearTokens();
      window.location.href = "/login";
    }
    return Promise.reject(error);
  }
);

// 認証API
export const authApi = {
  register: (email, password) =>
    api.post("/auth/register", { email, password }),
  login: (email, password) =>
    api.post("/auth/login", { email, password }),
};

// AI処理API
export const aiApi = {
  upload: (file, analysisType = "labels") => {
    const formData = new FormData();
    formData.append("file", file);
    return api.post(`/ai/upload?analysis_type=${analysisType}`, formData);
  },
  transcribe: (file, languageCode = "ja-JP") => {
    const formData = new FormData();
    formData.append("file", file);
    return api.post(`/ai/transcribe?language_code=${languageCode}`, formData);
  },
  translate: (text, targetLanguage = "en", sourceLanguage = "auto") =>
    api.post("/ai/translate", { text, target_language: targetLanguage, source_language: sourceLanguage }),
  comprehend: (text, languageCode = "ja") =>
    api.post("/ai/comprehend", { text, language_code: languageCode }),
  textract: (file, mode = "extract") => {
    const formData = new FormData();
    formData.append("file", file);
    return api.post(`/ai/textract?mode=${mode}`, formData);
  },
  bedrock: (prompt, mode = "generate") =>
    api.post("/ai/bedrock", { prompt, mode }),
  getUsage: () => api.get("/ai/usage"),
  getResults: (limit = 20) => api.get(`/ai/results?limit=${limit}`),
  getResult: (id) => api.get(`/ai/results/${id}`),
};

export default api;
