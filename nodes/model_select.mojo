from ambler import Next
from utils.llm_chat import list_models
from utils.prompt import get_prompt


trait State(Deinitable, Movable):
    def host(self) -> String:
        ...

    def set_model(mut self, value: String):
        ...


@fieldwise_init
struct Edges(Copyable, Movable):
    var on_success: Optional[String]


trait Utils(Deinitable, Movable):
    def list_models(mut self, host: String) raises -> List[String]:
        ...

    def get_prompt(mut self, msg: String) -> Optional[String]:
        ...

    def print_line(mut self, msg: String):
        ...


struct DefaultUtils(Defaultable, Utils):
    def __init__(out self):
        pass

    def list_models(mut self, host: String) raises -> List[String]:
        return list_models(host)

    def get_prompt(mut self, msg: String) -> Optional[String]:
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
        var models = self.utils.list_models(state.host())

        if not models:
            self.utils.print_line(
                "No models found. Please check the LLM host or enter a model"
                " name manually."
            )
            var manual = self.utils.get_prompt("Enter model name manually: ")
            state.set_model(manual.or_else(""))
            return Next(self.edges.on_success, state^)

        self.utils.print_line("Available models:")
        for i in range(len(models)):
            self.utils.print_line(String(t"{i + 1}. {models[i]}"))

        var choice = self.utils.get_prompt(
            String(t"Select a model (1-{len(models)}) [1]: ")
        )
        var index = 0
        if choice and choice.value():
            try:
                index = Int(choice.value()) - 1
            except:
                pass
        if index < 0 or index >= len(models):
            index = 0
        var selected = models[index]

        self.utils.print_line(String(t"Selected model: {selected}"))
        state.set_model(selected)
        return Next(self.edges.on_success, state^)
