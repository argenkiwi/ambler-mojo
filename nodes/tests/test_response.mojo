from std.testing import TestSuite, assert_equal

from nodes import response
from utils.llm_chat import Message


@fieldwise_init
struct State(response.State):
    var _messages: List[Message]
    var _host: String
    var _model: String

    def messages(self) -> List[Message]:
        return self._messages.copy()

    def host(self) -> String:
        return self._host

    def model(self) -> String:
        return self._model

    def add_message(mut self, var message: Message):
        self._messages.append(message^)


@fieldwise_init
struct FakeUtils(response.Utils):
    var reply: String

    def chat(
        mut self, messages: List[Message], model: String, host: String
    ) raises -> String:
        return self.reply

    def print_line(mut self, msg: String):
        pass


def test_transitions_to_on_complete_and_appends_assistant_response() raises:
    var node = response.Node(
        response.Edges(on_complete=String("prompt")), FakeUtils("hi there")
    )
    var result = node.run(
        State([Message("user", "hello")], "http://localhost:11434", "llama3")
    )
    assert_equal(result.node.value(), "prompt")
    assert_equal(
        result.state.messages(),
        [Message("user", "hello"), Message("assistant", "hi there")],
    )


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
