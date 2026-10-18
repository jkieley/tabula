import Foundation

/// Finder-style row selection over row ids; positions are resolved against the current display order.
public struct RowSelection: Sendable, Equatable {
    public enum ClickModifier: Sendable {
        case none, command, shift
    }

    public private(set) var selected: Set<Int> = []
    public private(set) var anchor: Int?
    public private(set) var cursor: Int?

    public init() {}

    public mutating func click(_ id: Int, modifier: ClickModifier, order: [Int]) {
        switch modifier {
        case .none:
            select(only: id)
        case .command:
            if selected.contains(id) { selected.remove(id) } else { selected.insert(id) }
            anchor = id
            cursor = id
        case .shift:
            guard let anchor, order.contains(anchor), order.contains(id) else {
                select(only: id)
                return
            }
            cursor = id
            selected = range(from: anchor, to: id, in: order)
        }
    }

    public mutating func move(by delta: Int, extend: Bool, order: [Int]) {
        guard !order.isEmpty else { return }
        guard let cursor, let position = order.firstIndex(of: cursor) else {
            select(only: delta > 0 ? order[0] : order[order.count - 1])
            return
        }
        let target = order[min(max(position + delta, 0), order.count - 1)]
        if extend, let anchor, order.contains(anchor) {
            self.cursor = target
            selected = range(from: anchor, to: target, in: order)
        } else {
            select(only: target)
        }
    }

    public mutating func selectAll(order: [Int]) {
        selected = Set(order)
        anchor = order.first
        cursor = order.last
    }

    public mutating func clear() {
        selected = []
        anchor = nil
        cursor = nil
    }

    private mutating func select(only id: Int) {
        selected = [id]
        anchor = id
        cursor = id
    }

    private func range(from a: Int, to b: Int, in order: [Int]) -> Set<Int> {
        guard let i = order.firstIndex(of: a), let j = order.firstIndex(of: b) else { return [] }
        return Set(order[min(i, j)...max(i, j)])
    }
}
