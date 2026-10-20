from std.testing import TestSuite, assert_equal, assert_false

from nodes import stop


@fieldwise_init
struct State(stop.State):
    var value: Int

    def count(self) -> Int:
        return self.value


@fieldwise_init
struct FakeUtils(stop.Utils):
    var printed: List[String]

    def print_line(mut self, msg: String):
        self.printed.append(msg)


def test_prints_final_count_and_transitions_to_on_done() raises:
    var node = stop.Node(stop.Edges(on_done=None), FakeUtils([]))
    var result = node.run(State(15))
    assert_false(result.node)
    assert_equal(result.state.count(), 15)
    assert_equal(node.utils.printed, ["Final count: 15"])


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
