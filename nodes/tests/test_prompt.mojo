from std.testing import TestSuite, assert_equal

from nodes import prompt
from utils.llm_chat import Message


@fieldwise_init
struct State(prompt.State):
    var messages: List[Message]

    def add_message(mut self, var message: Message):
        self.messages.append(message^)


@fieldwise_init
struct FakeUtils(prompt.Utils):
    var answer: Optional[String]

    def prompt(mut self, msg: String) -> Optional[String]:
        return self.answer

    def print_line(mut self, msg: String):
        pass


def make_node(answer: Optional[String]) -> prompt.Node[FakeUtils]:
    return prompt.Node(
        prompt.Edges(on_message=String("transpose"), on_quit=String("bye")),
        FakeUtils(answer),
    )


def test_transitions_to_on_message_when_user_enters_a_message() raises:
    var node = make_node(String("hello"))
    var result = node.run(State([]))
    assert_equal(result.node.value(), "transpose")
    assert_equal(result.state.messages, [Message("user", "hello")])


def test_transitions_to_on_quit_when_user_enters_a_quit_word() raises:
    var node = make_node(String("exit"))
    var result = node.run(State([]))
    assert_equal(result.node.value(), "bye")
    assert_equal(len(result.state.messages), 0)


def test_quit_words_are_case_insensitive_and_trimmed() raises:
    var node = make_node(String("  BYE "))
    var result = node.run(State([]))
    assert_equal(result.node.value(), "bye")


def test_transitions_to_on_quit_when_user_cancels_input() raises:
    var node = make_node(None)
    var result = node.run(State([]))
    assert_equal(result.node.value(), "bye")
    assert_equal(len(result.state.messages), 0)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
