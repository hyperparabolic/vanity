namespace VanityBrightness {
  public Device? get_default_screen() {
    return Device.get_default_screen(null);
  }

  public Device? get_default_keyboard() {
    return Device.get_default_keyboard(null);
  }
}

errordomain VanityBrightness.DeviceError {
  CODE_INVALID_PATH,
  CODE_NO_SUCH_DEVICE,
  CODE_MISSING_ATTRIBUTES,
  CODE_INIT_FAIL,
}

public class VanityBrightness.Device : Object {
  private static Device default_screen;
  private static Device default_keyboard;

  private string device_path;
  private string brightness_path;
  private FileMonitor brightness_monitor;
  private IBrightnessBus proxy;

  public string class { get; private set; }

  public string name { get; private set; }

  public uint32 brightness { get; set; }
  private uint32 last_brightness;

  public uint32 max_brightness { get; private set; }

  public static Device? get_default_screen(uint32? timer_refresh_ms) {
    // discover first device /sys/class/backlight/*
    if (default_screen != null) {
      return default_screen;
    }

    try {
      var backlight_dir = "/sys/class/backlight";
      var bl_dir = File.new_for_path(backlight_dir);
      var e = bl_dir.enumerate_children("standard::*", FileQueryInfoFlags.NONE);

      var info = e.next_file();
      if (info != null && info.get_file_type() == FileType.DIRECTORY) {
        default_screen = new Device(bl_dir.resolve_relative_path(info.get_name()).get_path(), timer_refresh_ms);
        return default_screen;
      }

      return null;
    } catch (Error e) {
      critical(e.message);
    }

    return null;
  }

  public static Device? get_default_keyboard(uint32? timer_refresh_ms) {
    if (default_keyboard != null) {
      return default_keyboard;
    }

    // discovery first device /sys/class/leds/*::kbd_backlight
    try {
      var leds_dir = "/sys/class/leds";
      var l_dir = File.new_for_path(leds_dir);
      var e = l_dir.enumerate_children("standard::*", FileQueryInfoFlags.NONE);

      FileInfo info = null;
      while ((info = e.next_file()) != null) {
        // look for  *::kbd_backlight device
        if (info.get_name().contains("::kbd_backlight")) {
          default_keyboard = new Device(l_dir.resolve_relative_path(info.get_name()).get_path(), timer_refresh_ms);
          return default_keyboard;
        }
      }
      return null;
    } catch (Error e) {
      critical(e.message);
    }

    return null;
  }

  /**
   * path is expected to be `/sys/class/<class>/<name>`
   *
   * At least for my device, hardware controls for the keyboard brightness do not update
   * the /sys/class/leds/brightness file. timer_refresh_ms may be specified to force
   * this.brightness to update every timer_refresh_ms ms.
   */
  public Device(string path, uint32? timer_refresh_ms) throws Error {
    this.device_path = path;

    this.proxy = Bus.get_proxy_sync(BusType.SYSTEM, "org.freedesktop.login1", "/org/freedesktop/login1/session/auto");

    var s = this.device_path.split("/", -1);

    if (s.length != 5 || s[1] != "sys" || s[2] != "class") {
      throw new DeviceError.CODE_INVALID_PATH("Invalid code path %s", this.device_path);
    }

    this.class = s[3];
    this.name = s[4];

    if (!FileUtils.test(this.device_path, FileTest.IS_DIR)) {
      throw new DeviceError.CODE_NO_SUCH_DEVICE("No such device %s", this.device_path);
    }

    var max_brightness_path = this.device_path + "/max_brightness";
    this.brightness_path = this.device_path + "/brightness";
    if (!FileUtils.test(max_brightness_path, FileTest.IS_REGULAR)) {
      throw new DeviceError.CODE_MISSING_ATTRIBUTES("Device %s has no max_brightness attribute", this.device_path);
    }
    if (!FileUtils.test(this.brightness_path, FileTest.IS_REGULAR)) {
      throw new DeviceError.CODE_MISSING_ATTRIBUTES("Device %s has no brightness attribute", this.device_path);
    }

    try {
      this.max_brightness = get_brightness_value_sync(max_brightness_path);
      this.brightness = get_brightness_value_sync(this.brightness_path);
      this.last_brightness = this.brightness;

      var file = File.new_for_path(this.brightness_path);
      brightness_monitor = file.monitor_file(FileMonitorFlags.NONE);

      brightness_monitor.changed.connect((_src, _dest, _event) => {
        update_brightness();
      });

      this.notify["brightness"].connect(() => {
        set_device_brightness(this.brightness);
        this.last_brightness = this.brightness;
      });

      if (timer_refresh_ms != null) {
        GLib.Timeout.add(timer_refresh_ms, () => {
          if (this.brightness_monitor == null || this.brightness_monitor.cancelled) {
            return false;
          }
          update_brightness();
          return true;
        });
      }

      brightness_monitor.ref();
      brightness_monitor.notify["cancelled"].connect(() => {
        if (!this.brightness_monitor.cancelled) {
          brightness_monitor.unref();
        }
      });
    } catch (Error e) {
      throw new DeviceError.CODE_INIT_FAIL("Initialization error: %s", e.message);
    }
  }

  ~Device() {
    if (this.brightness_monitor != null) {
      brightness_monitor.unref();
    }
  }

  private void set_device_brightness(uint32 value) {
    try {
      uint32 new_brightness = value;
      if (value > this.max_brightness) {
        new_brightness = this.max_brightness;
      }
      if (new_brightness == this.last_brightness) {
        return;
      }
      proxy.set_brightness(this.class, this.name, new_brightness);
    } catch (Error e) {
      critical(e.message);
    }
  }

  private void update_brightness() {
    // use async methods and suppress errors for updates
    var file = File.new_for_path(this.brightness_path);
    file.read_async.begin(Priority.DEFAULT, null, (obj, res) => {
      try {
        FileInputStream is = file.read_async.end(res);
        DataInputStream dis = new DataInputStream(is);
        var new_brightness = int.parse(dis.read_line());
        // set last brightness to prevent dbus call;
        this.last_brightness = new_brightness;
        this.brightness = new_brightness;
      } catch (Error e) {
        error("VanityBrightness.Device.update_brightness error: %s", e.message);
      }
    });
  }

  private int get_brightness_value_sync(string path) throws Error {
    // use syncrhonous methods for constructor
    var file = File.new_for_path(path);
    var is = file.read();
    var dis = new DataInputStream(is);
    var s_value = dis.read_line();
    return int.parse(s_value);
  }
}
