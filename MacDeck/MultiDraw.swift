import SwiftUI

struct MultiDrawEvent: Identifiable, Hashable {
    let id = UUID()
    let timestamp = Date()
    let cards: [Card]
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

    static func == (lhs: MultiDrawEvent, rhs: MultiDrawEvent) -> Bool {
        lhs.id == rhs.id
    }

    var description: String {
        switch eventType {
        case .draw:
            return cards.map { $0.description }.joined(separator: ", ")
        case .shuffle:
            return "Deck shuffled (\(deckCount) deck\(deckCount > 1 ? "s" : ""))"
        }
    }

    var shortDescription: String {
        switch eventType {
        case .draw:
            return cards.map { $0.shortDescription }.joined(separator: " ")
        case .shuffle:
            return "Shuffled"
        }
    }

    var formattedTime: String {
        timestamp.formatted(date: .omitted, time: .shortened)
    }
}

// Corresponding history item view for multi-draws
struct MultiHistoryItemView: View {
    let event: MultiDrawEvent
    @AppStorage("uniqueColors") private var uniqueColors = true
    @State private var isCopied = false
    @AppStorage("copyWithSymbol") private var copyWithSymbol = false

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
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(event.cards) { card in
                            CardView(card: card)
                        }
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
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
                }
            }

            if event.eventType == .draw {
                Text("\(event.remainingCards) cards remaining")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview("MultiHistoryItemView") {
    let sampleCards = [
        Card(rank: "King", suit: "Hearts"),
        Card(rank: "Queen", suit: "Diamonds"),
        Card(rank: "Jack", suit: "Spades"),
        Card(rank: "10", suit: "Clubs"),
        Card(rank: "Ace", suit: "Hearts")
    ]

    let event = MultiDrawEvent(
        cards: sampleCards,
        eventType: .draw,
        deckCount: 1,
        remainingCards: 47
    )

    return MultiHistoryItemView(event: event)
        .padding()
        .frame(width: 250)
}
