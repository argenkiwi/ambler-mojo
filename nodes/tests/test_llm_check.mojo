from std.testing import TestSuite, assert_equal

from nodes import llm_check


@fieldwise_init
struct State(llm_check.State):
    var _host: String

    def host(self) -> String:
        return self._host

    def set_host(mut self, value: String):
        self._host = value


@fieldwise_init
struct FakeUtils(llm_check.Utils):
    var reachable_host: String
    var answer: Optional[String]

    def check_host(mut self, host: String) -> Bool:
        return host == self.reachable_host

    def get_prompt(mut self, msg: String) -> Optional[String]:
        return self.answer

    def print_line(mut self, msg: String):
        pass


def make_node(
    reachable_host: String, answer: Optional[String]
) -> llm_check.Node[FakeUtils]:
    return llm_check.Node(
        llm_check.Edges(on_success=String("next"), on_error=String("retry")),
        FakeUtils(reachable_host, answer),
    )


def test_transitions_to_on_success_when_host_is_reachable() raises:
    var node = make_node("http://localhost:11434", None)
    var result = node.run(State("http://localhost:11434"))
    assert_equal(result.node.value(), "next")
    assert_equal(result.state.host(), "http://localhost:11434")


def test_transitions_to_on_error_with_new_host_when_user_provides_one() raises:
    var node = make_node("http://right:11434", String("http://right:11434"))
    var result = node.run(State("http://wrong:11434"))
    assert_equal(result.node.value(), "retry")
    assert_equal(result.state.host(), "http://right:11434")


def test_transitions_to_on_error_when_host_is_unreachable_and_user_cancels() raises:
    var node = make_node("", None)
    var result = node.run(State("http://wrong:11434"))
    assert_equal(result.node.value(), "retry")
    assert_equal(result.state.host(), "http://wrong:11434")


def test_tries_default_hosts_when_host_is_empty() raises:
    var node = make_node("http://localhost:1234/v1", None)
    var result = node.run(State(""))
    assert_equal(result.node.value(), "next")
    assert_equal(result.state.host(), "http://localhost:1234/v1")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
