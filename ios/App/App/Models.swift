import SwiftUI

// ─────────────────────────────────────────────
// MARK: - Data Model
// ─────────────────────────────────────────────

struct WordItem: Identifiable, Hashable {
    let id: String
    let label: String
    let emoji: String
    let bg: Color
    let textColor: Color
}

struct Category: Identifiable, Hashable {
    let id: String
    let label: String
    let emoji: String
    let gradientStart: Color
    let gradientEnd: Color
    let words: [WordItem]
    let stickerPool: [String]

    /// The free tier ships with one complete category so families can try every game.
    var isFree: Bool { id == FREE_CATEGORY_ID }

    static func == (lhs: Category, rhs: Category) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

let FREE_CATEGORY_ID = "animals"

// ─────────────────────────────────────────────
// MARK: - Categories Data
// ─────────────────────────────────────────────

let ALL_CATEGORIES: [Category] = [
    Category(id: "animals", label: "Animals", emoji: "🐶",
             gradientStart: Color(hex: "#66BB6A"), gradientEnd: Color(hex: "#2E7D32"),
             words: [
                WordItem(id:"dog",   label:"Dog",      emoji:"🐶", bg:Color(hex:"#FFF8E1"), textColor:Color(hex:"#5D4037")),
                WordItem(id:"cat",   label:"Cat",      emoji:"🐱", bg:Color(hex:"#FCE4EC"), textColor:Color(hex:"#880E4F")),
                WordItem(id:"bird",  label:"Bird",     emoji:"🐦", bg:Color(hex:"#E3F2FD"), textColor:Color(hex:"#0D47A1")),
                WordItem(id:"fish",  label:"Fish",     emoji:"🐟", bg:Color(hex:"#E0F7FA"), textColor:Color(hex:"#006064")),
                WordItem(id:"cow",   label:"Cow",      emoji:"🐮", bg:Color(hex:"#F3E5F5"), textColor:Color(hex:"#4A148C")),
                WordItem(id:"duck",  label:"Duck",     emoji:"🦆", bg:Color(hex:"#FFFDE7"), textColor:Color(hex:"#F57F17")),
                WordItem(id:"elephant",label:"Elephant",emoji:"🐘",bg:Color(hex:"#EDE7F6"), textColor:Color(hex:"#311B92")),
                WordItem(id:"lion",  label:"Lion",     emoji:"🦁", bg:Color(hex:"#FFF3E0"), textColor:Color(hex:"#E65100")),
                WordItem(id:"frog",  label:"Frog",     emoji:"🐸", bg:Color(hex:"#E8F5E9"), textColor:Color(hex:"#1B5E20")),
                WordItem(id:"rabbit",label:"Rabbit",   emoji:"🐰", bg:Color(hex:"#FCE4EC"), textColor:Color(hex:"#880E4F")),
             ],
             stickerPool: ["🐶","🐱","🐦","🐟","🐮","🦆","🐘","🦁","🐸","🐰","🦊","🐻"]),
    Category(id: "vehicles", label: "Vehicles", emoji: "🚒",
             gradientStart: Color(hex: "#EF5350"), gradientEnd: Color(hex: "#B71C1C"),
             words: [
                WordItem(id:"firetruck",  label:"Fire Truck",  emoji:"🚒", bg:Color(hex:"#FFEBEE"), textColor:Color(hex:"#B71C1C")),
                WordItem(id:"helicopter", label:"Helicopter",  emoji:"🚁", bg:Color(hex:"#E3F2FD"), textColor:Color(hex:"#0D47A1")),
                WordItem(id:"truck",      label:"Truck",       emoji:"🚚", bg:Color(hex:"#FFF3E0"), textColor:Color(hex:"#E65100")),
                WordItem(id:"ambulance",  label:"Ambulance",   emoji:"🚑", bg:Color(hex:"#FCE4EC"), textColor:Color(hex:"#880E4F")),
                WordItem(id:"policecar",  label:"Police Car",  emoji:"🚓", bg:Color(hex:"#E8EAF6"), textColor:Color(hex:"#1A237E")),
                WordItem(id:"tractor",    label:"Tractor",     emoji:"🚜", bg:Color(hex:"#F1F8E9"), textColor:Color(hex:"#33691E")),
                WordItem(id:"train",      label:"Train",       emoji:"🚂", bg:Color(hex:"#EFEBE9"), textColor:Color(hex:"#3E2723")),
                WordItem(id:"rocket",     label:"Rocket",      emoji:"🚀", bg:Color(hex:"#EDE7F6"), textColor:Color(hex:"#311B92")),
                WordItem(id:"airplane",   label:"Airplane",    emoji:"✈️",  bg:Color(hex:"#E0F7FA"), textColor:Color(hex:"#006064")),
                WordItem(id:"bus",        label:"Bus",         emoji:"🚌", bg:Color(hex:"#FFFDE7"), textColor:Color(hex:"#F57F17")),
             ],
             stickerPool: ["🚒","🚁","🚚","🚑","🚓","🚜","🚂","🚀","✈️","🚌","🏎️","⛵"]),
    Category(id: "food", label: "Food", emoji: "🍎",
             gradientStart: Color(hex: "#FF7043"), gradientEnd: Color(hex: "#BF360C"),
             words: [
                WordItem(id:"apple",     label:"Apple",      emoji:"🍎", bg:Color(hex:"#FFEBEE"), textColor:Color(hex:"#B71C1C")),
                WordItem(id:"banana",    label:"Banana",     emoji:"🍌", bg:Color(hex:"#FFFDE7"), textColor:Color(hex:"#F57F17")),
                WordItem(id:"milk",      label:"Milk",       emoji:"🥛", bg:Color(hex:"#F5F5F5"), textColor:Color(hex:"#333333")),
                WordItem(id:"bread",     label:"Bread",      emoji:"🍞", bg:Color(hex:"#FFF8E1"), textColor:Color(hex:"#E65100")),
                WordItem(id:"egg",       label:"Egg",        emoji:"🥚", bg:Color(hex:"#FFF9C4"), textColor:Color(hex:"#F57F17")),
                WordItem(id:"orange2",   label:"Orange",     emoji:"🍊", bg:Color(hex:"#FFF3E0"), textColor:Color(hex:"#E65100")),
                WordItem(id:"strawberry",label:"Strawberry", emoji:"🍓", bg:Color(hex:"#FCE4EC"), textColor:Color(hex:"#880E4F")),
                WordItem(id:"carrot",    label:"Carrot",     emoji:"🥕", bg:Color(hex:"#FFF3E0"), textColor:Color(hex:"#E65100")),
                WordItem(id:"cake",      label:"Cake",       emoji:"🎂", bg:Color(hex:"#F8BBD0"), textColor:Color(hex:"#880E4F")),
                WordItem(id:"grapes",    label:"Grapes",     emoji:"🍇", bg:Color(hex:"#EDE7F6"), textColor:Color(hex:"#4A148C")),
             ],
             stickerPool: ["🍎","🍌","🥛","🍞","🥚","🍊","🍓","🥕","🎂","🍇","🍕","🍪"]),
    Category(id: "colors", label: "Colors", emoji: "🎨",
             gradientStart: Color(hex: "#BA68C8"), gradientEnd: Color(hex: "#6A1B9A"),
             words: [
                WordItem(id:"red",   label:"Red",    emoji:"🔴", bg:Color(hex:"#EF5350"), textColor:.white),
                WordItem(id:"blue",  label:"Blue",   emoji:"🔵", bg:Color(hex:"#42A5F5"), textColor:.white),
                WordItem(id:"green", label:"Green",  emoji:"🟢", bg:Color(hex:"#66BB6A"), textColor:.white),
                WordItem(id:"yellow",label:"Yellow", emoji:"🟡", bg:Color(hex:"#FFEE58"), textColor:Color(hex:"#333333")),
                WordItem(id:"orange",label:"Orange", emoji:"🟠", bg:Color(hex:"#FFA726"), textColor:.white),
                WordItem(id:"purple",label:"Purple", emoji:"🟣", bg:Color(hex:"#AB47BC"), textColor:.white),
                WordItem(id:"pink",  label:"Pink",   emoji:"🩷", bg:Color(hex:"#F48FB1"), textColor:.white),
                WordItem(id:"white", label:"White",  emoji:"⬜", bg:Color(hex:"#F5F5F5"), textColor:Color(hex:"#333333")),
                WordItem(id:"black", label:"Black",  emoji:"⬛", bg:Color(hex:"#424242"), textColor:.white),
                WordItem(id:"brown", label:"Brown",  emoji:"🟤", bg:Color(hex:"#8D6E63"), textColor:.white),
             ],
             stickerPool: ["🔴","🔵","🟢","🟡","🟠","🟣","🩷","⬜","⬛","🟤","🌈","🎨"]),
]

let ALL_WORDS: [WordItem] = ALL_CATEGORIES.flatMap { $0.words }
let ALL_STICKERS: [String] = ALL_CATEGORIES.flatMap { $0.stickerPool }
