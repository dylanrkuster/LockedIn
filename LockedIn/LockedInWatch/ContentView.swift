//
//  ContentView.swift
//  LockedInWatch
//
//  Main watch app view showing current balance.
//

import SwiftUI

struct ContentView: View {
    @Environment(WatchState.self) private var watchState

    var body: some View {
        VStack(spacing: 8) {
            // Balance number
            Text("\(watchState.balance)")
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
                .contentTransition(.numericText())

            // Label
            Text("MIN")
                .font(.system(size: 12, weight: .semibold))
                .tracking(2)
                .foregroundStyle(.white.opacity(0.6))

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.2))

                    Rectangle()
                        .fill(difficultyColor)
                        .frame(width: geo.size.width * watchState.progress)
                }
            }
            .frame(height: 4)
            .clipShape(RoundedRectangle(cornerRadius: 2))

            // Difficulty indicator
            HStack(spacing: 2) {
                ForEach(0..<4, id: \.self) { index in
                    Rectangle()
                        .fill(index < barCount ? difficultyColor : Color.white.opacity(0.2))
                        .frame(width: 3, height: 10)
                }

                Text(watchState.difficulty)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(difficultyColor)
            }
            .padding(.top, 4)
        }
        .padding()
        .containerBackground(Color.black.gradient, for: .navigation)
        .onAppear {
            // Request current balance from iPhone when view appears
            WatchSessionManager.shared.requestBalance()
        }
    }

    private var barCount: Int {
        switch watchState.difficulty {
        case "EASY": return 1
        case "MEDIUM": return 2
        case "HARD": return 3
        case "EXTREME": return 4
        default: return 2
        }
    }

    private var difficultyColor: Color {
        switch watchState.difficulty {
        case "EASY": return Color(red: 0.133, green: 0.773, blue: 0.369)
        case "MEDIUM": return Color(red: 0.918, green: 0.702, blue: 0.031)
        case "HARD": return Color(red: 0.976, green: 0.451, blue: 0.086)
        case "EXTREME": return Color(red: 0.863, green: 0.149, blue: 0.149)
        default: return Color(red: 0.918, green: 0.702, blue: 0.031)
        }
    }
}

#Preview {
    ContentView()
        .environment(WatchState.shared)
}
