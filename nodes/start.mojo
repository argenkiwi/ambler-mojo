from ambler import Next
from utils.prompt import get_prompt


trait State(Deinitable, Movable):
    def count(self) -> Int:
        ...

    def set_count(mut self, value: Int):
        ...


@fieldwise_init
struct Edges(Copyable, Movable):
    var on_success: Optional[String]
    var on_error: Optional[String]


trait Utils(Deinitable, Movable):
    def read_line(mut self, msg: String) -> Optional[String]:
        ...

    def print_line(mut self, msg: String):
        ...


struct DefaultUtils(Defaultable, Utils):
    def __init__(out self):
        pass

    def read_line(mut self, msg: String) -> Optional[String]:
        return get_prompt(msg)

    def print_line(mut self, msg: String):
        print(msg)


struct Node[U: Utils = DefaultUtils](Movable):
    var edges: Edges
    var utils: Self.U

    def __init__(out self, var edges: Edges, var utils: Self.U):
        self.edges = edges^
        self.utils = utils^

    def run[S: State](mut self, var state: S) raises -> Next[S]:
        var input = self.utils.read_line("Enter a starting number: ")

        if not input or input.value() == "":
            state.set_count(0)
            return Next(self.edges.on_success, state^)

        var n: Int
        try:
            n = Int(input.value())
        except:
            self.utils.print_line(
                "Error: Invalid input. Please enter a number."
            )
            return Next(self.edges.on_error, state^)

        state.set_count(n)
        return Next(self.edges.on_success, state^)
