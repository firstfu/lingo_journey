#!/bin/bash
# ============================================================================
# 檔案名稱: build_appstore.sh
# 說明: 自動遞增 Build Number、打包 IPA 並上傳到 App Store Connect
# 專案: Lingo Journey (原生 Swift iOS App)
# 建立日期: 2025-01-29
# ============================================================================

set -e  # 遇到錯誤立即停止

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 專案配置
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_FILE="$PROJECT_DIR/lingo_journey.xcodeproj"
SCHEME="lingo_journey"
CONFIGURATION="Release"
EXPORT_OPTIONS="$PROJECT_DIR/ExportOptions.plist"
BUILD_DIR="$PROJECT_DIR/build"
ARCHIVE_PATH="$BUILD_DIR/lingo_journey.xcarchive"
IPA_EXPORT_PATH="$BUILD_DIR/ipa"

# App 名稱
APP_NAME="lingo_journey"

# App Store Connect API Key 配置
API_KEY_DIR="$HOME/.appstoreconnect"
API_KEY_PATH="$API_KEY_DIR/private_keys"
API_CONFIG_FILE="$API_KEY_DIR/config"
API_KEY_ID=""
API_ISSUER_ID=""

# 時間戳
TIMESTAMP=$(date +"%Y%m%d-%H%M")

# 版本資訊（稍後填入）
VERSION_NAME=""
OLD_BUILD_NUMBER=""
NEW_BUILD_NUMBER=""

# 上傳狀態標記
UPLOAD_COMPLETED=false

# 輸出函數
print_step() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}▶ $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ $1${NC}"
}

# 檢查必要工具
check_requirements() {
    print_step "檢查建置環境"

    if ! command -v xcodebuild &> /dev/null; then
        print_error "Xcode 未安裝"
        exit 1
    fi
    print_success "Xcode: $(xcodebuild -version | head -n 1)"

    if ! command -v xcrun &> /dev/null; then
        print_error "xcrun 未安裝"
        exit 1
    fi
    print_success "xcrun: 已安裝"

    if [ ! -d "$PROJECT_FILE" ]; then
        print_error "找不到 Xcode 專案: $PROJECT_FILE"
        exit 1
    fi
    print_success "專案: $PROJECT_FILE"

    if [ ! -f "$EXPORT_OPTIONS" ]; then
        print_error "找不到 ExportOptions.plist: $EXPORT_OPTIONS"
        exit 1
    fi
    print_success "ExportOptions: $EXPORT_OPTIONS"

    # 檢查 API Key 設定
    check_api_key
}

# 檢查並設定 App Store Connect API Key
check_api_key() {
    print_step "檢查 App Store Connect API Key"

    # 建立目錄結構
    mkdir -p "$API_KEY_PATH"

    # 嘗試從設定檔讀取
    if [ -f "$API_CONFIG_FILE" ]; then
        source "$API_CONFIG_FILE"
    fi

    # 檢查環境變數覆蓋
    if [ -n "$APP_STORE_API_KEY_ID" ]; then
        API_KEY_ID="$APP_STORE_API_KEY_ID"
    fi
    if [ -n "$APP_STORE_ISSUER_ID" ]; then
        API_ISSUER_ID="$APP_STORE_ISSUER_ID"
    fi

    # 如果還沒設定，提示用戶輸入
    if [ -z "$API_KEY_ID" ] || [ -z "$API_ISSUER_ID" ]; then
        print_warning "尚未設定 API Key"
        echo ""
        print_info "請先至 App Store Connect 建立 API Key："
        print_info "https://appstoreconnect.apple.com/access/integrations/api"
        echo ""

        echo -n "請輸入 Key ID (例如: ABC123DEFG): "
        read API_KEY_ID
        if [ -z "$API_KEY_ID" ]; then
            print_error "Key ID 不能為空"
            exit 1
        fi

        echo -n "請輸入 Issuer ID (例如: 12345678-1234-1234-1234-123456789012): "
        read API_ISSUER_ID
        if [ -z "$API_ISSUER_ID" ]; then
            print_error "Issuer ID 不能為空"
            exit 1
        fi

        # 儲存到設定檔
        echo "# App Store Connect API Key 設定" > "$API_CONFIG_FILE"
        echo "API_KEY_ID=\"$API_KEY_ID\"" >> "$API_CONFIG_FILE"
        echo "API_ISSUER_ID=\"$API_ISSUER_ID\"" >> "$API_CONFIG_FILE"
        print_success "設定已儲存至 $API_CONFIG_FILE"
    fi

    print_success "Key ID: $API_KEY_ID"
    print_success "Issuer ID: $API_ISSUER_ID"

    # 檢查 .p8 檔案
    P8_FILE="$API_KEY_PATH/AuthKey_${API_KEY_ID}.p8"
    if [ ! -f "$P8_FILE" ]; then
        print_error "找不到 API Key 檔案"
        echo ""
        print_info "請將下載的 .p8 檔案放到以下位置："
        print_info "$P8_FILE"
        echo ""
        print_info "檔案命名格式: AuthKey_<KeyID>.p8"
        print_info "例如: AuthKey_${API_KEY_ID}.p8"
        exit 1
    fi
    print_success "API Key 檔案: $P8_FILE"
}

# 讀取並遞增 Build Number
increment_build_number() {
    print_step "遞增 Build Number"

    cd "$PROJECT_DIR"

    # 從 project.pbxproj 讀取版本資訊
    PBXPROJ="$PROJECT_FILE/project.pbxproj"

    # 讀取 MARKETING_VERSION (版本號)
    VERSION_NAME=$(grep "MARKETING_VERSION" "$PBXPROJ" | head -1 | sed 's/.*= \(.*\);/\1/' | tr -d ' "')

    # 讀取 CURRENT_PROJECT_VERSION (Build Number)
    OLD_BUILD_NUMBER=$(grep "CURRENT_PROJECT_VERSION" "$PBXPROJ" | head -1 | sed 's/.*= \(.*\);/\1/' | tr -d ' "')

    # 遞增 build number
    NEW_BUILD_NUMBER=$((OLD_BUILD_NUMBER + 1))

    # 更新 project.pbxproj 中所有的 CURRENT_PROJECT_VERSION
    sed -i '' "s/CURRENT_PROJECT_VERSION = $OLD_BUILD_NUMBER;/CURRENT_PROJECT_VERSION = $NEW_BUILD_NUMBER;/g" "$PBXPROJ"

    print_info "版本名稱: $VERSION_NAME"
    print_info "舊 Build Number: $OLD_BUILD_NUMBER"
    print_success "新 Build Number: $NEW_BUILD_NUMBER"
    print_success "已更新 project.pbxproj"
}

# 清理舊建置
clean_build() {
    print_step "清理舊建置產物"

    # 清理 DerivedData
    if [ -d "$HOME/Library/Developer/Xcode/DerivedData" ]; then
        # 只清理本專案的 DerivedData
        find "$HOME/Library/Developer/Xcode/DerivedData" -maxdepth 1 -name "lingo_journey*" -type d -exec rm -rf {} + 2>/dev/null || true
        print_success "已清理專案 DerivedData"
    fi

    if [ -d "$ARCHIVE_PATH" ]; then
        rm -rf "$ARCHIVE_PATH"
        print_success "已刪除舊的 .xcarchive"
    fi

    if [ -d "$IPA_EXPORT_PATH" ]; then
        rm -rf "$IPA_EXPORT_PATH"
        print_success "已刪除舊的 IPA 目錄"
    fi

    if [ -d "$BUILD_DIR" ]; then
        rm -rf "$BUILD_DIR"
        print_success "已刪除 build 目錄"
    fi

    # 刪除舊的 AppStore IPA
    find "$PROJECT_DIR" -maxdepth 1 -name "${APP_NAME}-AppStore-*.ipa" -delete 2>/dev/null || true

    print_success "清理完成"
}

# Xcode Archive
xcode_archive() {
    print_step "建立 Xcode Archive"

    mkdir -p "$BUILD_DIR"

    xcodebuild -project "$PROJECT_FILE" \
        -scheme "$SCHEME" \
        -configuration "$CONFIGURATION" \
        -archivePath "$ARCHIVE_PATH" \
        -destination 'generic/platform=iOS' \
        -allowProvisioningUpdates \
        archive

    if [ ! -d "$ARCHIVE_PATH" ]; then
        print_error "Archive 建立失敗"
        exit 1
    fi

    print_success "Archive 建立完成: $ARCHIVE_PATH"
}

# 導出並上傳到 App Store Connect
export_and_upload() {
    print_step "導出並上傳到 App Store Connect"

    mkdir -p "$IPA_EXPORT_PATH"

    print_info "正在導出並上傳，這可能需要幾分鐘..."

    # 使用 xcodebuild 導出並上傳
    # 由於 ExportOptions.plist 使用 app-store-connect method，會直接上傳
    EXPORT_OUTPUT=$(xcodebuild -exportArchive \
        -archivePath "$ARCHIVE_PATH" \
        -exportOptionsPlist "$EXPORT_OPTIONS" \
        -exportPath "$IPA_EXPORT_PATH" \
        -allowProvisioningUpdates \
        -authenticationKeyPath "$API_KEY_PATH/AuthKey_${API_KEY_ID}.p8" \
        -authenticationKeyID "$API_KEY_ID" \
        -authenticationKeyIssuerID "$API_ISSUER_ID" 2>&1) || true

    EXPORT_RESULT=$?

    # 檢查是否上傳成功
    if echo "$EXPORT_OUTPUT" | grep -q "Upload succeeded"; then
        print_success "App 已成功上傳到 App Store Connect"
        UPLOAD_COMPLETED=true
        return 0
    fi

    # 檢查導出是否成功
    if echo "$EXPORT_OUTPUT" | grep -qi "EXPORT SUCCEEDED"; then
        print_success "導出成功"

        # 查找生成的 IPA
        GENERATED_IPA=$(find "$IPA_EXPORT_PATH" -name "*.ipa" | head -n 1)

        if [ -n "$GENERATED_IPA" ]; then
            # 複製到專案根目錄並重命名
            IPA_NAME="${APP_NAME}-AppStore-${VERSION_NAME}-${NEW_BUILD_NUMBER}-${TIMESTAMP}.ipa"
            cp "$GENERATED_IPA" "$PROJECT_DIR/$IPA_NAME"
            print_success "IPA 導出完成: $IPA_NAME"

            # 使用 altool 上傳
            upload_with_altool
        fi
        return 0
    fi

    # 如果導出失敗，顯示錯誤
    print_error "導出失敗"
    echo "$EXPORT_OUTPUT"
    exit 1
}

# 使用 altool 上傳（備用方法）
upload_with_altool() {
    if [ "$UPLOAD_COMPLETED" = true ]; then
        return 0
    fi

    print_step "使用 altool 上傳到 App Store Connect"

    FINAL_IPA="$PROJECT_DIR/$IPA_NAME"

    if [ ! -f "$FINAL_IPA" ]; then
        print_error "找不到 IPA 檔案: $FINAL_IPA"
        exit 1
    fi

    print_info "正在上傳 $IPA_NAME ..."
    print_info "這可能需要幾分鐘，請耐心等待..."

    xcrun altool --upload-app \
        --type ios \
        --file "$FINAL_IPA" \
        --apiKey "$API_KEY_ID" \
        --apiIssuer "$API_ISSUER_ID"

    if [ $? -eq 0 ]; then
        print_success "上傳成功！"
        UPLOAD_COMPLETED=true
    else
        print_error "上傳失敗"
        exit 1
    fi
}

# 顯示結果
show_result() {
    print_step "建置完成"

    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    🎉 App Store 上傳成功！                        ║${NC}"
    echo -e "${GREEN}╠═══════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║${NC} 版本:       ${YELLOW}${VERSION_NAME}${NC}"
    echo -e "${GREEN}║${NC} Build:      ${YELLOW}${NEW_BUILD_NUMBER}${NC}"

    # 如果有本地 IPA 檔案，顯示檔案資訊
    if [ -n "$IPA_NAME" ] && [ -f "$PROJECT_DIR/$IPA_NAME" ]; then
        FINAL_IPA="$PROJECT_DIR/$IPA_NAME"
        IPA_SIZE=$(du -h "$FINAL_IPA" | cut -f1)
        echo -e "${GREEN}║${NC} 檔案名稱:   ${YELLOW}$IPA_NAME${NC}"
        echo -e "${GREEN}║${NC} 檔案大小:   ${YELLOW}$IPA_SIZE${NC}"
    else
        echo -e "${GREEN}║${NC} 上傳方式:   ${YELLOW}直接上傳到 App Store Connect${NC}"
    fi

    echo -e "${GREEN}╠═══════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║${NC} ${CYAN}請前往 App Store Connect 查看處理狀態${NC}"
    echo -e "${GREEN}║${NC} ${CYAN}https://appstoreconnect.apple.com${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# 顯示使用說明
show_help() {
    echo -e "${CYAN}"
    echo "Lingo Journey App Store 上傳工具"
    echo ""
    echo "用法: ./build_appstore.sh [選項]"
    echo ""
    echo "選項:"
    echo "  -h, --help     顯示此說明"
    echo "  --skip-clean   跳過清理步驟"
    echo "  --skip-build   跳過 build number 遞增（使用現有版本）"
    echo ""
    echo "首次使用前請確認："
    echo "  1. 準備 App Store Connect API Key (.p8 檔案)"
    echo "  2. 將 .p8 檔案放到 ~/.appstoreconnect/private_keys/"
    echo -e "${NC}"
}

# 主流程
main() {
    SKIP_CLEAN=false
    SKIP_BUILD_INCREMENT=false

    # 解析參數
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            --skip-clean)
                SKIP_CLEAN=true
                shift
                ;;
            --skip-build)
                SKIP_BUILD_INCREMENT=true
                shift
                ;;
            *)
                print_error "未知選項: $1"
                show_help
                exit 1
                ;;
        esac
    done

    echo -e "${GREEN}"
    echo "╔═══════════════════════════════════════════════════════════════════╗"
    echo "║           Lingo Journey - App Store Connect 上傳工具             ║"
    echo "║                                                                   ║"
    echo "║   功能: 自動遞增 Build Number → 打包 IPA → 上傳 App Store         ║"
    echo "╚═══════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    check_requirements

    if [ "$SKIP_BUILD_INCREMENT" = false ]; then
        increment_build_number
    else
        # 讀取現有版本資訊
        PBXPROJ="$PROJECT_FILE/project.pbxproj"
        VERSION_NAME=$(grep "MARKETING_VERSION" "$PBXPROJ" | head -1 | sed 's/.*= \(.*\);/\1/' | tr -d ' "')
        NEW_BUILD_NUMBER=$(grep "CURRENT_PROJECT_VERSION" "$PBXPROJ" | head -1 | sed 's/.*= \(.*\);/\1/' | tr -d ' "')
        print_info "使用現有版本: $VERSION_NAME ($NEW_BUILD_NUMBER)"
    fi

    if [ "$SKIP_CLEAN" = false ]; then
        clean_build
    fi

    xcode_archive
    export_and_upload
    show_result
}

# 執行主流程
main "$@"
