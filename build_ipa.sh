#!/usr/bin/env bash
# 在仓库根目录执行：Archive + 使用 ExportOptions.plist 导出 IPA（app-store 方式）。

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

WORKSPACE="BlindHelp.xcworkspace"
SCHEME="BlindHelp"
CONFIGURATION="Release"
ARCHIVE_PATH="${ROOT}/build/BlindHelp.xcarchive"
EXPORT_DIR="${ROOT}/build/ipa"
EXPORT_PLIST="${ROOT}/ExportOptions.plist"

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "错误: 未找到 xcodebuild，请安装 Xcode 并将 xcode-select 指向 Xcode.app。" >&2
  exit 1
fi

ACTIVE_DEV="$(xcode-select -p 2>/dev/null || true)"
if [[ "$ACTIVE_DEV" == *CommandLineTools* ]]; then
  echo "错误: 当前 developer directory 指向 Command Line Tools，无法打 iOS 包。" >&2
  echo "     正在使用: ${ACTIVE_DEV}" >&2
  echo "" >&2
  echo "请安装「从 App Store 或 developer.apple.com 下载的完整 Xcode」，然后执行（路径按你机器上 Xcode 位置改）：" >&2
  echo "  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer" >&2
  echo "首次可在 Xcode 里同意许可：  sudo xcodebuild -license accept" >&2
  exit 1
fi

if [[ ! -f "$WORKSPACE/contents.xcworkspacedata" ]]; then
  echo "错误: 未找到 ${WORKSPACE}" >&2
  exit 1
fi

if [[ ! -f "$EXPORT_PLIST" ]]; then
  echo "错误: 未找到 ExportOptions.plist：${EXPORT_PLIST}" >&2
  exit 1
fi

echo "==> Archive: ${SCHEME} (${CONFIGURATION})"
xcodebuild \
  -workspace "$WORKSPACE" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -destination 'generic/platform=iOS' \
  clean archive \
  -archivePath "$ARCHIVE_PATH"

echo "==> Export IPA（${EXPORT_PLIST}）"
rm -rf "$EXPORT_DIR"
mkdir -p "$EXPORT_DIR"

xcodebuild \
  -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_DIR" \
  -exportOptionsPlist "$EXPORT_PLIST"

echo "==> 完成。导出目录: ${EXPORT_DIR}"
ls -la "$EXPORT_DIR"
