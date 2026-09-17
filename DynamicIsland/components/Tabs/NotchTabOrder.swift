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

enum NotchTabOrder {
    static let defaultSystemIDs: [String] = [
        NotchViews.home.rawValue,
        NotchViews.quickNote.rawValue,
        NotchViews.shelf.rawValue,
        NotchViews.timer.rawValue,
        NotchViews.stats.rawValue,
        NotchViews.llmUsage.rawValue,
        NotchViews.notes.rawValue,
        NotchViews.terminal.rawValue
    ]

    static func resolvedOrder(_ saved: [String] = Defaults[.notchTabOrder]) -> [String] {
        merge(saved: saved, defaultOrder: defaultSystemIDs)
    }

    static func merge(saved: [String], defaultOrder: [String]) -> [String] {
        let known = Set(defaultOrder)
        var result = saved.filter { known.contains($0) }
        for (index, id) in defaultOrder.enumerated() {
            guard !result.contains(id) else { continue }
            if let predecessor = defaultOrder[..<index].last(where: { result.contains($0) }),
               let insertAt = result.firstIndex(of: predecessor) {
                result.insert(id, at: insertAt + 1)
                continue
            }
            let successorRange = defaultOrder.index(after: index)..<defaultOrder.endIndex
            if let successor = defaultOrder[successorRange].first(where: { result.contains($0) }),
               let insertAt = result.firstIndex(of: successor) {
                result.insert(id, at: insertAt)
                continue
            }
            result.append(id)
        }
        return result
    }

    static func sort(_ tabs: [TabModel], order: [String]? = nil) -> [TabModel] {
        let resolved = order ?? resolvedOrder()
        return tabs.sorted { lhs, rhs in
            let left = resolved.firstIndex(of: lhs.view.rawValue) ?? Int.max
            let right = resolved.firstIndex(of: rhs.view.rawValue) ?? Int.max
            return left < right
        }
    }

    static func applying(enabledOrder: [String], to full: [String]) -> [String] {
        let enabledSet = Set(enabledOrder)
        var queue = enabledOrder
        var result = full.map { id -> String in
            if enabledSet.contains(id), !queue.isEmpty {
                return queue.removeFirst()
            }
            return id
        }
        if !queue.isEmpty {
            result.append(contentsOf: queue)
        }
        return merge(saved: result, defaultOrder: defaultSystemIDs)
    }

    static func visibleSystemTabs() -> [TabModel] {
        var tabs: [TabModel] = []

        if homeTabVisible {
            tabs.append(TabModel(label: "Home", icon: "house.fill", view: .home))
        }
        if Defaults[.enableQuickNote] {
            tabs.append(TabModel(label: "Quick Note", icon: "square.and.pencil", view: .quickNote))
        }
        if Defaults[.dynamicShelf] {
            tabs.append(TabModel(label: "Shelf", icon: "tray.fill", view: .shelf))
        }
        if Defaults[.enableTimerFeature] && Defaults[.timerDisplayMode] == .tab {
            tabs.append(TabModel(label: "Timer", icon: "timer", view: .timer))
        }
        if Defaults[.enableStatsFeature] {
            tabs.append(TabModel(label: "Stats", icon: "chart.xyaxis.line", view: .stats))
        }
        if Defaults[.enableLLMUsageFeature] {
            tabs.append(TabModel(label: "Usage", icon: "chart.bar.doc.horizontal", view: .llmUsage))
        }
        if Defaults[.enableNotes] || (Defaults[.enableClipboardManager] && Defaults[.clipboardDisplayMode] == .separateTab) {
            let label = Defaults[.enableNotes] ? "Notes" : "Clipboard"
            let icon = Defaults[.enableNotes] ? "note.text" : "doc.on.clipboard"
            tabs.append(TabModel(label: label, icon: icon, view: .notes))
        }
        if Defaults[.enableTerminalFeature] {
            tabs.append(TabModel(label: "Terminal", icon: "apple.terminal", view: .terminal))
        }

        return sort(tabs)
    }

    static func defaultLandingView() -> NotchViews {
        if Defaults[.enableMinimalisticUI] {
            return .home
        }
        return visibleSystemTabs().first?.view ?? .home
    }

    static var animationTabOrder: [NotchViews] {
        let system = resolvedOrder().compactMap(NotchViews.init(rawValue:))
        let extras: [NotchViews] = [.colorPicker, .clipboard, .extensionExperience]
        return system + extras.filter { !system.contains($0) }
    }

    private static var homeTabVisible: Bool {
        if Defaults[.enableMinimalisticUI] {
            return true
        }
        return Defaults[.showStandardMediaControls] || Defaults[.showCalendar] || Defaults[.showMirror]
    }
}
