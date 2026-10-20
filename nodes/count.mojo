from std.random import random_float64
from std.time import sleep

from ambler import Next


trait State(Deinitable, Movable):
    def count(self) -> Int:
        ...

    def set_count(mut self, value: Int):
        ...


@fieldwise_init
struct Edges(Copyable, Movable):
    var on_count: Optional[String]
    var on_stop: Optional[String]


trait Utils(Deinitable, Movable):
    def print_line(mut self, msg: String):
        ...

    def sleep(mut self, seconds: Float64):
        ...

    def random(mut self) -> Float64:
        ...


struct DefaultUtils(Defaultable, Utils):
    def __init__(out self):
        pass

    def print_line(mut self, msg: String):
        print(msg)

    def sleep(mut self, seconds: Float64):
        sleep(seconds)

    def random(mut self) -> Float64:
        return random_float64()


struct Node[U: Utils = DefaultUtils](Movable):
    var edges: Edges
    var utils: Self.U

    def __init__(out self, var edges: Edges, var utils: Self.U):
        self.edges = edges^
        self.utils = utils^

    def run[S: State](mut self, var state: S) raises -> Next[S]:
        self.utils.print_line(String(t"Current count: {state.count()}"))
        self.utils.sleep(1.0)
        state.set_count(state.count() + 1)

        if self.utils.random() > 0.5:
            return Next(self.edges.on_count, state^)
        return Next(self.edges.on_stop, state^)
