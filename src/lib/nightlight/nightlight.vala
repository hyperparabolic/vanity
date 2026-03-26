using Org.Freedesktop.Login1;

namespace VanityNightlight {
}

/**
 * State tracker and service management for a systemd user session wlsunset service
 *
 * Systemd state is watched and all state updates are triggered from state changes.
 *
 * Relies on file-state@wlsunset.service to monitor systemd state
 * without relying on manual systemd polling.
 * https://github.com/hyperparabolic/nix-config/blob/2dde993d489dc1d4ce13adc8d819d4a3e53a0369/modules/desktop/vanity.nix#L39
 * TODO: move this and home-manager module to this project
 */
public class VanityNightlight.Nightlight : Object {
  private static Nightlight default_nightlight;

  private static string state_file_path = @"$(Environment.get_home_dir())/.local/state/wlsunset-state";

  private static FileMonitor state_monitor;

  private static uint? inhibit_timeout;

  private static DateTime? inhibit_until;


  public bool enabled { get; private set; }

  public string status_icon { get; private set; }

  public static string enable_icon { get; set; default = "night-light-symbolic"; }

  public static string disable_icon { get; set; default = "night-light-disabled-symbolic"; }

  public static Nightlight? get_default() {
    if (default_nightlight != null) {
      return default_nightlight;
    }

    try {
      default_nightlight = new Nightlight();
      return default_nightlight;
    } catch (Error e) {
      critical(e.message);
    }

    return null;
  }

  private Nightlight() throws Error {
    var state_file = File.new_for_path(state_file_path);
    state_monitor = state_file.monitor_file(FileMonitorFlags.NONE, null);

    state_monitor.changed.connect((src, _, event) => {
      debug(@"src: $(src.get_path()), event: $(event.to_string())");
      if (event == FileMonitorEvent.CHANGES_DONE_HINT) {
        update_state();
      }
    });

    // assume enabled until state can be polled
    this.enabled = true;
    this.status_icon = enable_icon;
    update_state();
  }

  ~Nightlight() {
    state_monitor.cancel();
  }

  private void update_state() {
    var state_file = File.new_for_path(state_file_path);
    state_file.read_async.begin(Priority.DEFAULT, null, (obj, res) => {
      try {
        FileInputStream is = state_file.read_async.end(res);
        DataInputStream dis = new DataInputStream(is);

        var line = dis.read_line();
        dis.close();

        if (line == null) {
          return;
        }

        var new_state = int.parse(line.strip()) == 0;
        this.status_icon = new_state ? enable_icon : disable_icon;
        this.enabled = new_state ? true : false;

        debug(@"inhibit: $(this.enabled)");
        if (this.enabled) {
          // ensure timeouts are cleaned up when enabled
          if (inhibit_timeout != null) {
            GLib.Source.remove(inhibit_timeout);
          }

          inhibit_until = null;
        }
      } catch (Error e) {
        error("VanityNightlight.Nightlight.update_state error: %s", e.message);
      }
    });
  }

  /**
   * Best effort. May not togggle if called repeatedly in quick succession.
   * wlsunset also crashes if repeatedly toggled.
   */
  public void toggle() {
    if (enabled) {
      this.disable(0);
    } else {
      this.enable();
    }
    return;
  }

  /**
   * Ensures wlsunset is started.
   *
   * Best effort, logs errors
   */
  public void enable() {
    VanityIO.Process.exec_asyncv.begin({ "bash", "-c", "systemctl --user start wlsunset.service" }, (obj, res) => {
      try {
        var result = VanityIO.Process.exec_asyncv.end(res);

        if (!result.success) {
          error("VanityNightlight.Nightlight.enable error: %s", result.stderr);
        }
      } catch (Error e) {
        error(e.message);
      }
    });

    return;
  }

  /**
   * Ensures wlsunset is stopped.
   *
   * Service will be restarted depending on timeout_seconds:
   * timeout_seconds > 0: after timeout_seconds seconds
   * timeout_seconds == 0: at next 2AM
   * timeout_seconds < 0: never
   *
   * Best effort, logs errors
   */
  public void disable(int timeout_seconds) {
    VanityIO.Process.exec_asyncv.begin({ "bash", "-c", "systemctl --user stop wlsunset.service" }, (obj, res) => {
      try {
        var result = VanityIO.Process.exec_asyncv.end(res);

        if (!result.success) {
          error("VanityNightlight.Nightlight.disable error: %s", result.stderr);
        }
      } catch (Error e) {
        error(e.message);
      }
    });

    // restart service after timeout
    var timeout_final = timeout_seconds == 0 ? VanityTime.Util.seconds_until_two_am() : timeout_seconds;
    if (timeout_final >= 0) {
      GLib.Timeout.add_seconds_once(
        timeout_final,
        () => { this.enable(); });
      var now = new DateTime.now_local();
      inhibit_until = now.add_seconds(timeout_final);
    }

    return;
  }

  public string status_string() {
    if (!enabled) {
      return "Nightlight enabled";
    }
    if (inhibit_until == null) {
      return "Nightlight disabled until cancelled";
    }

    var time_string = inhibit_until.format("%I:%M %p");
    return @"Nightlight disabled until $(time_string)";
  }
}
