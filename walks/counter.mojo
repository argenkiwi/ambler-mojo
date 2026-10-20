from ambler import Next, Walk, amble, node_not_found
from nodes import count, start, stop


@fieldwise_init
struct State(count.State, start.State, stop.State):
    var value: Int

    def count(self) -> Int:
        return self.value

    def set_count(mut self, value: Int):
        self.value = value


comptime START = "START"
comptime COUNT = "COUNT"
comptime STOP = "STOP"


struct Counter(Walk):
    comptime State = State

    var start: start.Node[]
    var count: count.Node[]
    var stop: stop.Node[]

    def __init__(out self):
        self.start = start.Node(
            start.Edges(on_success=String(COUNT), on_error=String(START)),
            start.DefaultUtils(),
        )
        self.count = count.Node(
            count.Edges(on_count=String(COUNT), on_stop=String(STOP)),
            count.DefaultUtils(),
        )
        self.stop = stop.Node(stop.Edges(on_done=None), stop.DefaultUtils())

    def step(
        mut self, node_id: String, var state: Self.State
    ) raises -> Next[Self.State]:
        if node_id == START:
            return self.start.run(state^)
        if node_id == COUNT:
            return self.count.run(state^)
        if node_id == STOP:
            return self.stop.run(state^)
        raise node_not_found(node_id)


def main() raises:
    var walk = Counter()
    _ = amble(walk, START, State(0))
