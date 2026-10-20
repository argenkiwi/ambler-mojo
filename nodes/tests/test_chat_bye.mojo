from std.testing import TestSuite, assert_equal

from nodes import chat_bye


@fieldwise_init
struct State(Movable):
    pass


@fieldwise_init
struct FakeUtils(chat_bye.Utils):
    var printed: List[String]

    def print_line(mut self, msg: String):
        self.printed.append(msg)


def test_says_goodbye_and_transitions_to_on_done() raises:
    var node = chat_bye.Node(chat_bye.Edges(on_done=String("end")), FakeUtils([]))
    var result = node.run(State())
    assert_equal(result.node.value(), "end")
    assert_equal(node.utils.printed, ["Goodbye!"])


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
