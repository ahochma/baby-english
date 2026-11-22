import SwiftUI

// ─────────────────────────────────────────────
// MARK: - Sticker Board
// ─────────────────────────────────────────────

struct StickerBoardView: View {
    @ObservedObject var stickerStore: StickerStore
    let onBack: () -> Void

    @State private var appeared = false
    @State private var bounced: Int?

    private var slots: Int {
        // Always show the next empty row(s) so there is something to look forward to.
        max(24, ((stickerStore.stickers.count / 12) + 1) * 12)
    }

    var body: some View {
        GeometryReader { geo in
            let u = layoutUnit(geo.size)
            let cols = geo.size.width > 700 ? 6 : 4
            ZStack {
                LinearGradient(colors: [Color(hex: "#FFF8E1"), Color(hex: "#FFECB3")],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                VStack(spacing: 12 * u) {
                    HStack(alignment: .center) {
                        ChunkyButton(colors: [.white, Color(hex: "#FFF3D6")], lip: Color(hex: "#E8C77A"),
                                     radius: 26 * u, depth: 5 * u, action: onBack) {
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.backward")
                                    .font(.system(size: 18 * u, weight: .heavy))
                                    .foregroundColor(Color(hex: "#5D4037"))
                                Text("🏠").font(.system(size: 26 * u))
                            }
                        }
                        .frame(width: 96 * u, height: 58 * u)
                        .accessibilityLabel(L10n.t("Back", "חזרה"))
                        Spacer()
                        Mascot(mood: stickerStore.stickers.isEmpty ? .idle : .happy)
                            .frame(width: 70 * u, height: 70 * u)
                    }

                    Text("🏆 My Stickers")
                        .font(.system(size: 34 * u, weight: .black, design: .rounded))
                        .foregroundColor(Color(hex: "#E65100"))
                        .shadow(color: .white, radius: 0, x: 0, y: 2.5)
                    Text("\(stickerStore.stickers.count)")
                        .font(.system(size: 20 * u, weight: .heavy, design: .rounded))
                        .foregroundColor(Color(hex: "#8D6E63"))
                        .padding(.horizontal, 14).padding(.vertical, 4)
                        .background(Capsule().fill(Color.white.opacity(0.7)))

                    ScrollView(showsIndicators: false) {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12 * u), count: cols),
                                  spacing: 12 * u) {
                            ForEach(0..<slots, id: \.self) { i in
                                slot(i, u: u)
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.bottom, 24)
                    }
                }
                .padding(.top, max(geo.safeAreaInsets.top, 12) + 8)
                .padding(.horizontal, 20 * u)
                .frame(maxWidth: 900)
                .frame(maxWidth: .infinity)
            }
            .ignoresSafeArea(edges: .top)
        }
        .onAppear { appeared = true }
    }

    @ViewBuilder
    private func slot(_ i: Int, u: CGFloat) -> some View {
        let has = i < stickerStore.stickers.count
        let isNewest = has && i == stickerStore.stickers.count - 1
        ZStack {
            RoundedRectangle(cornerRadius: 18 * u, style: .continuous)
                .fill(has ? Color.white : Color.white.opacity(0.45))
                .shadow(color: Color.black.opacity(has ? 0.07 : 0), radius: 4, y: 2)
            if has {
                Text(stickerStore.stickers[i])
                    .font(.system(size: 46 * u))
                    .scaleEffect(appeared ? (bounced == i ? 1.35 : 1.0) : 0.3)
                    .rotationEffect(.degrees(bounced == i ? 12 : 0))
                    .animation(.spring(response: 0.4, dampingFraction: 0.45)
                                .delay(appeared && bounced == nil ? min(Double(i) * 0.03, 0.8) : 0),
                               value: appeared)
                    .animation(.spring(response: 0.3, dampingFraction: 0.4), value: bounced)
                if isNewest {
                    Text("NEW")
                        .font(.system(size: 10 * u, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Capsule().fill(Color(hex: "#EF5350")))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .padding(6)
                }
            } else {
                Image(systemName: "star.fill")
                    .font(.system(size: 22 * u))
                    .foregroundColor(Color(hex: "#FFE082"))
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .onTapGesture {
            guard has else { return }
            bounced = i
            Haptics.tap()
            AudioManager.shared.play(.sparkle, volume: 0.5)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { if bounced == i { bounced = nil } }
        }
        .accessibilityLabel(has ? stickerStore.stickers[i] : L10n.t("Empty", "ריק"))
    }
}
