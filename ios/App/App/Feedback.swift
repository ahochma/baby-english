import SwiftUI
import MessageUI
import StoreKit

// ─────────────────────────────────────────────
// MARK: - Parent feedback (Parent Zone only, behind the parental gate)
// ─────────────────────────────────────────────
//
// Happy parents are sent to Apple's rating prompt; everyone else gets an
// email draft to us. That turns would-be 1-star reviews into fixable emails.
// Nothing about the child is attached: only app version, iOS version,
// device model and language, which the parent sees before sending.

extension AppInfo {
    /// Where parent feedback goes. Leave empty to hide the email options.
    static let supportEmail = ""

    static var deviceModel: String {
        var info = utsname()
        uname(&info)
        return withUnsafePointer(to: &info.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) { String(cString: $0) }
        }
    }
}

enum FeedbackMood: String {
    case love, okay, notForUs

    var emoji: String {
        switch self { case .love: return "😍"; case .okay: return "🙂"; case .notForUs: return "😕" }
    }
    var label: String {
        switch self {
        case .love: return L10n.t("We love it", "אוהבים")
        case .okay: return L10n.t("It's OK", "בסדר")
        case .notForUs: return L10n.t("Not for us", "לא בשבילנו")
        }
    }
}

enum FeedbackMail {
    static func subject(_ mood: FeedbackMood) -> String {
        "Pip English feedback (\(mood.rawValue))"
    }

    static func body(_ mood: FeedbackMood) -> String {
        let prompt = mood == .notForUs
            ? L10n.t("What didn't work for your child? We read every message.",
                     "מה לא עבד אצל הילד/ה? אנחנו קוראים כל הודעה.")
            : L10n.t("What would make Pip English better for your child?",
                     "מה היה הופך את אנגלית עם פיפ לטובה יותר בשבילכם?")
        return """
        \(prompt)



        —
        App \(AppInfo.version) · iOS \(UIDevice.current.systemVersion) · \(AppInfo.deviceModel) · \(Locale.preferredLanguages.first ?? "")
        """
    }

    static func mailtoURL(_ mood: FeedbackMood) -> URL? {
        guard !AppInfo.supportEmail.isEmpty else { return nil }
        var c = URLComponents()
        c.scheme = "mailto"
        c.path = AppInfo.supportEmail
        c.queryItems = [URLQueryItem(name: "subject", value: subject(mood)),
                        URLQueryItem(name: "body", value: body(mood))]
        return c.url
    }
}

/// Wraps the system mail sheet. Used when Mail is set up; otherwise we fall back to a mailto: link.
struct MailComposer: UIViewControllerRepresentable {
    let mood: FeedbackMood
    let onDone: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onDone: onDone) }

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        vc.setToRecipients([AppInfo.supportEmail])
        vc.setSubject(FeedbackMail.subject(mood))
        vc.setMessageBody(FeedbackMail.body(mood), isHTML: false)
        return vc
    }

    func updateUIViewController(_ vc: MFMailComposeViewController, context: Context) {}

    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let onDone: () -> Void
        init(onDone: @escaping () -> Void) { self.onDone = onDone }
        func mailComposeController(_ controller: MFMailComposeViewController,
                                   didFinishWith result: MFMailComposeResult, error: Error?) {
            onDone()
        }
    }
}

/// "How is Pip English going?" card for the Parent Zone.
struct FeedbackCard: View {
    @Environment(\.requestReview) private var requestReview
    @Environment(\.openURL) private var openURL
    @State private var mailMood: FeedbackMood?
    @State private var thanked = false

    private var emailAvailable: Bool { !AppInfo.supportEmail.isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(L10n.t("How is Pip English going?", "איך אנגלית עם פיפ עובדת אצלכם?"),
                  systemImage: "heart.text.square.fill")
                .font(.parent(17, .bold))
                .foregroundColor(Palette.parentInk)

            if thanked {
                Text(L10n.t("Thank you! A rating helps other parents find us.",
                            "תודה! דירוג עוזר להורים אחרים למצוא אותנו."))
                    .font(.parent(14))
                    .foregroundColor(Palette.parentInk.opacity(0.7))
            } else {
                HStack(spacing: 10) {
                    ForEach(moods, id: \.rawValue) { mood in
                        Button { choose(mood) } label: {
                            VStack(spacing: 4) {
                                Text(mood.emoji).font(.system(size: 30))
                                Text(mood.label).font(.parent(13, .semibold))
                                    .lineLimit(1).minimumScaleFactor(0.7)
                            }
                            .foregroundColor(Palette.parentInk)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Palette.parentBG))
                        }
                        .buttonStyle(SquishyButtonStyle(scale: 0.95))
                        .accessibilityLabel(mood.label)
                    }
                }
                if emailAvailable {
                    Text(L10n.t("Not perfect yet? Tell us, we answer every email.",
                                "משהו לא מושלם? ספרו לנו, אנחנו עונים לכל מייל."))
                        .font(.parent(12))
                        .foregroundColor(Palette.parentInk.opacity(0.55))
                }
            }
        }
        .sheet(item: Binding(get: { mailMood.map(MoodBox.init) }, set: { mailMood = $0?.mood })) { box in
            MailComposer(mood: box.mood) { mailMood = nil }
                .ignoresSafeArea()
        }
    }

    private var moods: [FeedbackMood] {
        emailAvailable ? [.love, .okay, .notForUs] : [.love]
    }

    private func choose(_ mood: FeedbackMood) {
        Haptics.tap()
        switch mood {
        case .love:
            requestReview()
            withAnimation { thanked = true }
        case .okay, .notForUs:
            if MFMailComposeViewController.canSendMail() {
                mailMood = mood
            } else if let url = FeedbackMail.mailtoURL(mood) {
                openURL(url)
            }
        }
    }
}

private struct MoodBox: Identifiable {
    let mood: FeedbackMood
    var id: String { mood.rawValue }
}
