"""Ambler: a lightweight state-machine engine.

A walk is a graph of nodes. Each node receives the current state and returns
a `Next`: the ID of the node to run next (or `None` to stop) and the updated
state.
"""


@fieldwise_init
struct Next[S: Deinitable & Movable](Movable):
    """The result of a node's execution.

    Parameters:
        S: The machine's state type.
    """

    var node: Optional[String]
    """The next node ID, or `None` to stop."""
    var state: Self.S
    """The updated state."""

    def take_state(deinit self) -> Self.S:
        """Consumes this `Next`, returning its state."""
        return self.state^


trait Walk:
    """A graph of nodes that can be driven by `amble`.

    Implementors dispatch `node_id` to the matching node and raise
    `Error("Node not found: <id>")` for unknown IDs.
    """

    comptime State: Deinitable & Movable

    def step(
        mut self, node_id: String, var state: Self.State
    ) raises -> Next[Self.State]:
        ...


def node_not_found(node_id: String) -> Error:
    """The error a `Walk.step` raises for an unknown node ID."""
    return Error(t"Node not found: {node_id}")


def amble[
    W: Walk
](mut walk: W, start: String, var state: W.State) raises -> W.State:
    """Runs `walk` from node `start` until a node returns `None`.

    Parameters:
        W: The walk type.

    Args:
        walk: The walk to run.
        start: The ID of the first node.
        state: The initial state.

    Returns:
        The final state.

    Raises:
        If a node raises, or if a node ID is not part of the walk.
    """
    var node_id: Optional[String] = start
    while node_id:
        var next = walk.step(node_id.value(), state^)
        node_id = next.node.copy()
        state = next^.take_state()
    return state^
