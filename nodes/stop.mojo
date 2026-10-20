from ambler import Next


trait State(Deinitable, Movable):
    def count(self) -> Int:
        ...


@fieldwise_init
struct Edges(Copyable, Movable):
    var on_done: Optional[String]


trait Utils(Deinitable, Movable):
    def print_line(mut self, msg: String):
        ...


struct DefaultUtils(Defaultable, Utils):
    def __init__(out self):
        pass

    def print_line(mut self, msg: String):
        print(msg)


struct Node[U: Utils = DefaultUtils](Movable):
    var edges: Edges
    var utils: Self.U

    def __init__(out self, var edges: Edges, var utils: Self.U):
        self.edges = edges^
        self.utils = utils^

    def run[S: State](mut self, var state: S) raises -> Next[S]:
        self.utils.print_line(String(t"Final count: {state.count()}"))
        return Next(self.edges.on_done, state^)
