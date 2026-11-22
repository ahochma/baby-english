import SwiftUI

// ─────────────────────────────────────────────
// MARK: - Paywall (parent-facing, always behind the gate)
// ─────────────────────────────────────────────

struct PaywallView: View {
    let onClose: () -> Void
    @ObservedObject private var store = PurchaseManager.shared
    @State private var showPrivacy = false
    @State private var heroBob = false

    var body: some View {
        GeometryReader { geo in
            let u = min(layoutUnit(geo.size), 1.35)
            ZStack {
                Palette.parentBG.ignoresSafeArea()

                if store.isUnlocked {
                    successView(u: u)
                        .transition(.scale(scale: 0.9).combined(with: .opacity))
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20 * u) {
                            hero(u: u)
                            titleBlock(u: u)
                            benefits(u: u)
                            purchaseBlock(u: u)
                            footer
                        }
                        .padding(.horizontal, 22)
                        .padding(.top, max(geo.safeAreaInsets.top, 12) + 56)
                        .padding(.bottom, max(geo.safeAreaInsets.bottom, 12) + 16)
                        .frame(maxWidth: 560)
                        .frame(maxWidth: .infinity)
                    }
                }

                VStack {
                    HStack {
                        Spacer()
                        Button(action: onClose) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Palette.parentInk.opacity(0.6))
                                .frame(width: 40, height: 40)
                                .background(Circle().fill(Color.white))
                                .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
                        }
                        .accessibilityLabel(L10n.t("Close", "סגירה"))
                    }
                    Spacer()
                }
                .padding(.top, max(geo.safeAreaInsets.top, 12) + 4)
                .padding(.horizontal, 18)
            }
            .ignoresSafeArea()
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: store.isUnlocked)
        .task { await store.loadProduct() }
        .sheet(isPresented: $showPrivacy) { PrivacyPolicyView() }
        .alert(L10n.t("Purchase", "רכישה"),
               isPresented: Binding(get: { store.errorMessage != nil }, set: { if !$0 { store.errorMessage = nil } }),
               actions: { Button(L10n.t("OK", "אישור"), role: .cancel) {} },
               message: { Text(store.errorMessage ?? "") })
        .onChange(of: store.isUnlocked) { unlocked in
            if unlocked {
                Haptics.success()
                AudioManager.shared.play("celebration")
            }
        }
    }

    // MARK: Pieces

    private func hero(u: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(LinearGradient(colors: [Color(hex: "#B39DDB"), Color(hex: "#81D4FA"), Color(hex: "#A5D6A7")],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
            let emojis = ["🐶", "🚒", "🍓", "🎨", "🦁", "🚀", "🍌", "🫧", "🐸", "🚂", "🍇", "🔍"]
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8 * u) {
                ForEach(Array(emojis.enumerated()), id: \.offset) { i, e in
                    Text(e)
                        .font(.system(size: 38 * u))
                        .frame(width: 60 * u, height: 60 * u)
                        .background(Circle().fill(Color.white.opacity(0.55)))
                        .offset(y: heroBob ? (i.isMultiple(of: 2) ? -4 : 4) : 0)
                }
            }
            .padding(18 * u)
        }
        .frame(height: 230 * u)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) { heroBob = true }
        }
        .accessibilityHidden(true)
    }

    private func titleBlock(u: CGFloat) -> some View {
        VStack(spacing: 8) {
            Text(L10n.t("Unlock all of Baby English", "פתחו את כל Baby English"))
                .font(.system(size: 28 * u, weight: .heavy, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundColor(Palette.parentInk)
            Text(L10n.t("One payment. Yours forever.", "תשלום אחד. שלכם לתמיד."))
                .font(.system(size: 17 * u, weight: .semibold, design: .rounded))
                .foregroundColor(Palette.accent)
        }
    }

    private func benefits(u: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 14 * u) {
            benefit("🌍", L10n.t("All \(ALL_CATEGORIES.count) word worlds — \(ALL_WORDS.count) first words",
                                 "כל \(ALL_CATEGORIES.count) העולמות — \(ALL_WORDS.count) מילים ראשונות"), u: u)
            benefit("🫧", L10n.t("Every word inside Bubbles and Find it!",
                                 "כל המילים בתוך משחקי הבועות ו-Find it!"), u: u)
            benefit("🗣️", L10n.t("A clear, friendly English voice for every word",
                                 "קול באנגלית ברור וחם לכל מילה"), u: u)
            benefit("🛡️", L10n.t("No ads. No tracking. No subscription.",
                                 "בלי פרסומות. בלי מעקב. בלי מנוי."), u: u)
            benefit("👨‍👩‍👧", L10n.t("Family Sharing — every device in your family",
                                   "שיתוף משפחתי — לכל המכשירים במשפחה"), u: u)
        }
        .padding(20 * u)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Color.white))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 3)
    }

    private func benefit(_ icon: String, _ text: String, u: CGFloat) -> some View {
        HStack(alignment: .center, spacing: 14) {
            Text(icon).font(.system(size: 24 * u))
                .frame(width: 34 * u)
            Text(text)
                .font(.system(size: 16 * u, weight: .semibold, design: .rounded))
                .foregroundColor(Palette.parentInk)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    private func purchaseBlock(u: CGFloat) -> some View {
        VStack(spacing: 10) {
            Button {
                Task { await store.purchase() }
            } label: {
                ZStack {
                    if store.isPurchasing {
                        ProgressView().tint(.white)
                    } else if let price = store.displayPrice {
                        Text(L10n.t("Unlock everything · \(price)", "לפתוח הכל · \(price)"))
                    } else if store.loadState == .failed {
                        Text(L10n.t("Try again", "נסו שוב"))
                    } else {
                        ProgressView().tint(.white)
                    }
                }
                .font(.system(size: 19 * u, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 60 * u)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(LinearGradient(colors: [Color(hex: "#7C4DFF"), Palette.accent],
                                             startPoint: .leading, endPoint: .trailing))
                )
                .shadow(color: Palette.accent.opacity(0.4), radius: 12, y: 6)
            }
            .buttonStyle(SquishyButtonStyle(scale: 0.97))
            .disabled(store.isPurchasing || (store.product == nil && store.loadState == .loading))

            Text(L10n.t("One-time purchase. No subscription, nothing renews.",
                        "רכישה חד-פעמית. ללא מנוי, שום דבר לא מתחדש."))
                .font(.system(size: 13 * u, weight: .medium, design: .rounded))
                .foregroundColor(Palette.parentInk.opacity(0.55))
                .multilineTextAlignment(.center)

            Text(L10n.t("Animals and all games stay free forever.",
                        "עולם החיות וכל המשחקים נשארים בחינם לתמיד."))
                .font(.system(size: 13 * u, weight: .medium, design: .rounded))
                .foregroundColor(Palette.parentInk.opacity(0.55))
                .multilineTextAlignment(.center)
        }
    }

    private var footer: some View {
        HStack(spacing: 18) {
            Button(L10n.t("Restore purchase", "שחזור רכישה")) {
                Task { await store.restore() }
            }
            Text("·").foregroundColor(Palette.parentInk.opacity(0.3))
            Button(L10n.t("Privacy", "פרטיות")) { showPrivacy = true }
            Text("·").foregroundColor(Palette.parentInk.opacity(0.3))
            Link(L10n.t("Terms", "תנאים"), destination: AppInfo.termsURL)
        }
        .font(.system(size: 14, weight: .semibold, design: .rounded))
        .foregroundColor(Palette.accent)
        .disabled(store.isPurchasing)
    }

    private func successView(u: CGFloat) -> some View {
        ZStack {
            ConfettiView().ignoresSafeArea()
            VStack(spacing: 18 * u) {
                Text("🎉").font(.system(size: 90 * u))
                Text(L10n.t("Everything is unlocked!", "הכל פתוח!"))
                    .font(.system(size: 30 * u, weight: .heavy, design: .rounded))
                    .foregroundColor(Palette.parentInk)
                Text(L10n.t("Thank you for supporting a small, ad-free app for little ones.",
                            "תודה שתמכתם באפליקציה קטנה וללא פרסומות לקטנטנים."))
                    .font(.system(size: 16 * u, weight: .medium, design: .rounded))
                    .foregroundColor(Palette.parentInk.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                Button(action: onClose) {
                    Text(L10n.t("Let's play!", "בואו נשחק!"))
                        .font(.system(size: 20 * u, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 44)
                        .frame(height: 58 * u)
                        .background(Capsule().fill(Color(hex: "#43A047")))
                }
                .buttonStyle(SquishyButtonStyle())
                .padding(.top, 8)
            }
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - App info & privacy policy
// ─────────────────────────────────────────────

enum AppInfo {
    /// Apple's standard license agreement — fine for a one-time purchase.
    static let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    static var version: String {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let b = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(v) (\(b))"
    }
}

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    section(L10n.t("The short version", "בקצרה"),
                            L10n.t("Baby English collects no personal data. There are no accounts, no ads, no analytics and no tracking. Nothing your child does in the app ever leaves the device.",
                                   "Baby English לא אוספת שום מידע אישי. אין חשבונות, אין פרסומות, אין אנליטיקה ואין מעקב. שום דבר שהילד עושה באפליקציה לא יוצא מהמכשיר."))
                    section(L10n.t("What is stored on the device", "מה נשמר במכשיר"),
                            L10n.t("Stickers earned, which words were heard, the play streak and your sound setting are saved only on this device so progress isn't lost. Deleting the app deletes them.",
                                   "המדבקות שנאספו, המילים שנשמעו, רצף הימים והגדרת הצלילים נשמרים רק במכשיר הזה כדי שההתקדמות לא תאבד. מחיקת האפליקציה מוחקת אותם."))
                    section(L10n.t("Purchases", "רכישות"),
                            L10n.t("Purchases are handled entirely by Apple. We never see your name, email or payment details.",
                                   "הרכישות מטופלות במלואן על ידי Apple. אנחנו לא רואים את השם, האימייל או פרטי התשלום שלכם."))
                    section(L10n.t("Children", "ילדים"),
                            L10n.t("The app is designed for children under 5 and complies with COPPA and GDPR-K: no data is collected from children. Purchases and links are behind a parental gate.",
                                   "האפליקציה מיועדת לילדים מתחת לגיל 5 ועומדת ב-COPPA וב-GDPR-K: לא נאסף שום מידע מילדים. רכישות וקישורים נמצאים מאחורי שער הורים."))
                    section(L10n.t("Contact", "יצירת קשר"),
                            L10n.t("Questions? Use the support link on our App Store page.",
                                   "שאלות? השתמשו בקישור התמיכה בעמוד האפליקציה ב-App Store."))
                }
                .padding(22)
            }
            .background(Palette.parentBG.ignoresSafeArea())
            .navigationTitle(L10n.t("Privacy", "פרטיות"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.t("Done", "סיום")) { dismiss() }
                }
            }
        }
        .navigationViewStyle(.stack)
        .environment(\.layoutDirection, L10n.direction)
    }

    private func section(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.system(size: 17, weight: .bold, design: .rounded))
            Text(body).font(.system(size: 15, design: .rounded)).foregroundColor(Palette.parentInk.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
