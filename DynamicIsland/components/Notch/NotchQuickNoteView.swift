/*
 * Atoll (DynamicIsland)
 * Copyright (C) 2024-2026 Atoll Contributors
 *
 * Originally from boring.notch project
 * Modified and adapted for Atoll (DynamicIsland)
 * See NOTICE for details.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <https://www.gnu.org/licenses/>.
 */

import Defaults
import SwiftUI

struct NotchQuickNoteView: View {
    @ObservedObject var coordinator = DynamicIslandViewCoordinator.shared
    @Default(.quickNoteText) private var quickNoteText
    @Default(.quickNotes) private var quickNotes
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Memo")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)

            ZStack(alignment: .topLeading) {
                if quickNoteText.isEmpty {
                    Text("Start typing...")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.35))
                        .padding(.top, 8)
                        .padding(.leading, 4)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $quickNoteText)
                    .font(.system(size: 13))
                    .foregroundStyle(.white)
                    .scrollContentBackground(.hidden)
                    .focused($isInputFocused)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear {
            migrateLegacyNotesIfNeeded()
            isInputFocused = true
        }
        .onChange(of: coordinator.currentView) { _, newValue in
            if newValue == .quickNote {
                isInputFocused = true
            }
        }
    }

    private func migrateLegacyNotesIfNeeded() {
        guard quickNoteText.isEmpty, !quickNotes.isEmpty else { return }
        quickNoteText = quickNotes.map(\.text).joined(separator: "\n")
        quickNotes = []
    }
}
