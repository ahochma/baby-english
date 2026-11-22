import SwiftUI
import StoreKit

// ─────────────────────────────────────────────
// MARK: - Parent Zone (behind the gate)
// ─────────────────────────────────────────────

struct ParentZoneView: View {
    let onClose: () -> Void

    @ObservedObject private var store = PurchaseManager.shared
    @ObservedObject private var progress = StickerStore.shared
    @ObservedObject private var settings = SettingsStore.shared
    @Environment(\.requestReview) private var requestReview
    @State private var showPaywall = false
    @State private var showPrivacy = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    progressCard
                    if !store.isUnlocked { upgradeCard } else { unlockedCard }
                    settingsCard
                    tipsCard
                    aboutCard
                }
                .padding(18)
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
            }
            .background(Palette.parentBG.ignoresSafeArea())
            .navigationTitle(L10n.t("Parent Zone", "אזור הורים"))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.t("Done", "סיום"), action: onClose).font(.body.bold())
                }
            }
        }
        .navigationViewStyle(.stack)
        .environment(\.layoutDirection, L10n.direction)
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView(onClose: { showPaywall = false })
                .environment(\.layoutDirection, L10n.direction)
        }
        .sheet(isPresented: $showPrivacy) { PrivacyPolicyView() }
        .onAppear(perform: maybeAskForReview)
    }

    // MARK: Cards

    private var progressCard: some View {
        let heard = progress.heardWords.count
        let total = ALL_WORDS.count
        return card {
            VStack(alignment: .leading, spacing: 14) {
                Label(L10n.t("Your child's progress", "ההתקדמות של הילד/ה"), systemImage: "chart.bar.fill")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(Palette.parentInk)
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(L10n.t("Words heard", "מילים שנשמעו"))
                        Spacer()
                        Text("\(heard) / \(total)").bold()
                    }
                    .font(.system(size: 15, design: .rounded))
                    ProgressView(value: Double(heard), total: Double(total))
                        .tint(Palette.accent)
                }
                HStack(spacing: 12) {
                    stat("🏆", "\(progress.stickers.count)", L10n.t("stickers", "מדבקות"))
                    stat("🔥", "\(progress.streak)", L10n.t("day streak", "ימים ברצף"))
                    stat("🎮", "\(progress.gamesFinished)", L10n.t("rounds done", "סבבים"))
                }
            }
        }
    }

    private func stat(_ icon: String, _ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(icon).font(.system(size: 22))
            Text(value).font(.system(size: 20, weight: .heavy, design: .rounded)).foregroundColor(Palette.parentInk)
            Text(label).font(.system(size: 12, weight: .medium, design: .rounded)).foregroundColor(Palette.parentInk.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 14).fill(Palette.parentBG))
    }

    private var upgradeCard: some View {
        Button { showPaywall = true } label: {
            HStack(spacing: 14) {
                Text("🔓").font(.system(size: 32))
                VStack(alignment: .leading, spacing: 3) {
                    Text(L10n.t("Unlock all \(ALL_WORDS.count) words", "פתחו את כל \(ALL_WORDS.count) המילים"))
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                    Text(L10n.t("Vehicles, Food & Colors · one-time purchase", "כלי תחבורה, אוכל וצבעים · רכישה חד-פעמית"))
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .opacity(0.85)
                }
                Spacer()
                Image(systemName: L10n.isHebrew ? "chevron.left" : "chevron.right").font(.system(size: 15, weight: .bold))
            }
            .foregroundColor(.white)
            .padding(18)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(LinearGradient(colors: [Color(hex: "#7C4DFF"), Palette.accent], startPoint: .leading, endPoint: .trailing)))
            .shadow(color: Palette.accent.opacity(0.3), radius: 10, y: 5)
        }
        .buttonStyle(SquishyButtonStyle(scale: 0.98))
    }

    private var unlockedCard: some View {
        card {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.seal.fill").font(.system(size: 26)).foregroundColor(Color(hex: "#43A047"))
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.t("Full version unlocked", "הגרסה המלאה פתוחה"))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                    Text(L10n.t("Thank you for your support!", "תודה על התמיכה!"))
                        .font(.system(size: 13, design: .rounded)).foregroundColor(Palette.parentInk.opacity(0.6))
                }
                Spacer()
            }
        }
    }

    private var settingsCard: some View {
        card {
            VStack(spacing: 0) {
                Toggle(isOn: $settings.soundEffectsOn) {
                    Label(L10n.t("Sound effects", "אפקטים קוליים"), systemImage: "speaker.wave.2.fill")
                }
                .tint(Palette.accent)
                .padding(.vertical, 6)
                Divider().padding(.vertical, 6)
                Button {
                    Task { await store.restore() }
                } label: {
                    HStack {
                        Label(L10n.t("Restore purchase", "שחזור רכישה"), systemImage: "arrow.clockwise")
                        Spacer()
                        if store.isPurchasing { ProgressView() }
                    }
                }
                .padding(.vertical, 6)
            }
            .font(.system(size: 16, weight: .medium, design: .rounded))
            .foregroundColor(Palette.parentInk)
        }
        .alert(L10n.t("Restore", "שחזור"),
               isPresented: Binding(get: { store.errorMessage != nil && !showPaywall },
                                    set: { if !$0 { store.errorMessage = nil } }),
               actions: { Button(L10n.t("OK", "אישור"), role: .cancel) {} },
               message: { Text(store.errorMessage ?? "") })
    }

    private var tipsCard: some View {
        card {
            VStack(alignment: .leading, spacing: 12) {
                Label(L10n.t("Tips for parents", "טיפים להורים"), systemImage: "lightbulb.fill")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                tip("🫧", L10n.t("Bubbles is a calm warm-up: every touch makes a sound and there's no way to fail.",
                                 "הבועות הן חימום רגוע: כל נגיעה משמיעה צליל, ואין דרך להיכשל."))
                tip("🔍", L10n.t("Find it! starts with 2 pictures and grows to 4 as your child gets it right.",
                                 "Find it! מתחיל עם 2 תמונות ומתקדם עד 4 ככל שהילד מצליח."))
                tip("🗣️", L10n.t("Say the word together with the app and point at the picture — that's when the magic happens.",
                                 "אמרו את המילה יחד עם האפליקציה והצביעו על התמונה — שם קורה הקסם."))
                tip("🏠", L10n.t("To leave a game, press and hold the house button for a moment.",
                                 "כדי לצאת ממשחק, לחצו לחיצה ארוכה על כפתור הבית."))
                tip("🔒", L10n.t("Keep your child inside the app with Guided Access: Settings → Accessibility → Guided Access, then triple-click the side button.",
                                 "כדי שהילד יישאר באפליקציה, הפעילו גישה מודרכת: הגדרות ← נגישות ← גישה מודרכת, ואז לחיצה משולשת על הכפתור הצדדי."))
            }
            .foregroundColor(Palette.parentInk)
        }
    }

    private func tip(_ icon: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(icon).font(.system(size: 18))
            Text(text).font(.system(size: 14, design: .rounded)).foregroundColor(Palette.parentInk.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var aboutCard: some View {
        card {
            VStack(spacing: 0) {
                row(L10n.t("Privacy policy", "מדיניות פרטיות"), "hand.raised.fill") { showPrivacy = true }
                Divider().padding(.vertical, 6)
                row(L10n.t("Rate Baby English", "דרגו את Baby English"), "star.fill") { requestReview() }
                Divider().padding(.vertical, 6)
                HStack {
                    Label(L10n.t("Version", "גרסה"), systemImage: "info.circle")
                    Spacer()
                    Text(AppInfo.version).foregroundColor(Palette.parentInk.opacity(0.5))
                }
                .padding(.vertical, 6)
            }
            .font(.system(size: 16, weight: .medium, design: .rounded))
            .foregroundColor(Palette.parentInk)
        }
    }

    private func row(_ title: String, _ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Label(title, systemImage: icon)
                Spacer()
                Image(systemName: L10n.isHebrew ? "chevron.left" : "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Palette.parentInk.opacity(0.3))
            }
            .contentShape(Rectangle())
        }
        .padding(.vertical, 6)
    }

    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.white))
            .shadow(color: .black.opacity(0.04), radius: 8, y: 3)
    }

    /// Ask happy, engaged parents (inside the gate) for a rating — ratings drive App Store conversion.
    private func maybeAskForReview() {
        let key = "didAskReview"
        guard !UserDefaults.standard.bool(forKey: key),
              progress.heardWords.count >= 10, progress.stickers.count >= 2 else { return }
        UserDefaults.standard.set(true, forKey: key)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { requestReview() }
    }
}
