from ambler import Next


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

    def run[S: Deinitable & Movable](mut self, var state: S) raises -> Next[S]:
        self.utils.print_line("Goodbye!")
        return Next(self.edges.on_done, state^)
