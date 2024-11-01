import SwiftUI

// MARK: - Models

struct Card: Identifiable, Equatable {
    let id = UUID()
    let rank: String
    let suit: String

    var description: String {
        "\(rank) of \(suit)"
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

    var color: Color {
        switch suit {
        case "Hearts", "Diamonds":
            return .red
        case "Spades", "Clubs":
            return .primary
        default:
            return .secondary
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

struct DrawEvent: Identifiable {
    let id = UUID()
    let timestamp = Date()
    let card: Card?
    let eventType: EventType
    let deckCount: Int
    let remainingCards: Int

    enum EventType {
        case draw
        case shuffle
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
        copyWithSymbol ? "\(card.rank.first?.description ?? "")\(card.unicodeSuit)" : card.description
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



struct CardResultView: View {
    let card: Card?
    let remainingCards: Int

    var body: some View {
        HStack {
            if let card = card {
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.background)
                        .shadow(radius: 1)

                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(.secondary.opacity(0.3), lineWidth: 0.5)

                    VStack(spacing: 0) {
                        Text(card.rank.first.map { String($0) } ?? "")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(card.color)
                        card.suitImage
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(card.color)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(card.color)
                    }
                    .padding(2)
                }
                .frame(width: 20, height: 32)
                Spacer()
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(card.description)
                            .foregroundColor(card.color)
                        CopyButton(card: card)
                    }
                    Text("\(remainingCards) cards remaining")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
        }
    }
}

struct HistoryItemView: View {
    let event: DrawEvent

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if let card = event.card {
                    HStack {
                        Text(event.description)
                            .font(.caption)
                            .foregroundColor(card.color)
                        CopyButton(card: card)
                    }
                } else {
                    Text(event.description)
                        .font(.caption)
                }

                HStack {
                    if event.eventType == .draw {
                        Text("\(event.remainingCards) cards remaining")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text(event.formattedTime)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

struct ContentView: View {
    @AppStorage("deckCount") private var deckCount = 1
    @AppStorage("historyEnabled") private var historyEnabled = true
    @AppStorage("copyWithSymbol") private var copyWithSymbol = false
    @AppStorage("clearHistoryOnShuffle") private var clearHistoryOnShuffle = false
    @State private var deck: Deck
    @State private var currentDraw: DrawEvent?
    @State private var drawHistory: [DrawEvent] = []
    @State private var showHistory = false

    init() {
        let savedDeckCount = UserDefaults.standard.integer(forKey: "deckCount")
        _deck = State(initialValue: Deck(numberOfDecks: savedDeckCount > 0 ? savedDeckCount : 1))
    }

    var body: some View {
        VStack(spacing: 12) {
            // Main controls
            HStack(spacing: 8) {
                Button(action: drawCard) {
                    HStack {
                        Image(systemName: "rectangle.stack")
                        Text("Draw")
                    }
                }
                .disabled(deck.remainingCards == 0)

                Button(action: shuffleDeck) {
                    HStack {
                        Image(systemName: "shuffle")
                        Text("Shuffle")
                    }
                }

                Spacer()

                Menu {
                    Stepper("Number of Decks: \(deckCount)", value: $deckCount, in: 1...8)
                        .onChange(of: deckCount) { oldValue, newValue in
                            shuffleDeck()
                        }
                    Toggle("Enable History", isOn: $historyEnabled)
                    Toggle("Clear History on Shuffle", isOn: $clearHistoryOnShuffle)
                    Toggle("Copy as Symbol", isOn: $copyWithSymbol)
                    Divider()
                    Button("Quit", action: {
                        NSApplication.shared.terminate(nil)
                    })
                } label: {
                    Image(systemName: "gear")
                        .foregroundColor(.secondary)
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .fixedSize()
            }

            if let currentDraw = currentDraw {
                CardResultView(card: currentDraw.card, remainingCards: deck.remainingCards)
            }

            if historyEnabled && !drawHistory.isEmpty {
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
                            ForEach(drawHistory) { event in
                                HistoryItemView(event: event)
                            }
                        }
                    }
                    .frame(height: 300)
                }
            }
        }
        .padding()
        .frame(width: 250)
    }



    private func drawCard() {
        let card = deck.draw()
        let event = DrawEvent(
            card: card,
            eventType: .draw,
            deckCount: deckCount,
            remainingCards: deck.remainingCards
        )
        currentDraw = event

        if historyEnabled {
            drawHistory.insert(event, at: 0)
            if drawHistory.count > 50 {
                drawHistory.removeLast()
            }
        }
    }

    private func shuffleDeck() {
        deck = Deck(numberOfDecks: deckCount)
        let event = DrawEvent(
            card: nil,
            eventType: .shuffle,
            deckCount: deckCount,
            remainingCards: deck.remainingCards
        )
        currentDraw = nil

        if historyEnabled {
            if clearHistoryOnShuffle {
                drawHistory = []
            } else {
                drawHistory.insert(event, at: 0)
                if drawHistory.count > 50 {
                    drawHistory.removeLast()
                }
            }
        }
    }
}

