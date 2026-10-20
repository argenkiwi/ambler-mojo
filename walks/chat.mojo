from ambler import Next, Walk, amble, node_not_found
from nodes import chat_bye, llm_check, model_select, prompt, response
from utils.llm_chat import Message


@fieldwise_init
struct State(llm_check.State, model_select.State, prompt.State, response.State):
    var _messages: List[Message]
    var _host: String
    var _model: String

    def messages(self) -> List[Message]:
        return self._messages.copy()

    def add_message(mut self, var message: Message):
        self._messages.append(message^)

    def host(self) -> String:
        return self._host

    def set_host(mut self, value: String):
        self._host = value

    def model(self) -> String:
        return self._model

    def set_model(mut self, value: String):
        self._model = value


comptime LLM_CHECK = "LLM_CHECK"
comptime MODEL_SELECT = "MODEL_SELECT"
comptime CHAT_PROMPT = "CHAT_PROMPT"
comptime CHAT_RESPONSE = "CHAT_RESPONSE"
comptime CHAT_BYE = "CHAT_BYE"


struct Chat(Walk):
    comptime State = State

    var llm_check: llm_check.Node[]
    var model_select: model_select.Node[]
    var chat_prompt: prompt.Node[]
    var chat_response: response.Node[]
    var chat_bye: chat_bye.Node[]

    def __init__(out self):
        self.llm_check = llm_check.Node(
            llm_check.Edges(
                on_success=String(MODEL_SELECT), on_error=String(LLM_CHECK)
            ),
            llm_check.DefaultUtils(),
        )
        self.model_select = model_select.Node(
            model_select.Edges(on_success=String(CHAT_PROMPT)),
            model_select.DefaultUtils(),
        )
        self.chat_prompt = prompt.Node(
            prompt.Edges(
                on_message=String(CHAT_RESPONSE), on_quit=String(CHAT_BYE)
            ),
            prompt.DefaultUtils(),
        )
        self.chat_response = response.Node(
            response.Edges(on_complete=String(CHAT_PROMPT)),
            response.DefaultUtils(),
        )
        self.chat_bye = chat_bye.Node(
            chat_bye.Edges(on_done=None), chat_bye.DefaultUtils()
        )

    def step(
        mut self, node_id: String, var state: Self.State
    ) raises -> Next[Self.State]:
        if node_id == LLM_CHECK:
            return self.llm_check.run(state^)
        if node_id == MODEL_SELECT:
            return self.model_select.run(state^)
        if node_id == CHAT_PROMPT:
            return self.chat_prompt.run(state^)
        if node_id == CHAT_RESPONSE:
            return self.chat_response.run(state^)
        if node_id == CHAT_BYE:
            return self.chat_bye.run(state^)
        raise node_not_found(node_id)


def main() raises:
    var walk = Chat()
    _ = amble(walk, LLM_CHECK, State([], "", ""))
