from ambler import Next
from utils.llm_chat import Message
from utils.prompt import get_prompt


trait State(Deinitable, Movable):
    def add_message(mut self, var message: Message):
        ...


@fieldwise_init
struct Edges(Copyable, Movable):
    var on_message: Optional[String]
    var on_quit: Optional[String]


trait Utils(Deinitable, Movable):
    def prompt(mut self, msg: String) -> Optional[String]:
        ...

    def print_line(mut self, msg: String):
        ...


struct DefaultUtils(Defaultable, Utils):
    def __init__(out self):
        pass

    def prompt(mut self, msg: String) -> Optional[String]:
        return get_prompt(msg)

    def print_line(mut self, msg: String):
        print(msg)


comptime QUIT_WORDS: List[String] = ["bye", "exit", "quit"]


struct Node[U: Utils = DefaultUtils](Movable):
    var edges: Edges
    var utils: Self.U

    def __init__(out self, var edges: Edges, var utils: Self.U):
        self.edges = edges^
        self.utils = utils^

    def run[S: State](mut self, var state: S) raises -> Next[S]:
        var input = self.utils.prompt("You: ")

        if not input or String(input.value().strip()).lower() in materialize[
            QUIT_WORDS
        ]():
            return Next(self.edges.on_quit, state^)

        state.add_message(Message("user", input.value()))
        return Next(self.edges.on_message, state^)
