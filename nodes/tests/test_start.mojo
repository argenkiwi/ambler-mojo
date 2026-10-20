from std.testing import TestSuite, assert_equal

from nodes import start


@fieldwise_init
struct State(start.State):
    var value: Int

    def count(self) -> Int:
        return self.value

    def set_count(mut self, value: Int):
        self.value = value


@fieldwise_init
struct FakeUtils(start.Utils):
    var line: Optional[String]

    def read_line(mut self, msg: String) -> Optional[String]:
        return self.line

    def print_line(mut self, msg: String):
        pass


def make_node(line: Optional[String]) -> start.Node[FakeUtils]:
    return start.Node(
        start.Edges(on_success=String("NEXT"), on_error=String("ERROR")),
        FakeUtils(line),
    )


def test_empty_input_transitions_to_on_success_with_zero() raises:
    var node = make_node(String(""))
    var result = node.run(State(0))
    assert_equal(result.node.value(), "NEXT")
    assert_equal(result.state.count(), 0)


def test_number_input_transitions_to_on_success_with_number() raises:
    var node = make_node(String("42"))
    var result = node.run(State(0))
    assert_equal(result.node.value(), "NEXT")
    assert_equal(result.state.count(), 42)


def test_invalid_input_transitions_to_on_error() raises:
    var node = make_node(String("abc"))
    var result = node.run(State(123))
    assert_equal(result.node.value(), "ERROR")
    assert_equal(result.state.count(), 123)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
