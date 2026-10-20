from std.io import FileDescriptor


def get_prompt(message: String) -> Optional[String]:
    """Prompts the user for input via the terminal.

    Reads stdin one byte at a time rather than using `input()`, which (as of
    Mojo 1.1) buffers a whole chunk of piped stdin and drops every line after
    the first.

    Args:
        message: The message to display to the user.

    Returns:
        The user's input, or `None` if input was closed (e.g. Ctrl+D).
    """
    print(message, end="", flush=True)
    var stdin = FileDescriptor(0)
    var line = List[UInt8]()
    var byte: List[UInt8] = [0]
    try:
        while stdin.read_bytes(byte) > 0:
            if byte[0] == UInt8(ord("\n")):
                return String(from_utf8=line)
            line.append(byte[0])
        if line:
            return String(from_utf8=line)
    except:
        pass
    return None
