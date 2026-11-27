import SwiftUI
import AppKit

struct ABCBubble: View {
    var size: CGFloat
    var body: some View {
        ZStack {
            // speech bubble
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(Color.white)
                .frame(width: size * 1.5, height: size * 0.82)
                .shadow(color: .black.opacity(0.18), radius: size * 0.05, y: size * 0.03)
            Triangle().fill(Color.white)
                .frame(width: size * 0.26, height: size * 0.22)
                .rotationEffect(.degrees(200))
                .offset(x: -size * 0.42, y: size * 0.46)
            HStack(spacing: -size * 0.03) {
                Text("A").foregroundColor(Color(hex: "#FF5A5F"))
                Text("B").foregroundColor(Color(hex: "#2E9BF0"))
                Text("C").foregroundColor(Color(hex: "#3DBE5A"))
            }
            .font(.system(size: size * 0.55, weight: .black, design: .rounded))
        }
    }
}
struct Triangle: Shape {
    func path(in r: CGRect) -> Path { var p = Path(); p.move(to: CGPoint(x: r.midX, y: r.minY)); p.addLine(to: CGPoint(x: r.maxX, y: r.maxY)); p.addLine(to: CGPoint(x: r.minX, y: r.maxY)); p.closeSubpath(); return p }
}
struct Hill: Shape {
    var base: CGFloat
    func path(in r: CGRect) -> Path {
        var p = Path(); let y = r.height * base
        p.move(to: CGPoint(x: 0, y: y + r.height * 0.03))
        p.addCurve(to: CGPoint(x: r.width, y: y), control1: CGPoint(x: r.width * 0.3, y: y - r.height * 0.07), control2: CGPoint(x: r.width * 0.7, y: y + r.height * 0.05))
        p.addLine(to: CGPoint(x: r.width, y: r.height)); p.addLine(to: CGPoint(x: 0, y: r.height)); p.closeSubpath(); return p
    }
}
struct Cloud: View {
    var w: CGFloat
    var body: some View {
        ZStack {
            Circle().frame(width: w * 0.45).offset(x: -w * 0.2, y: w * 0.05)
            Circle().frame(width: w * 0.6).offset(x: w * 0.02, y: -w * 0.06)
            Circle().frame(width: w * 0.42).offset(x: w * 0.25, y: w * 0.06)
        }.foregroundColor(.white)
    }
}

// A: Pip on a sunny meadow with an ABC speech bubble
struct IconA: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "#5CC8FF"), Color(hex: "#A8E4FF")], startPoint: .top, endPoint: .bottom)
            Circle().fill(Color(hex: "#FFE36E")).frame(width: 300).position(x: 900, y: 110).opacity(0.9)
            Cloud(w: 300).opacity(0.85).position(x: 150, y: 210)
            Hill(base: 0.80).fill(Color(hex: "#7AD957"))
            Mascot(mood: .idle).frame(width: 700, height: 700).position(x: 470, y: 600)
            ABCBubble(size: 230).position(x: 790, y: 260)
        }
        .frame(width: 1024, height: 1024)
    }
}
// D: hybrid of A and B: meadow world, big Pip, ABC bubble
struct IconD: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "#4FC0FF"), Color(hex: "#9FE0FF")], startPoint: .top, endPoint: .bottom)
            Circle().fill(Color(hex: "#FFE36E")).frame(width: 260).position(x: 930, y: 90)
            Hill(base: 0.84).fill(Color(hex: "#79D957"))
            Mascot(mood: .idle).frame(width: 860, height: 860).position(x: 480, y: 640)
            ABCBubble(size: 250).position(x: 770, y: 205)
        }
        .frame(width: 1024, height: 1024)
    }
}
// Launch screen: same world, Pip centred (2732² image, aspect-filled, so keep content central)
struct SplashView: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "#7FD3FF"), Color(hex: "#D8F3FF")], startPoint: .top, endPoint: .bottom)
            Hill(base: 0.78).fill(Color(hex: "#A6E36B"))
            Hill(base: 0.84).fill(Color(hex: "#79D957"))
            Mascot(mood: .idle).frame(width: 900, height: 900).position(x: 1366, y: 1300)
        }
        .frame(width: 2732, height: 2732)
    }
}
// B: Big Pip face on warm gradient with ABC bubble
struct IconB: View {
    var body: some View {
        ZStack {
            RadialGradient(colors: [Color(hex: "#FFB3D1"), Color(hex: "#FF6FA5")], center: .topLeading, startRadius: 50, endRadius: 1300)
            Circle().fill(Color.white.opacity(0.18)).frame(width: 760).position(x: 512, y: 600)
            Mascot(mood: .idle).frame(width: 860, height: 860).position(x: 500, y: 640)
            ABCBubble(size: 250).position(x: 760, y: 200)
        }
        .frame(width: 1024, height: 1024)
    }
}
// C: Pip inside a soap bubble on purple-blue
struct IconC: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "#8C6BFF"), Color(hex: "#3FA9F5")], startPoint: .topLeading, endPoint: .bottomTrailing)
            Circle()
                .fill(RadialGradient(colors: [.white.opacity(0.05), .white.opacity(0.28)], center: .center, startRadius: 100, endRadius: 420))
                .overlay(Circle().stroke(LinearGradient(colors: [.white, Color(hex: "#FFD1E8"), Color(hex: "#B3E5FC")], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 22))
                .frame(width: 800, height: 800).position(x: 512, y: 540)
            Ellipse().fill(Color.white.opacity(0.8)).frame(width: 170, height: 80).rotationEffect(.degrees(-35)).position(x: 290, y: 280)
            Mascot(mood: .idle).frame(width: 600, height: 600).position(x: 512, y: 580)
            ABCBubble(size: 200).position(x: 800, y: 170)
        }
        .frame(width: 1024, height: 1024)
    }
}

@MainActor func render<V: View>(_ v: V, _ path: String, size: Int = 1024) {
    let r = ImageRenderer(content: v)
    r.scale = 1
    guard let cg = r.cgImage else { print("render failed", path); return }
    let cs = CGColorSpace(name: CGColorSpace.sRGB)!
    let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0, space: cs, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    ctx.draw(cg, in: CGRect(x: 0, y: 0, width: size, height: size))
    try! NSBitmapImageRep(cgImage: ctx.makeImage()!).representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: path))
    print("wrote", path)
}
@main struct Runner {
    @MainActor static func main() {
        render(IconA(), "iconA.png"); render(IconB(), "iconB.png"); render(IconC(), "iconC.png"); render(IconD(), "iconD.png"); render(SplashView(), "splash.png", size: 2732)
    }
}
