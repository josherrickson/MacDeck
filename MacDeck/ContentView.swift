import SwiftUI

// MARK: - Models


struct Card: Identifiable, Equatable {
    let id: UUID
    let rank: String
    let suit: String
    let isJoker: Bool

    init(id: UUID = UUID(), rank: String, suit: String, isJoker: Bool = false) {
        self.id = id
        self.rank = rank
        self.suit = suit
        self.isJoker = isJoker
    }

    var description: String {
        if (self.isJoker) {
            return "Joker"
        }
        return "\(rank) of \(suit)"
    }

    var shortDescription: String {
        if (self.isJoker) {
            return "JKR"
        }
        return "\(rank.first?.description ?? "")\(unicodeSuit)"
    }

    var suitImage: Image {
        if (self.isJoker) {
            return Image(systemName: "theatermasks.fill")
        }
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
        if (self.isJoker) {
            return .suitPurple
        }
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

struct DeckTemplate {
    var rankCounts: [String: Int] // How many of each rank to include
    var includedSuits: Set<String> // Which suits to include
    var numberOfJokers: Int

    static let standardRanks = ["Ace", "2", "3", "4", "5", "6", "7", "8", "9", "10", "Jack", "Queen", "King"]
    static let standardSuits = ["Hearts", "Diamonds", "Clubs", "Spades"]

    // Default configuration for a standard 52-card deck
    static func standard(includeJokers: Bool = false) -> DeckTemplate {
        var rankCounts: [String: Int] = [:]
        for rank in standardRanks {
            rankCounts[rank] = 1 // One of each rank by default
        }
        return DeckTemplate(
            rankCounts: rankCounts,
            includedSuits: Set(standardSuits),
            numberOfJokers: includeJokers ? 2 : 0
        )
    }

    // Helper to create custom configurations
    static func noFaceCards() -> DeckTemplate {
        var config = standard()
        config.rankCounts.removeValue(forKey: "Jack")
        config.rankCounts.removeValue(forKey: "Queen")
        config.rankCounts.removeValue(forKey: "King")
        return config
    }
}


struct Deck {
    private var cards: [Card]
    let template: DeckTemplate
    let numberOfDecks: Int

    init(template: DeckTemplate = .standard(), numberOfDecks: Int = 1) {
        self.template = template
        self.numberOfDecks = numberOfDecks
        self.cards = []

        // Add cards from multiple decks
        for _ in 0..<numberOfDecks {
            // Build one deck based on template
            for suit in template.includedSuits {
                for (rank, count) in template.rankCounts {
                    for _ in 0..<count {
                        cards.append(Card(rank: rank, suit: suit))
                    }
                }
            }

            // Add jokers for this deck if specified
            for _ in 0..<template.numberOfJokers {
                cards.append(Card(rank: "Joker", suit: "", isJoker: true))
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

    mutating func drawCards(count: Int) -> [Card]? {
        guard count <= remainingCards else { return nil }

        var drawnCards: [Card] = []
        for _ in 0..<count {
            if let card = draw() {
                drawnCards.append(card)
            }
        }
        return drawnCards
    }

    var remainingCards: Int {
        cards.count
    }

    // Calculate how many cards should be in a complete pile
    var totalPossibleCards: Int {
        let cardsInOneDeck = template.includedSuits.count *
            template.rankCounts.values.reduce(0, +) +
            template.numberOfJokers
        return cardsInOneDeck * numberOfDecks
    }
}



struct DrawEvent: Identifiable, Hashable {
    let id = UUID()
    let timestamp = Date()
    let cards: [Card]?
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
            return cards?.map { $0.description }.joined(separator: ", ") ?? "No cards remaining"
        case .shuffle:
            return "Deck shuffled (\(deckCount) deck\(deckCount > 1 ? "s" : ""))"
        }
    }

    var shortDescription: String {
        switch eventType {
        case .draw:
            if let cards = cards, !cards.isEmpty {
                return cards.map { $0.shortDescription }.joined(separator: " ")
            } else {
                return "No cards remaining"
            }
        case .shuffle:
            return "Shuffled"
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
                Group {
                    if card.rank == "10" {
                        Text(card.rank)
                    } else {
                        Text(card.rank.first.map { String($0) } ?? "")
                    }
                }
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

struct DeckView: View {
    let backColor: Color

    var body: some View {
        ZStack {
            // Same base card shape as CardView
            RoundedRectangle(cornerRadius: 4)
                .fill(.background)
                .shadow(radius: 1)

            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(.secondary.opacity(0.3), lineWidth: 0.5)

            RoundedRectangle(cornerRadius: 3)
                .fill(backColor)
                .padding(1)
        }
        .frame(width: 20, height: 32)
    }
}

// Preview provider for SwiftUI canvas
#Preview {
    HStack(spacing: 4) {
        DeckView(backColor: .red)
        DeckView(backColor: .blue)
        DeckView(backColor: .green)
    }
    .padding()
}


struct CardResultView: View {
    let cards: [Card]
    let remainingCards: Int
    @AppStorage("uniqueColors") private var uniqueColors = true
    @AppStorage("copyWithSymbol") private var copyWithSymbol = false
    @State private var isCopied = false

    private var copyText: String {
        if copyWithSymbol {
            return cards.map { $0.shortDescription }.joined(separator: " ")
        } else {
            return cards.map { $0.description }.joined(separator: ", ")
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            if cards.count == 1, let card = cards.first {
                HStack {
                    CardView(card: card)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(card.description)
                                .bold()
                                .foregroundColor(card.color(uniqueColors: uniqueColors))
                        }
                    }
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(cards) { card in
                            CardView(card: card)
                        }
                    }
                }
            }
            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                Text("\(remainingCards) cards left")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.trailing)



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
    }
}


#Preview("Single CardResultView") {
    let sampleCards = [
        Card(rank: "King", suit: "Hearts")
    ]

    return CardResultView(cards: sampleCards, remainingCards: 47)
        .padding()
        .frame(width: 250)

}


#Preview("Multiple CardResultView") {
    let sampleCards = [
        Card(rank: "King", suit: "Hearts"),
        Card(rank: "Queen", suit: "Diamonds"),
        Card(rank: "Jack", suit: "Spades"),
        Card(rank: "10", suit: "Clubs"),
        Card(rank: "Ace", suit: "Hearts")
    ]

    return CardResultView(cards: sampleCards, remainingCards: 47)
        .padding()
        .frame(width: 250)

}

struct DeckShuffleView: View {
    let numberOfDecks: Int
    let remainingCards: Int
    let shuffleId: UUID

    // https://sashamaps.net/docs/resources/20-colors/
    private static let availableColors: [Color] = [
        Color(red: 0.90, green: 0.10, blue: 0.29),    // #e6194B
        Color(red: 0.24, green: 0.70, blue: 0.29),    // #3cb44b
        Color(red: 1.00, green: 0.88, blue: 0.10),    // #ffe119
        Color(red: 0.26, green: 0.39, blue: 0.85),    // #4363d8
        Color(red: 0.96, green: 0.51, blue: 0.19),    // #f58231
        Color(red: 0.26, green: 0.83, blue: 0.96),    // #42d4f4
        Color(red: 0.94, green: 0.20, blue: 0.90),    // #f032e6
        Color(red: 0.98, green: 0.75, blue: 0.83),    // #fabed4
        Color(red: 0.86, green: 0.75, blue: 1.00),    // #dcbeff
        Color(red: 0.60, green: 0.39, blue: 0.14),    // #9A6324
        Color(red: 1.00, green: 0.98, blue: 0.78),    // #fffac8
        Color(red: 0.50, green: 0.00, blue: 0.00),    // #800000
        Color(red: 0.67, green: 1.00, blue: 0.76),    // #aaffc3
        Color(red: 0.66, green: 0.66, blue: 0.66),    // #a9a9a9
        Color(red: 1.00, green: 1.00, blue: 1.00),    // #ffffff
        Color(red: 0.00, green: 0.00, blue: 0.00)     // #000000
    ]


    // Store deckColors as a property initialized once
    private let deckColors: [Color]

    init(numberOfDecks: Int, remainingCards: Int, shuffleId: UUID) {
        self.numberOfDecks = numberOfDecks
        self.remainingCards = remainingCards
        self.shuffleId = shuffleId

        assert(numberOfDecks <= DeckShuffleView.availableColors.count,
               "Not enough unique colors for the number of decks.")

        // Shuffle the colors and take the required amount
        self.deckColors = Array(DeckShuffleView.availableColors.shuffled().prefix(numberOfDecks))
    }



    var body: some View {
        HStack(spacing: 8) {
            // Overlapping deck stack and count label
            HStack {
                ZStack {
                    ForEach(0..<numberOfDecks, id: \.self) { index in
                        DeckView(backColor: deckColors[index])
                            .offset(x: Double(index) * 8)
                    }
                }
                .frame(width: Double(numberOfDecks - 1) * 8 + 20, alignment: .leading)

                Text("\(numberOfDecks) deck\(numberOfDecks == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                Text("\(remainingCards) cards left")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.trailing)

                Button {
                    // Disabled, no action
                } label: {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(.secondary.opacity(0.5))
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .disabled(true)
            }
        }
    }
}

// Preview provider for SwiftUI canvas
#Preview("DeckShuffleView") {
    VStack(spacing: 20) {
        DeckShuffleView(numberOfDecks: 1, remainingCards: 52, shuffleId: UUID())
        DeckShuffleView(numberOfDecks: 3, remainingCards: 156, shuffleId: UUID())
        DeckShuffleView(numberOfDecks: 6, remainingCards: 312, shuffleId: UUID())
    }
    .padding()
}

struct HistoryItemView: View {
    let event: DrawEvent
    @AppStorage("uniqueColors") private var uniqueColors = true
    @AppStorage("copyWithSymbol") private var copyWithSymbol = false
    @State private var isCopied = false

    private var copyText: String {
        if copyWithSymbol {
            return event.shortDescription
        } else {
            return event.description
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Cards section
                if let cards = event.cards {
                    if cards.count == 1, let firstCard = cards.first {
                        // Single card case
                        CardView(card: firstCard)
                        Text(event.description)
                            .font(.system(.caption, weight: .bold))
                            .foregroundColor(firstCard.color(uniqueColors: uniqueColors))
                        Spacer()
                    } else {
                        // Multiple cards case
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 4) {
                                ForEach(cards) { card in
                                    CardView(card: card)
                                }
                            }
                        }
                    }
                } else {
                    VStack {
                        Text(event.description)
                            .font(.system(.caption, weight: .bold))
                    }
                    Spacer()

                }

                // Timestamp and copy button section
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(event.remainingCards) cards left")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    HStack {
                        Text(event.formattedTime)
                            .font(.caption2)
                            .foregroundColor(.secondary)

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
                        .disabled(event.eventType == .shuffle)
                    }
                }
            }

        }
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview("HistoryItemView - Single Card") {
    let sampleEvent = DrawEvent(
            cards: [Card(rank: "King", suit: "Hearts")],
            eventType: .draw,
            deckCount: 1,
            remainingCards: 51
        )

        return HistoryItemView(event: sampleEvent)
            .padding()
            .frame(width: 300)
    }

    #Preview("HistoryItemView - Multiple Cards") {
        let sampleCards = [
            Card(rank: "King", suit: "Hearts"),
            Card(rank: "Queen", suit: "Diamonds"),
            Card(rank: "Jack", suit: "Spades")
        ]
        let sampleEvent = DrawEvent(
            cards: sampleCards,
        eventType: .draw,
        deckCount: 1,
        remainingCards: 49
    )

    return HistoryItemView(event: sampleEvent)
        .padding()
        .frame(width: 300)
}

#Preview("HistoryItemView - Shuffle") {
    let sampleEvent = DrawEvent(
        cards: nil,
        eventType: .shuffle,
        deckCount: 2,
        remainingCards: 104
    )

    return HistoryItemView(event: sampleEvent)
        .padding()
        .frame(width: 300)
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
            guard let cards = event.cards, let firstCard = cards.first else { return nil }
            return copyWithSymbol ? firstCard.shortDescription : firstCard.description
        }.reversed().joined(separator: "\n")

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(historyText, forType: .string)
    }
}

struct DeckControlsView: View {
    @Binding var selectedDrawCount: Int
    @Binding var deckCount: Int
    @Binding var uniqueColors: Bool
    @Binding var deckHasJokers: Bool
    @Binding var historyEnabled: Bool
    @Binding var clearHistoryOnShuffle: Bool
    @Binding var copyWithSymbol: Bool
    var remainingCards: Int


    let drawAction: () -> Void
    let shuffleAction: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            // Draw controls
            Menu {
                ForEach([1, 2, 3, 4, 5, 6, 7], id: \.self) { count in
                    Button("Draw \(count)") {
                        selectedDrawCount = count
                    }
                }
            } label: {
                Text("Draw \(selectedDrawCount)")
                    .padding(.horizontal)
            } primaryAction: {
                if remainingCards >= selectedDrawCount {
                    drawAction()
                }
            }
            .buttonStyle(.borderedProminent)
            .frame(width: 100)
            .controlSize(.large)
            .padding(.horizontal, 4)
            .tint(remainingCards >= selectedDrawCount ? .accentColor : .gray)
            .opacity(remainingCards >= selectedDrawCount ? 1.0 : 0.5)


            Spacer()

            // Shuffle button
            Button(action: shuffleAction) {
                Text("Shuffle")
                Image(systemName: "shuffle")
            }
            .buttonStyle(.bordered)


            // Settings menu
            Menu {
                Toggle("Unique Suit Colors", isOn: $uniqueColors)
                Toggle("Copy Symbols", isOn: $copyWithSymbol)
                Toggle("Keep History", isOn: $historyEnabled)
                Toggle("Clear History on Shuffle", isOn: $clearHistoryOnShuffle)
                    .disabled(!historyEnabled)

                Divider()

                Section(header: Text("Changing these settings will reshuffle")
                                    .font(.subheadline)
                                    .foregroundColor(.primary)) {
                    Picker("Number of Decks", selection: $deckCount) {
                        ForEach(1...8, id: \.self) { count in
                            Text("\(count)").tag(count)
                        }
                    }
                    Toggle("Include Jokers", isOn: $deckHasJokers)
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
        deckHasJokers: .constant(true),
        historyEnabled: .constant(true),
        clearHistoryOnShuffle: .constant(false),
        copyWithSymbol: .constant(false),
        remainingCards: 40,
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
    @AppStorage("deckHasJokers") private var deckHasJokers = false
    @AppStorage("selectedDrawCount") private var selectedDrawCount = 1

    @State private var currentDraw: DrawEvent?
    @State private var history: [AnyHashable] = []
    @State private var showHistory = false

    // Instantiating these with dummy items, to be updated in init below
    @State private var deckTemplate = DeckTemplate.standard(includeJokers: false) // Initialize here
    @State private var deck = Deck(template: DeckTemplate.standard(includeJokers: false), numberOfDecks: 1)

    init() {
        self.deckTemplate = DeckTemplate.standard(includeJokers: deckHasJokers)
        self.deck = Deck(template: self.deckTemplate, numberOfDecks: deckCount)
    }

    var body: some View {
        VStack(spacing: 12) {
            // New Controls Layout
            DeckControlsView(
                selectedDrawCount: $selectedDrawCount,
                deckCount: $deckCount,
                uniqueColors: $uniqueColors,
                deckHasJokers: $deckHasJokers,
                historyEnabled: $historyEnabled,
                clearHistoryOnShuffle: $clearHistoryOnShuffle,
                copyWithSymbol: $copyWithSymbol,
                remainingCards: deck.remainingCards,
                drawAction: drawCards,
                shuffleAction: shuffleDeck
            )



            // Current draw result
            Group {
                if let currentDraw = currentDraw, let cards = currentDraw.cards {
                    CardResultView(cards: cards, remainingCards: deck.remainingCards)
                } else {
                    DeckShuffleView(numberOfDecks: deckCount,
                                    remainingCards: deck.remainingCards,
                                    shuffleId: UUID())
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
                                if let drawEvent = event as? DrawEvent {
                                    HistoryItemView(event: drawEvent)
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
        .onChange(of: deckCount) {
            deckTemplate = DeckTemplate.standard(includeJokers: deckHasJokers)
            deck = Deck(template: deckTemplate,
                        numberOfDecks: deckCount)
            // This second shuffle seems redundant, but it forces some redraws
            shuffleDeck()
        }
        .onChange(of: deckHasJokers) {
            deckTemplate = DeckTemplate.standard(includeJokers: deckHasJokers)
            deck = Deck(template: deckTemplate,
                        numberOfDecks: deckCount)
            shuffleDeck()
        }
    }

    // Updated draw function to handle variable card counts
    private func drawCards() {
        currentDraw = nil

        if let cards = deck.drawCards(count: selectedDrawCount) {
            let event = DrawEvent(
                cards: cards,
                eventType: .draw,
                deckCount: deckCount,
                remainingCards: deck.remainingCards
            )
            currentDraw = event

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
        deck = Deck(template: deckTemplate,
                    numberOfDecks: deckCount)
        currentDraw = nil

        if historyEnabled {
            if clearHistoryOnShuffle {
                history = []
            } else {
                let event = DrawEvent(
                    cards: nil,
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
                guard let cards = drawEvent.cards, let firstCard = cards.first else { return nil }
                return copyWithSymbol ? firstCard.shortDescription : firstCard.description
            }
            return nil
        }.joined(separator: "\n")

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(historyText, forType: .string)
    }
}
