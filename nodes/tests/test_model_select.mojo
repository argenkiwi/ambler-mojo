from std.testing import TestSuite, assert_equal

from nodes import model_select


@fieldwise_init
struct State(model_select.State):
    var _host: String
    var _model: String

    def host(self) -> String:
        return self._host

    def set_model(mut self, value: String):
        self._model = value


@fieldwise_init
struct FakeUtils(model_select.Utils):
    var models: List[String]
    var answer: Optional[String]

    def list_models(mut self, host: String) raises -> List[String]:
        return self.models.copy()

    def get_prompt(mut self, msg: String) -> Optional[String]:
        return self.answer

    def print_line(mut self, msg: String):
        pass


def make_node(
    var models: List[String], answer: Optional[String]
) -> model_select.Node[FakeUtils]:
    return model_select.Node(
        model_select.Edges(on_success=String("next")),
        FakeUtils(models^, answer),
    )


def test_transitions_to_on_success_with_selected_model() raises:
    var node = make_node(["llama3", "mistral"], String("2"))
    var result = node.run(State("http://localhost:11434", ""))
    assert_equal(result.node.value(), "next")
    assert_equal(result.state._model, "mistral")


def test_defaults_to_first_model_if_choice_is_empty() raises:
    var node = make_node(["llama3", "mistral"], String(""))
    var result = node.run(State("http://localhost:11434", ""))
    assert_equal(result.node.value(), "next")
    assert_equal(result.state._model, "llama3")


def test_allows_manual_model_entry_if_no_models_found() raises:
    var node = make_node([], String("custom-model"))
    var result = node.run(State("http://localhost:11434", ""))
    assert_equal(result.node.value(), "next")
    assert_equal(result.state._model, "custom-model")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
