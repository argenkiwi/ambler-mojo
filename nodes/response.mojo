from ambler import Next
from utils.llm_chat import Message, llm_chat


trait State(Deinitable, Movable):
    def messages(self) -> List[Message]:
        ...

    def host(self) -> String:
        ...

    def model(self) -> String:
        ...

    def add_message(mut self, var message: Message):
        ...


@fieldwise_init
struct Edges(Copyable, Movable):
    var on_complete: Optional[String]


trait Utils(Deinitable, Movable):
    def chat(
        mut self, messages: List[Message], model: String, host: String
    ) raises -> String:
        ...

    def print_line(mut self, msg: String):
        ...


struct DefaultUtils(Defaultable, Utils):
    def __init__(out self):
        pass

    def chat(
        mut self, messages: List[Message], model: String, host: String
    ) raises -> String:
        return llm_chat(messages, model, host)

    def print_line(mut self, msg: String):
        print(msg)


struct Node[U: Utils = DefaultUtils](Movable):
    var edges: Edges
    var utils: Self.U

    def __init__(out self, var edges: Edges, var utils: Self.U):
        self.edges = edges^
        self.utils = utils^

    def run[S: State](mut self, var state: S) raises -> Next[S]:
        var response = self.utils.chat(
            state.messages(), state.model(), state.host()
        )

        self.utils.print_line(String(t"Assistant: {response}"))

        state.add_message(Message("assistant", response))
        return Next(self.edges.on_complete, state^)
