"""Client for OpenAI-compatible chat APIs (e.g. Ollama, LM Studio).

Mojo's stdlib has no HTTP client, so requests go through Python's
`urllib.request` via Python interop.
"""

from std.python import Python, PythonObject


@fieldwise_init
struct Message(Copyable, Equatable, Movable, Writable):
    """A chat message."""

    var role: String
    """Either "user" or "assistant"."""
    var content: String
    """The message text."""


def _v1(host: String) -> String:
    if host.endswith("/v1"):
        return host
    return host + "/v1"


def llm_chat(
    messages: List[Message], model: String, host: String
) raises -> String:
    """Sends a conversation history to an OpenAI-compatible API.

    Args:
        messages: The conversation history.
        model: The model to use.
        host: The API host URL (e.g. http://localhost:11434/v1).

    Returns:
        The assistant's response content.

    Raises:
        If the request fails or the response is malformed.
    """
    var url = host + "/chat/completions"
    var request = Python.import_module("urllib.request")
    var json = Python.import_module("json")

    var py_messages = Python.list()
    for message in messages:
        py_messages.append(
            Python.dict(role=message.role, content=message.content)
        )
    var body = json.dumps(
        Python.dict(model=PythonObject(model), messages=py_messages)
    )

    try:
        var headers: PythonObject = {"Content-Type": "application/json"}
        var req = request.Request(
            url, data=body.encode("utf-8"), headers=headers, method="POST"
        )
        var data = json.loads(request.urlopen(req).read())
        return String(py=data["choices"][0]["message"]["content"])
    except e:
        print(
            String(
                t"Error sending request to LLM:\n  URL: {url}\n  Body:"
                t" {String(py=body)}\n  Error: {e}"
            )
        )
        raise e^


def check_host(host: String) -> Bool:
    """Checks if the LLM host is reachable.

    Args:
        host: The API host URL (e.g. http://localhost:11434/v1).

    Returns:
        True if `<host>/models` answers with a success status.
    """
    try:
        var request = Python.import_module("urllib.request")
        var response = request.urlopen(_v1(host) + "/models", timeout=5)
        var status = Int(py=response.status)
        return status >= 200 and status < 300
    except:
        return False


def list_models(host: String) raises -> List[String]:
    """Lists available models from the LLM host.

    Args:
        host: The API host URL (e.g. http://localhost:11434/v1).

    Returns:
        The model IDs.

    Raises:
        If the request fails or the response is malformed.
    """
    var request = Python.import_module("urllib.request")
    var json = Python.import_module("json")
    var data = json.loads(request.urlopen(_v1(host) + "/models").read())
    var models = List[String]()
    for model in data["data"]:
        models.append(String(py=model["id"]))
    return models^
