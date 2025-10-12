namespace VanityIO {
}

public struct VanityIO.ProcessResult {
  public bool success;
  public string stdout;
  public string stderr;
}

public class VanityIO.Process {

  public static async ProcessResult exec_asyncv(string[] cmd) throws Error {
    var process = new Subprocess.newv(
      cmd,
      SubprocessFlags.STDERR_PIPE |
      SubprocessFlags.STDOUT_PIPE
    );

    string err_str, out_str;
    yield process.communicate_utf8_async(null, null, out out_str, out err_str);

    var result = ProcessResult() {
      success = process.get_successful(),
      stdout = out_str,
      stderr = err_str
    };
    return result;
  }
}
