from ambler import Next
from utils.llm_chat import check_host
from utils.prompt import get_prompt


trait State(Deinitable, Movable):
    def host(self) -> String:
        ...

    def set_host(mut self, value: String):
        ...


@fieldwise_init
struct Edges(Copyable, Movable):
    var on_success: Optional[String]
    var on_error: Optional[String]


trait Utils(Deinitable, Movable):
    def check_host(mut self, host: String) -> Bool:
        ...

    def get_prompt(mut self, msg: String) -> Optional[String]:
        ...

    def print_line(mut self, msg: String):
        ...


struct DefaultUtils(Defaultable, Utils):
    def __init__(out self):
        pass

    def check_host(mut self, host: String) -> Bool:
        return check_host(host)

    def get_prompt(mut self, msg: String) -> Optional[String]:
        return get_prompt(msg)

    def print_line(mut self, msg: String):
        print(msg)


comptime DEFAULT_HOSTS: List[String] = [
    "http://localhost:11434/v1",
    "http://localhost:1234/v1",
]


struct Node[U: Utils = DefaultUtils](Movable):
    var edges: Edges
    var utils: Self.U

    def __init__(out self, var edges: Edges, var utils: Self.U):
        self.edges = edges^
        self.utils = utils^

    def run[S: State](mut self, var state: S) raises -> Next[S]:
        var current = state.host()
        var hosts_to_try = [current] if current else materialize[
            DEFAULT_HOSTS
        ]()

        for host in hosts_to_try:
            self.utils.print_line(String(t"Checking LLM at {host}..."))
            if self.utils.check_host(host):
                state.set_host(host)
                return Next(self.edges.on_success, state^)

        var error_msg = String(
            t"LLM not found at {current}."
        ) if current else String(
            "No LLM found at default ports (11434 or 1234)."
        )
        self.utils.print_line(error_msg)

        var new_host = self.utils.get_prompt(
            "Enter LLM host URL (e.g. http://localhost:11434/v1 or"
            " http://localhost:1234/v1): "
        )
        if new_host and new_host.value():
            state.set_host(new_host.value())
        return Next(self.edges.on_error, state^)
