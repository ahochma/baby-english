import SwiftUI

// ─────────────────────────────────────────────
// MARK: - Sticker Albums
// ─────────────────────────────────────────────
//
// One album page per world plus "Surprises" for Pip's daily gifts. Missing
// stickers show as soft silhouettes, so a child can see what's still to
// collect and has a reason to play that world again.

struct StickerAlbum: Identifiable {
    let id: String
    let title: String
    let emoji: String
    let color: Color
    let pool: [String]
}

struct StickerBoardView: View {
    @ObservedObject var stickerStore: StickerStore
    let onBack: () -> Void

    @State private var appeared = false
    @State private var bounced: String?

    private var albums: [StickerAlbum] {
        var list = ALL_CATEGORIES.map {
            StickerAlbum(id: $0.id, title: $0.label, emoji: $0.emoji, color: $0.gradientEnd, pool: $0.stickerPool)
        }
        list.append(StickerAlbum(id: "gifts", title: "Surprises", emoji: "🎁",
                                 color: Color(hex: "#E8458B"), pool: StickerStore.giftPool))
        // Stickers won in games that aren't part of any album page.
        let inAlbums = Set(list.flatMap(\.pool))
        var extras: [String] = []
        for s in stickerStore.stickers where !inAlbums.contains(s) && !extras.contains(s) { extras.append(s) }
        if !extras.isEmpty {
            list.append(StickerAlbum(id: "extras", title: "Extras", emoji: "⭐",
                                     color: Color(hex: "#FB8C00"), pool: extras))
        }
        return list
    }

    var body: some View {
        GeometryReader { geo in
            let u = layoutUnit(geo.size)
            let cols = geo.size.width > 700 ? 6 : 4
            let owned = Set(stickerStore.stickers)
            ZStack {
                LinearGradient(colors: [Color(hex: "#FFF8E1"), Color(hex: "#FFECB3")],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                VStack(spacing: 10 * u) {
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
                        VStack(spacing: 0) {
                            Text("🏆 My Stickers")
                                .font(.system(size: 26 * u, weight: .black, design: .rounded))
                                .foregroundColor(Color(hex: "#E65100"))
                                .shadow(color: .white, radius: 0, x: 0, y: 2)
                                .lineLimit(1).minimumScaleFactor(0.7)
                            Text("\(owned.count) / \(albums.filter { $0.id != "extras" }.reduce(0) { $0 + $1.pool.count })")
                                .font(.system(size: 15 * u, weight: .heavy, design: .rounded))
                                .foregroundColor(Color(hex: "#8D6E63"))
                        }
                        .accessibilityElement(children: .combine)
                        Spacer()
                        Mascot(mood: stickerStore.stickers.isEmpty ? .idle : .happy)
                            .frame(width: 64 * u, height: 64 * u)
                    }

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16 * u) {
                            ForEach(albums) { album in
                                albumCard(album, owned: owned, cols: cols, u: u)
                            }
                        }
                        .padding(.vertical, 6)
                        .padding(.bottom, max(geo.safeAreaInsets.bottom, 12) + 16)
                    }
                }
                .padding(.top, max(geo.safeAreaInsets.top, 12) + 8)
                .padding(.horizontal, 18 * u)
                .frame(maxWidth: 900)
                .frame(maxWidth: .infinity)
            }
            .ignoresSafeArea(edges: [.top, .bottom])
        }
        .onAppear { appeared = true }
    }

    private func albumCard(_ album: StickerAlbum, owned: Set<String>, cols: Int, u: CGFloat) -> some View {
        let have = album.pool.filter { owned.contains($0) }.count
        let complete = have == album.pool.count
        return VStack(alignment: .leading, spacing: 10 * u) {
            HStack(spacing: 8 * u) {
                Text(album.emoji).font(.system(size: 24 * u))
                Text(album.title)
                    .font(.system(size: 20 * u, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Text(complete ? "⭐️ \(have)/\(album.pool.count)" : "\(have)/\(album.pool.count)")
                    .font(.system(size: 15 * u, weight: .heavy, design: .rounded))
                    .foregroundColor(album.color)
                    .padding(.horizontal, 10).padding(.vertical, 3)
                    .background(Capsule().fill(Color.white))
            }
            .padding(.horizontal, 14 * u)
            .padding(.vertical, 8 * u)
            .background(RoundedRectangle(cornerRadius: 18 * u, style: .continuous).fill(album.color))
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(album.title), \(have) of \(album.pool.count)")

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10 * u), count: cols), spacing: 10 * u) {
                ForEach(Array(album.pool.enumerated()), id: \.offset) { i, sticker in
                    slot(sticker, owned: owned.contains(sticker), index: i, u: u)
                }
            }
        }
        .padding(12 * u)
        .background(
            RoundedRectangle(cornerRadius: 26 * u, style: .continuous)
                .fill(Color.white.opacity(0.55))
        )
    }

    @ViewBuilder
    private func slot(_ sticker: String, owned: Bool, index: Int, u: CGFloat) -> some View {
        let isNewest = owned && stickerStore.stickers.last == sticker
        ZStack {
            RoundedRectangle(cornerRadius: 16 * u, style: .continuous)
                .fill(owned ? Color.white : Color.white.opacity(0.5))
                .shadow(color: Color.black.opacity(owned ? 0.07 : 0), radius: 4, y: 2)
            if owned {
                Text(sticker)
                    .font(.system(size: 40 * u))
                    .scaleEffect(appeared ? (bounced == sticker ? 1.35 : 1.0) : 0.3)
                    .rotationEffect(.degrees(bounced == sticker ? 12 : 0))
                    .animation(.spring(response: 0.4, dampingFraction: 0.45)
                                .delay(appeared && bounced == nil ? min(Double(index) * 0.03, 0.4) : 0),
                               value: appeared)
                    .animation(.spring(response: 0.3, dampingFraction: 0.4), value: bounced)
                if isNewest {
                    Text("NEW")
                        .font(.system(size: 9 * u, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 5).padding(.vertical, 2)
                        .background(Capsule().fill(Color(hex: "#EF5350")))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .padding(4)
                }
            } else {
                // silhouette of the sticker still to win
                Text(sticker)
                    .font(.system(size: 34 * u))
                    .saturation(0)
                    .colorMultiply(Color(hex: "#5D4037"))
                    .opacity(0.13)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .onTapGesture {
            Haptics.tap()
            if owned {
                bounced = sticker
                AudioManager.shared.play(.sparkle, volume: 0.5)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { if bounced == sticker { bounced = nil } }
            } else {
                AudioManager.shared.play(.tap, volume: 0.3)
            }
        }
        .accessibilityLabel(owned ? sticker : L10n.t("Not collected yet", "עוד לא נאסף"))
    }
}
