import SwiftUI

// ─────────────────────────────────────────────
// MARK: - Parental Gate
// ─────────────────────────────────────────────
//
// Required by App Store Review Guidelines 1.3 & 5.1.4 for the Kids Category:
// purchases, settings and links must sit behind a gate a young child can't pass.
// A multiplication question with a number pad is the standard approach.

struct ParentalGateView: View {
    let onPass: () -> Void
    let onCancel: () -> Void

    @State private var a = Int.random(in: 3...9)
    @State private var b = Int.random(in: 4...9)
    @State private var entry = ""
    @State private var shakes = 0
    @State private var wrong = false

    private var answer: Int { a * b }

    var body: some View {
        GeometryReader { geo in
            let u = min(layoutUnit(geo.size), 1.3)
            ZStack {
                Palette.parentBG.ignoresSafeArea()

                VStack(spacing: 18 * u) {
                    HStack {
                        Spacer()
                        Button(action: onCancel) {
                            Image(systemName: "xmark")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(Palette.parentInk.opacity(0.6))
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(Color.white))
                        }
                        .accessibilityLabel(L10n.t("Close", "סגירה"))
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "person.2.fill")
                        .font(.system(size: 34 * u))
                        .foregroundColor(Palette.accent)
                    Text(L10n.t("For grown-ups", "למבוגרים בלבד"))
                        .font(.system(size: 28 * u, weight: .heavy, design: .rounded))
                        .foregroundColor(Palette.parentInk)
                    Text(L10n.t("To continue, enter the answer:", "כדי להמשיך, הקלידו את התשובה:"))
                        .font(.system(size: 16 * u, weight: .medium, design: .rounded))
                        .foregroundColor(Palette.parentInk.opacity(0.65))

                    HStack(spacing: 10) {
                        Text("\(a) × \(b) =")
                            .environment(\.layoutDirection, .leftToRight)
                        Text(entry.isEmpty ? "?" : entry)
                            .foregroundColor(wrong ? Color(hex: "#E53935") : Palette.accent)
                            .frame(minWidth: 56)
                    }
                    .font(.system(size: 40 * u, weight: .bold, design: .rounded))
                    .foregroundColor(Palette.parentInk)
                    .environment(\.layoutDirection, .leftToRight)
                    .modifier(ShakeEffect(shakes: CGFloat(shakes)))
                    .accessibilityElement(children: .combine)

                    keypad(u: u)
                        .frame(maxWidth: 340 * u)

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 24)
                .padding(.top, max(geo.safeAreaInsets.top, 12))
                .padding(.bottom, max(geo.safeAreaInsets.bottom, 12) + 8)
            }
            .ignoresSafeArea()
        }
    }

    private func keypad(u: CGFloat) -> some View {
        let keys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "", "0", "⌫"]
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
            ForEach(Array(keys.enumerated()), id: \.offset) { _, k in
                if k.isEmpty {
                    Color.clear.frame(height: 58 * u)
                } else {
                    Button { press(k) } label: {
                        Group {
                            if k == "⌫" {
                                Image(systemName: "delete.left").font(.system(size: 22 * u, weight: .semibold))
                            } else {
                                Text(k).font(.system(size: 26 * u, weight: .semibold, design: .rounded))
                            }
                        }
                        .foregroundColor(Palette.parentInk)
                        .frame(maxWidth: .infinity)
                        .frame(height: 58 * u)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.white))
                        .shadow(color: .black.opacity(0.05), radius: 3, y: 1)
                    }
                    .buttonStyle(SquishyButtonStyle(scale: 0.95))
                    .accessibilityLabel(k == "⌫" ? L10n.t("Delete", "מחיקה") : k)
                }
            }
        }
        .environment(\.layoutDirection, .leftToRight)
    }

    private func press(_ k: String) {
        wrong = false
        if k == "⌫" {
            if !entry.isEmpty { entry.removeLast() }
            return
        }
        guard entry.count < 3 else { return }
        entry += k
        let target = String(answer)
        if entry.count >= target.count {
            if entry == target {
                Haptics.success()
                onPass()
            } else {
                wrong = true
                withAnimation(.linear(duration: 0.4)) { shakes += 1 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    entry = ""
                    wrong = false
                    a = Int.random(in: 3...9)
                    b = Int.random(in: 4...9)
                }
            }
        }
    }
}
