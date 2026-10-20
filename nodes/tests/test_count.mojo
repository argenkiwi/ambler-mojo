from std.testing import TestSuite, assert_equal

from nodes import count


@fieldwise_init
struct State(count.State):
    var value: Int

    def count(self) -> Int:
        return self.value

    def set_count(mut self, value: Int):
        self.value = value


@fieldwise_init
struct FakeUtils(count.Utils):
    var roll: Float64

    def print_line(mut self, msg: String):
        pass

    def sleep(mut self, seconds: Float64):
        pass

    def random(mut self) -> Float64:
        return self.roll


def make_node(roll: Float64) -> count.Node[FakeUtils]:
    return count.Node(
        count.Edges(on_count=String("onCount"), on_stop=String("onStop")),
        FakeUtils(roll),
    )


def test_increments_and_transitions_to_on_count_if_random_above_half() raises:
    var node = make_node(0.6)
    var result = node.run(State(5))
    assert_equal(result.node.value(), "onCount")
    assert_equal(result.state.count(), 6)


def test_increments_and_transitions_to_on_stop_if_random_at_most_half() raises:
    var node = make_node(0.4)
    var result = node.run(State(10))
    assert_equal(result.node.value(), "onStop")
    assert_equal(result.state.count(), 11)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
