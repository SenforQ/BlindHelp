//
//  MDefinition+Config.swift
//  BlindHelp
//
//  Created by tabier on 2026/5/13.
//

import Foundation

// MARK: - App Store

/// App Store 应用 ID（用于分享链接、跳转更新页）。
let kAppId: String = "6754641449"

/// App Store 分享链接。
let kShareAppLink: String = "https://itunes.apple.com/app/apple-store/\(kAppId)"

/// App Store 应用详情页链接。
let kAppStoreLink: String = "https://itunes.apple.com/app/\(kAppId)"

// MARK: - 内购

/// 周订阅商品 ID。
let kAppStoreWeekBuy: String = "com.cailing.ai.photoeditor.weeklyplan"

/// 年订阅商品 ID。
let kAppStoreYearBuy: String = "com.cailing.ai.photoeditor.annuallyplan"

/// 与订阅/购买流程相关的业务 Key（按后端或本地约定使用）。
let kProductBuyKey: String = "a591bc2818d745db8e0c8482ee352114"

/// 商品 ID 展示顺序（列表等场景使用）。
let kAppProductPlanArray: [String] = [kAppStoreWeekBuy, kAppStoreYearBuy]

/// 商品 ID 集合（快速查找、校验）。
let kAppProductArray: Set<String> = [kAppStoreWeekBuy, kAppStoreYearBuy]

// MARK: - 埋点事件名

/// 购买引导详情。
let kPurchaseGuideDetailEvents: String = "PurchaseGuideDetail"

/// 购买页详情。
let kPurchasePageDetailEvents: String = "PurchasePageDetail"

/// AI 修图任务计数。
let kAIPhotoEditorTaskCountEvents: String = "AIPhotoEditorTaskCount"

let kGenerateRatioUseDetailEvents: String = "RatioUseDetail"
let kClickPasteCountEvents: String = "ClickPasteCount"

let kClickPreviewPhotoBehaviourEvents: String = "PreviewPhotoBehaviour"
let kClickHomeVipRouteCountEvents: String = "HomeVipRouteCount"
let kClickProfileVipRouteCountEvents: String = "ProfileVipRouteCount"

// MARK: - 协议与政策 URL

/// 隐私政策地址（上线前请替换为正式 H5）。
var kPrivatePolicyHtmlStr: String = "http://49.235.121.178/private.html"

/// 用户协议地址（上线前请替换为正式 H5）。
var kUserAgreementHtmlStr: String = "http://49.235.121.178/usage.html"

// MARK: - 网络与密钥

/// 第三方 / Banana 相关 API Key（勿提交到公开仓库时建议改为远端下发或 xcconfig）。
let kBananakey: String = "c85203f01ad447f101bb5d9ab1c4917b"

/// 智谱开放平台（GLM｜Chat Completions）密钥；公开仓库勿提交真实 Key，建议使用 xcconfig / 远端下发并轮换密钥。
let kZhipuAPIKey: String = "6d7dd50e84874f0ba119ececc8291332.lBVvYltsiM8rXbEz"

/// 创建任务（无图）接口。
let postBananaCreateTaskNoImageUrlStr: String = "https://api.kie.ai/api/v1/jobs/createTask"

/// Base64 上传图片任务接口。
let postBananaUploadImgTaskUrlStr: String = "https://kieai.redpandaai.co/api/file-base64-upload"

/// 查询任务状态（前缀 URL，需拼接 taskId）。
let getBananaCheckTaskNoImageUrlStr: String = "https://api.kie.ai/api/v1/jobs/recordInfo?taskId="
