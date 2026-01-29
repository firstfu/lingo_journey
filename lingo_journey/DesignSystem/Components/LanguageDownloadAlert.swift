import SwiftUI

struct LanguageDownloadAlert: ViewModifier {
    @Binding var isPresented: Bool
    let languageName: String
    let onDownload: () -> Void

    func body(content: Content) -> some View {
        content
            .alert("「\(languageName)」尚未下載", isPresented: $isPresented) {
                Button("下載語言包", action: onDownload)
                Button("取消", role: .cancel) { }
            } message: {
                Text("下載後可離線使用")
            }
    }
}

extension View {
    func languageDownloadAlert(
        isPresented: Binding<Bool>,
        languageName: String,
        onDownload: @escaping () -> Void
    ) -> some View {
        modifier(LanguageDownloadAlert(
            isPresented: isPresented,
            languageName: languageName,
            onDownload: onDownload
        ))
    }
}
