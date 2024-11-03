import SwiftUI

// MARK: - Models


struct Card: Identifiable, Equatable {
    let id = UUID()
    let rank: String
    let suit: String


    var description: String {
        "\(rank) of \(suit)"
    }

    var shortDescription: String {
        "\(rank.first?.description ?? "")\(unicodeSuit)"
    }

    var suitImage: Image {
        switch suit {
        case "Hearts":
            return Image(systemName: "suit.heart.fill")
        case "Diamonds":
            return Image(systemName: "suit.diamond.fill")
        case "Spades":
            return Image(systemName: "suit.spade.fill")
        case "Clubs":
            return Image(systemName: "suit.club.fill")
        default:
            return Image(systemName: "questionmark.circle.fill")
        }
    }

    var unicodeSuit: String {
        switch suit {
        case "Hearts":
            return "♥"
        case "Diamonds":
            return "♦"
        case "Spades":
            return "♠"
        case "Clubs":
            return "♣"
        default:
            return "?"
        }
    }

    func color(uniqueColors: Bool) -> Color {
        switch suit {
        case "Hearts":
            return .suitRed
        case "Diamonds":
            return uniqueColors ? .suitBlue : .suitRed
        case "Spades":
            return .suitBlack
        case "Clubs":
            return uniqueColors ? .suitGreen : .suitBlack
        default:
            return .suitBlack
        }
    }

}


struct Deck {
    private let ranks = ["Ace", "2", "3", "4", "5", "6", "7", "8", "9", "10", "Jack", "Queen", "King"]
    private let suits = ["Hearts", "Diamonds", "Clubs", "Spades"]
    private var cards: [Card]
    let deckCount: Int

    init(numberOfDecks: Int = 1) {
        self.deckCount = numberOfDecks
        self.cards = []
        for _ in 0..<numberOfDecks {
            for suit in suits {
                for rank in ranks {
                    cards.append(Card(rank: rank, suit: suit))
                }
            }
        }
        shuffle()
    }

    mutating func shuffle() {
        cards.shuffle()
    }

    mutating func draw() -> Card? {
        guard !cards.isEmpty else { return nil }
        return cards.removeLast()
    }

    var remainingCards: Int {
        cards.count
    }
}

struct DrawEvent: Identifiable, Hashable {
    let id = UUID()
    let timestamp = Date()
    let card: Card?
    let eventType: EventType
    let deckCount: Int
    let remainingCards: Int

    enum EventType: Hashable {
        case draw
        case shuffle
    }

    // Implementation of Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: DrawEvent, rhs: DrawEvent) -> Bool {
        lhs.id == rhs.id
    }

    var description: String {
        switch eventType {
        case .draw:
            return card?.description ?? "No cards remaining"
        case .shuffle:
            return "Deck shuffled (\(deckCount) deck\(deckCount > 1 ? "s" : ""))"
        }
    }

    var formattedTime: String {
        timestamp.formatted(date: .omitted, time: .shortened)
    }
}



// MARK: - Views

struct CopyButton: View {
    let card: Card
    @AppStorage("copyWithSymbol") private var copyWithSymbol = false
    @State private var isCopied = false

    var copyText: String {
        copyWithSymbol ? card.shortDescription : card.description
    }

    var body: some View {
        Button {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(copyText, forType: .string)

            withAnimation {
                isCopied = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    isCopied = false
                }
            }
        } label: {
            Image(systemName: isCopied ? "checkmark.circle.fill" : "doc.on.doc")
                .foregroundColor(isCopied ? .green : .secondary)
                .font(.caption)
        }
        .buttonStyle(.plain)
    }
}

struct CardView: View {
    let card: Card
    @AppStorage("uniqueColors") private var uniqueColors = true

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(.background)
                .shadow(radius: 1)

            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(.secondary.opacity(0.3), lineWidth: 0.5)

            VStack(spacing: 0) {
                Text(card.rank.first.map { String($0) } ?? "")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(card.color(uniqueColors: uniqueColors))
                card.suitImage
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(card.color(uniqueColors: uniqueColors))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(card.color(uniqueColors: uniqueColors))
            }
            .padding(2)
        }
        .frame(width: 20, height: 32)
    }

}



struct CardResultView: View {
    let card: Card?
    let remainingCards: Int
    @AppStorage("uniqueColors") private var uniqueColors = true


    var body: some View {
        HStack {
            if let card = card {
                HStack {
                    Spacer()
                    CardView(card: card)
                    Spacer()
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Spacer()
                            Text(card.description)
                                .bold()
                                .foregroundColor(card.color(uniqueColors: uniqueColors))

                            Spacer()
                        }
                        HStack {
                            Spacer()
                            Text("\(remainingCards) cards remaining")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                    Spacer()
                    CopyButton(card: card)
                }
                Spacer()
            }
        }
    }
}


#Preview("CardResultView") {
    let sampleCard = Card(rank: "King", suit: "Hearts")

    return CardResultView(card: sampleCard, remainingCards: 48)
        .padding()
}


struct HistoryItemView: View {
    let event: DrawEvent
    @AppStorage("uniqueColors") private var uniqueColors = true

    var body: some View {
        HStack {
            if let card = event.card {
                CardView(card: card)
                Spacer()
                HStack {

                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.description)
                            .font(.system(.caption, weight: .bold)) .foregroundColor(card.color(uniqueColors: uniqueColors))
                        if event.eventType == .draw {
                            Text("\(event.remainingCards) cards remaining")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(event.formattedTime)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        CopyButton(card: card)
                    }
                }
            }
        }
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview("HistoryItemView") {
    let sampleCard = Card(rank: "King", suit: "Hearts")
    let sampleEvent = DrawEvent(
        card: sampleCard,
        eventType: .draw,
        deckCount: 1,
        remainingCards: 51
    )

    return HistoryItemView(event: sampleEvent)
        .padding()
}

struct CopyHistoryView: View {
    var drawHistory: [DrawEvent]
    @AppStorage("copyWithSymbol") private var copyWithSymbol = false

    var body: some View {
        Button(action: copyAllHistory) {
            Text("Copy All History")
        }
    }

    private func copyAllHistory() {
        let historyText = drawHistory.compactMap { event in
            guard let card = event.card else { return nil }
            return copyWithSymbol ? card.shortDescription : card.description
        }.reversed().joined(separator: "\n")

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(historyText, forType: .string)
    }
}

struct DeckControlsView: View {
    @Binding var selectedDrawCount: Int
    @Binding var deckCount: Int
    @Binding var uniqueColors: Bool
    @Binding var historyEnabled: Bool
    @Binding var clearHistoryOnShuffle: Bool
    @Binding var copyWithSymbol: Bool


    let drawAction: () -> Void
    let shuffleAction: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            // Draw controls

            HStack(spacing: 0) {
                Button(action: {
                    drawAction()
                }) {
                    Text("Draw \(selectedDrawCount)")
                        .padding(.horizontal)
                }

                Menu {
                    ForEach([1, 2, 3, 4, 5, 6, 7], id: \.self) { count in
                        Button("Draw \(count)") {
                            selectedDrawCount = count
                        }
                    }
                } label: {
                    Text("#")
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }


            // Shuffle button
            Button(action: shuffleAction) {
                Text("Shuffle")
//                Image(systemName: "shuffle")
            }
            .buttonStyle(.bordered)


            // Settings menu
            Menu {
                Group {
                    Picker("Number of Decks", selection: $deckCount) {
                        ForEach(1...8, id: \.self) { count in
                            Text("\(count)").tag(count)
                        }
                    }
                    Toggle("Unique Suit Colors", isOn: $uniqueColors)
                }

                Divider()

                Group {
                    Toggle("Keep History", isOn: $historyEnabled)
                    if historyEnabled {
                        Toggle("Clear on Shuffle", isOn: $clearHistoryOnShuffle)
                    }
                    Toggle("Use Symbols", isOn: $copyWithSymbol)
                }

                Divider()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
            } label: {
                Image(systemName: "gear")
                    .foregroundColor(.secondary)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
        }
    }
}

#Preview("DeckControlsView") {
    DeckControlsView(
        selectedDrawCount: .constant(1),
        deckCount: .constant(1),
        uniqueColors: .constant(true),
        historyEnabled: .constant(true),
        clearHistoryOnShuffle: .constant(false),
        copyWithSymbol: .constant(false),
        drawAction: {},
        shuffleAction: {}
    )
    .padding()
    .frame(width: 250)
}


struct ContentView: View {
    @AppStorage("deckCount") private var deckCount = 1
    @AppStorage("historyEnabled") private var historyEnabled = true
    @AppStorage("copyWithSymbol") private var copyWithSymbol = false
    @AppStorage("clearHistoryOnShuffle") private var clearHistoryOnShuffle = false
    @AppStorage("uniqueColors") private var uniqueColors = true
    @AppStorage("selectedDrawCount") private var selectedDrawCount = 1

    @State private var deck: Deck
    @State private var currentDraw: DrawEvent?
    @State private var currentMultiDraw: MultiDrawEvent?
    @State private var history: [AnyHashable] = []
    @State private var showHistory = false

    init() {
        let savedDeckCount = UserDefaults.standard.integer(forKey: "deckCount")
        _deck = State(initialValue: Deck(numberOfDecks: savedDeckCount > 0 ? savedDeckCount : 1))
    }

    var body: some View {
        VStack(spacing: 12) {
            // New Controls Layout
            DeckControlsView(
                selectedDrawCount: $selectedDrawCount,
                deckCount: $deckCount,
                uniqueColors: $uniqueColors,
                historyEnabled: $historyEnabled,
                clearHistoryOnShuffle: $clearHistoryOnShuffle,
                copyWithSymbol: $copyWithSymbol,
                drawAction: drawCards,
                shuffleAction: shuffleDeck
            )


            // Current draw result
            Group {
                if let multiDraw = currentMultiDraw {
                    MultiCardResultView(cards: multiDraw.cards, remainingCards: deck.remainingCards)
                } else if let currentDraw = currentDraw {
                    CardResultView(card: currentDraw.card, remainingCards: deck.remainingCards)
                } else {
                    VStack {
                        Text("\(deckCount) deck\(deckCount > 1 ? "s" : ""), \(deck.remainingCards) remaining")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // History section
            if historyEnabled && !history.isEmpty {
                Divider()

                Button {
                    showHistory.toggle()
                } label: {
                    HStack {
                        Text("History")
                            .font(.headline)
                        Spacer()
                        Image(systemName: showHistory ? "chevron.up" : "chevron.down")
                    }
                    .contentShape(Rectangle())
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)

                if showHistory {
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(history, id: \.self) { event in
                                Group {
                                    if let drawEvent = event as? DrawEvent {
                                        HistoryItemView(event: drawEvent)
                                    } else if let multiDrawEvent = event as? MultiDrawEvent {
                                        MultiHistoryItemView(event: multiDrawEvent)
                                    }
                                }
                            }
                        }
                    }
                    .frame(height: 300)

                    if !history.isEmpty {
                        Button("Copy All History") {
                            copyAllHistory()
                        }
                    }
                }
            }
        }
        .padding()
        .frame(width: 300)
    }

    // Updated draw function to handle variable card counts
    private func drawCards() {
        currentDraw = nil
        currentMultiDraw = nil

        if selectedDrawCount == 1 {
            let card = deck.draw()
            let event = DrawEvent(
                card: card,
                eventType: .draw,
                deckCount: deckCount,
                remainingCards: deck.remainingCards
            )
            currentDraw = event

            if historyEnabled {
                history.insert(event, at: 0)
            }
        } else if let cards = deck.drawCards(count: selectedDrawCount) {
            let event = MultiDrawEvent(
                cards: cards,
                eventType: .draw,
                deckCount: deckCount,
                remainingCards: deck.remainingCards
            )
            currentMultiDraw = event

            if historyEnabled {
                history.insert(event, at: 0)
            }
        }

        // Trim history if needed
        if history.count > 50 {
            history.removeLast()
        }
    }

    private func shuffleDeck() {
        deck = Deck(numberOfDecks: deckCount)
        currentDraw = nil
        currentMultiDraw = nil

        if historyEnabled {
            if clearHistoryOnShuffle {
                history = []
            } else {
                let event = DrawEvent(
                    card: nil,
                    eventType: .shuffle,
                    deckCount: deckCount,
                    remainingCards: deck.remainingCards
                )
                history.insert(event, at: 0)
                if history.count > 50 {
                    history.removeLast()
                }
            }
        }
    }

    private func copyAllHistory() {
        let historyText = history.compactMap { event -> String? in
            if let drawEvent = event as? DrawEvent {
                guard let card = drawEvent.card else { return nil }
                return copyWithSymbol ? card.shortDescription : card.description
            } else if let multiDrawEvent = event as? MultiDrawEvent {
                return copyWithSymbol ? multiDrawEvent.shortDescription : multiDrawEvent.description
            }
            return nil
        }.joined(separator: "\n")

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(historyText, forType: .string)
    }
}
