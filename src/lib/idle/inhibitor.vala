using Org.Freedesktop.Login1;

namespace VanityIdle {
}

/**
 * Inhibits idle via the org.freedesktop.login1 dbus interface.
 *
 * This will not work with idle daemons that only implement the
 * wayland unstable idle inhibit protocol.
 */
public class VanityIdle.Inhibitor : Object {
  private static Inhibitor default_inhibitor;

  private static UnixInputStream inhibit_fd;
  // we only track one file descriptor, and do not want to double close either,
  // use mutex to protect these operations.
  private static Mutex inhibit_fd_mutex = Mutex();

  private static uint? inhibit_timeout;

  private ManagerSync proxy;

  public bool inhibit { get; private set; }


  public static Inhibitor? get_default() {
    if (default_inhibitor != null) {
      return default_inhibitor;
    }

    try {
      default_inhibitor = new Inhibitor();
      return default_inhibitor;
    } catch (Error e) {
      critical(e.message);
    }

    return null;
  }

  private Inhibitor() throws Error {
    this.proxy = Bus.get_proxy_sync(BusType.SYSTEM, "org.freedesktop.login1", "/org/freedesktop/login1");
    this.inhibit = false;
  }

  ~Inhibitor() {
    // attempt to clean up inhibitor on close
    if (inhibit_fd != null && !inhibit_fd.is_closed()) {
      try {
        inhibit_fd.close();
      } catch (Error e) {
        critical(e.message);
      }
    }
  }

  /**
   * Best effort. May not togggle if called repeatedly in quick succession.
   *
   * returns current this.inhibit on completion.
   */
  public bool toggle() {
    if (inhibit) {
      this.disable();
    } else {
      this.enable(-1);
    }
    return this.inhibit;
  }

  /**
   * The inhibitor will disable itself after `timeout_seconds` seconds.
   * Supply a negative `timeout_seconds` to last indefinitely.
   *
   * returns 0 if enable successful
   */
  public int enable(int timeout_seconds) {
    inhibit_fd_mutex.lock();
    if (inhibit_fd != null) {
      inhibit_fd_mutex.unlock();
      return 1;
    }

    var ret = 0;
    try {
      inhibit_fd = this.proxy.inhibit("idle", "vanity", "Inhibit system idle", "block");

      if (timeout_seconds >= 0) {
        GLib.Timeout.add_seconds_once(
          timeout_seconds,
          () => { this.disable(); });
      }

      this.inhibit = true;
    } catch (Error e) {
      critical(e.message);
      ret = -1;
    } finally {
      inhibit_fd_mutex.unlock();
    }
    return ret;
  }

  /**
   * returns 0 if disable successful
   */
  public int disable() {
    inhibit_fd_mutex.lock();
    if (inhibit_fd == null) {
      inhibit_fd_mutex.unlock();
      return 1;
    }

    var ret = 0;
    try {
      inhibit_fd.close();

      if (inhibit_timeout != null) {
        GLib.Source.remove(inhibit_timeout);
      }

      this.inhibit = false;
    } catch (Error e) {
      critical(e.message);
      ret = -1;
    } finally {
      inhibit_fd_mutex.unlock();
    }
    return ret;
  }
}
