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
        let total = ALL_WORDS.count
        let known = ALL_WORDS.filter { progress.isKnown($0.id) }
        let practicing = ALL_WORDS.filter { progress.isPracticing($0.id) }
        let heard = progress.heardWords.count
        return card {
            VStack(alignment: .leading, spacing: 14) {
                Label(L10n.t("Your child's progress", "ההתקדמות של הילד/ה"), systemImage: "chart.bar.fill")
                    .font(.parent(17, .bold))
                    .foregroundColor(Palette.parentInk)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(L10n.t("Words your child knows", "מילים שהילד/ה כבר יודע/ת"))
                        Spacer()
                        Text("\(known.count) / \(total)").bold()
                    }
                    .font(.parent(15))
                    ProgressView(value: Double(known.count), total: Double(total))
                        .tint(Color(hex: "#43A047"))
                    Text(L10n.t("Heard so far: \(heard) / \(total)", "נשמעו עד עכשיו: \(heard) / \(total)"))
                        .font(.parent(13))
                        .foregroundColor(Palette.parentInk.opacity(0.55))
                }
                .accessibilityElement(children: .combine)

                if known.isEmpty {
                    Text(L10n.t("Play Find it! together: a word counts as known after 2 right answers in a row.",
                                "שחקו יחד ב-Find it!: מילה נחשבת ידועה אחרי 2 תשובות נכונות ברצף."))
                        .font(.parent(13))
                        .foregroundColor(Palette.parentInk.opacity(0.65))
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    wordChips(known, color: Color(hex: "#43A047"))
                }

                if !practicing.isEmpty {
                    Text(L10n.t("Still practicing (asked more often):", "עדיין מתרגלים (יישאלו יותר):"))
                        .font(.parent(13, .semibold))
                        .foregroundColor(Palette.parentInk.opacity(0.7))
                    wordChips(practicing, color: Color(hex: "#FB8C00"))
                }

                HStack(spacing: 12) {
                    stat("🏆", "\(progress.stickers.count)", L10n.t("stickers", "מדבקות"))
                    stat("🔥", "\(progress.streak)", L10n.t("day streak", "ימים ברצף"))
                    stat("🎮", "\(progress.gamesFinished)", L10n.t("rounds done", "סבבים"))
                }
            }
        }
    }

    private func wordChips(_ words: [WordItem], color: Color) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(words) { w in
                HStack(spacing: 4) {
                    Text(w.emoji).font(.system(size: 16))
                    Text(w.label).font(.parent(13, .semibold)).lineLimit(1).minimumScaleFactor(0.7)
                }
                .foregroundColor(Palette.parentInk)
                .padding(.horizontal, 10).padding(.vertical, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Capsule().fill(color.opacity(0.14)))
                .overlay(Capsule().stroke(color.opacity(0.35), lineWidth: 1))
                .environment(\.layoutDirection, .leftToRight)
                .accessibilityElement(children: .combine)
            }
        }
    }

    private func stat(_ icon: String, _ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(icon).font(.system(size: 22))
            Text(value).font(.parent(20, .heavy)).foregroundColor(Palette.parentInk)
            Text(label).font(.parent(12, .medium)).foregroundColor(Palette.parentInk.opacity(0.6))
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
                        .font(.parent(17, .heavy))
                    Text(L10n.t("\(ALL_CATEGORIES.count - 1) more worlds · one-time purchase", "עוד \(ALL_CATEGORIES.count - 1) עולמות · רכישה חד-פעמית"))
                        .font(.parent(13, .medium))
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
                        .font(.parent(16, .bold))
                    Text(L10n.t("Thank you for your support!", "תודה על התמיכה!"))
                        .font(.parent(13)).foregroundColor(Palette.parentInk.opacity(0.6))
                }
                Spacer()
            }
        }
    }

    private var settingsCard: some View {
        card {
            VStack(spacing: 0) {
                Toggle(isOn: $settings.bilingualHebrew) {
                    VStack(alignment: .leading, spacing: 2) {
                        Label(L10n.t("Hebrew → English", "עברית ← אנגלית"), systemImage: "character.bubble.fill")
                        Text(L10n.t("Says the Hebrew word first: “כלב… Dog!”. Works best when you play together and repeat.",
                                    "אומר קודם את המילה בעברית: ״כלב… Dog!״. עובד הכי טוב כשמשחקים יחד וחוזרים על המילה."))
                            .font(.parent(13))
                            .foregroundColor(Palette.parentInk.opacity(0.55))
                    }
                }
                .tint(Palette.accent)
                .padding(.vertical, 6)
                Divider().padding(.vertical, 6)
                Toggle(isOn: $settings.calmMode) {
                    VStack(alignment: .leading, spacing: 2) {
                        Label(L10n.t("Calm mode", "מצב רגוע"), systemImage: "leaf.fill")
                        Text(L10n.t("No confetti or bouncing decorations. Good for bedtime.",
                                    "בלי קונפטי ובלי קישוטים קופצים. מתאים גם לפני השינה."))
                            .font(.parent(13))
                            .foregroundColor(Palette.parentInk.opacity(0.55))
                    }
                }
                .tint(Palette.accent)
                .padding(.vertical, 6)
                Divider().padding(.vertical, 6)
                Toggle(isOn: $settings.musicOn) {
                    Label(L10n.t("Background music", "מוזיקת רקע"), systemImage: "music.note")
                }
                .tint(Palette.accent)
                .padding(.vertical, 6)
                Divider().padding(.vertical, 6)
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
            .font(.parent(16, .medium))
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
                    .font(.parent(17, .bold))
                tip("🫧", L10n.t("Bubbles is a calm warm-up: every touch makes a sound and there's no way to fail.",
                                 "הבועות הן חימום רגוע: כל נגיעה משמיעה צליל, ואין דרך להיכשל."))
                tip("🔍", L10n.t("Find it! starts with 2 pictures and grows to 4 as your child gets it right.",
                                 "Find it! מתחיל עם 2 תמונות ומתקדם עד 4 ככל שהילד מצליח."))
                tip("👨‍👧", L10n.t("Play together when you can. Young children learn words best from a person: point at the picture, say the word with the app, then use it later in the day (\"Look, a dog!\").",
                                 "שחקו יחד כשאפשר. ילדים קטנים לומדים מילים הכי טוב מאדם: הצביעו על התמונה, אמרו את המילה יחד עם האפליקציה, ואחר כך השתמשו בה במהלך היום (״Look, a dog!״)."))
                tip("⏱️", L10n.t("Short and often beats long: 5–10 minutes a day is plenty at this age.",
                                 "קצר ולעתים קרובות עדיף על ארוך: 5–10 דקות ביום זה בדיוק מספיק בגיל הזה."))
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
            Text(text).font(.parent(14)).foregroundColor(Palette.parentInk.opacity(0.8))
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
            .font(.parent(16, .medium))
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
