//
//  BHZhipuChatClient.swift
//  BlindHelp
//

import Alamofire
import Foundation

/// 请求体改为 `JSONSerialization` → `Data` + `URLRequest`，避免 Alamofire `JSONParameterEncoder` 对「Encodable 且隔离」的类型参数告警。
private let kBHZhipuTravelAssistantSystemPrompt: String =
    """
    你是一个中文旅行社交应用里的旅行助手，语气友好、专业。\
    用户可用中文或英文提问；除用户明确要求使用其他语言外，**请始终用简体中文回答**，\
    措辞清晰简洁，需要时可稍展开。\
    擅长的方向包括：行程与路线、行前准备与行李、天气与安全、当地风俗与礼仪、\
    以及本应用内常见问题（动态/广场、私信与关注、拉黑与举报等）。\
    不要编造不存在的功能；若不确定请如实说明并给出合理建议。
    """

private struct BHZhipuChatResponseBody: Decodable, Sendable {
    struct Choice: Decodable, Sendable {
        struct Msg: Decodable, Sendable {
            let content: String?
        }
        let message: Msg?
    }
    struct APIError: Decodable, Sendable {
        let message: String?
        let code: String?
    }
    let choices: [Choice]?
    let error: APIError?
}

/// 智谱开放平台 Chat Completions（GLM-4-Flash）。
enum BHZhipuChatClient {

    static let endpointURL =
        URL(string: "https://open.bigmodel.cn/api/paas/v4/chat/completions")!

    static let modelGLM4Flash = "glm-4-flash"

    /// `dialogue` 为按时间顺序的 `(isUser, text)`；`isUser == false` 视为 assistant。
    nonisolated static func completeChat(
        dialogue: [(isUser: Bool, text: String)],
        completion: @escaping @Sendable (Result<String, Error>) -> Void
    ) {
        var messages: [[String: String]] = [
            ["role": "system", "content": kBHZhipuTravelAssistantSystemPrompt],
        ]
        for turn in dialogue {
            let role = turn.isUser ? "user" : "assistant"
            messages.append(["role": role, "content": turn.text])
        }

        let payload: [String: Any] = [
            "model": modelGLM4Flash,
            "messages": messages,
        ]

        guard JSONSerialization.isValidJSONObject(payload) else {
            DispatchQueue.main.async {
                completion(.failure(NSError(
                    domain: "BHZhipuChatClient",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Invalid chat payload"]
                )))
            }
            return
        }

        let bodyData: Data
        do {
            bodyData = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            DispatchQueue.main.async {
                completion(.failure(error))
            }
            return
        }

        var request = URLRequest(url: endpointURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(kZhipuAPIKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = bodyData

        AF.request(request)
            .validate(statusCode: 200 ..< 300)
            .responseData(queue: .global(qos: .userInitiated)) { response in
                switch response.result {
                case .success(let data):
                    do {
                        let decoded = try JSONDecoder().decode(BHZhipuChatResponseBody.self, from: data)
                        if let err = decoded.error, let msg = err.message, !msg.isEmpty {
                            DispatchQueue.main.async {
                                completion(.failure(NSError(
                                    domain: "BHZhipuChatClient",
                                    code: -2,
                                    userInfo: [NSLocalizedDescriptionKey: msg]
                                )))
                            }
                            return
                        }
                        let text =
                            decoded.choices?.first?.message?.content?
                            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                        if text.isEmpty {
                            DispatchQueue.main.async {
                                completion(.failure(NSError(
                                    domain: "BHZhipuChatClient",
                                    code: -3,
                                    userInfo: [NSLocalizedDescriptionKey: "Empty assistant reply"]
                                )))
                            }
                            return
                        }
                        DispatchQueue.main.async {
                            completion(.success(text))
                        }
                    } catch {
                        DispatchQueue.main.async {
                            completion(.failure(error))
                        }
                    }
                case .failure(let err):
                    DispatchQueue.main.async {
                        completion(.failure(err))
                    }
                }
            }
    }
}
