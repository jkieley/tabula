import Testing
@testable import TabulaCore

struct RowSelectionTests {
    /// Display order that differs from id order.
    let order = [3, 0, 4, 1, 2]

    @Test func plainClickSelectsOne() {
        var s = RowSelection()
        s.click(4, modifier: .none, order: order)
        s.click(1, modifier: .none, order: order)
        #expect(s.selected == [1])
        #expect(s.anchor == 1)
        #expect(s.cursor == 1)
    }

    @Test func commandClickToggles() {
        var s = RowSelection()
        s.click(4, modifier: .none, order: order)
        s.click(2, modifier: .command, order: order)
        #expect(s.selected == [4, 2])
        s.click(4, modifier: .command, order: order)
        #expect(s.selected == [2])
        #expect(s.anchor == 4)
    }

    @Test func shiftClickSelectsDisplayRange() {
        var s = RowSelection()
        s.click(0, modifier: .none, order: order)
        s.click(1, modifier: .shift, order: order)
        #expect(s.selected == [0, 4, 1])
        #expect(s.anchor == 0)
        #expect(s.cursor == 1)
        s.click(3, modifier: .shift, order: order)
        #expect(s.selected == [3, 0])
    }

    @Test func shiftClickWithoutAnchorActsLikeClick() {
        var s = RowSelection()
        s.click(1, modifier: .shift, order: order)
        #expect(s.selected == [1])
        #expect(s.anchor == 1)
    }

    @Test func moveWithoutCursorPicksEnds() {
        var down = RowSelection()
        down.move(by: 1, extend: false, order: order)
        #expect(down.selected == [3])
        var up = RowSelection()
        up.move(by: -1, extend: false, order: order)
        #expect(up.selected == [2])
        var none = RowSelection()
        none.move(by: 1, extend: false, order: [])
        #expect(none.selected.isEmpty)
    }

    @Test func moveAndExtend() {
        var s = RowSelection()
        s.click(0, modifier: .none, order: order)
        s.move(by: 1, extend: false, order: order)
        #expect(s.selected == [4])
        s.move(by: 1, extend: true, order: order)
        s.move(by: 1, extend: true, order: order)
        #expect(s.selected == [4, 1, 2])
        #expect(s.anchor == 4)
        #expect(s.cursor == 2)
        s.move(by: -3, extend: true, order: order)
        #expect(s.selected == [0, 4])
    }

    @Test func moveClamps() {
        var s = RowSelection()
        s.click(2, modifier: .none, order: order)
        s.move(by: 5, extend: false, order: order)
        #expect(s.selected == [2])
        s.move(by: -10, extend: false, order: order)
        #expect(s.selected == [3])
    }

    @Test func selectAllAndClear() {
        var s = RowSelection()
        s.selectAll(order: order)
        #expect(s.selected == Set(order))
        #expect(s.anchor == 3)
        #expect(s.cursor == 2)
        s.clear()
        #expect(s.selected.isEmpty)
        #expect(s.anchor == nil)
        #expect(s.cursor == nil)
    }
}
