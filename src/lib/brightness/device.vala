namespace VanityBrightness {}

errordomain VanityBrightness.DeviceError {
  CODE_INVALID_PATH,
  CODE_NO_SUCH_DEVICE,
  CODE_MISSING_ATTRIBUTES,
  CODE_INIT_FAIL,
}

public class VanityBrightness.Device : Object {
  private string device_path;
  private string brightness_path;
  private FileMonitor brightness_monitor;
  private IBrightnessBus proxy;

  public string class { get; private set; }

  public string name { get; private set; }

  public uint32 brightness { get; private set; }

  public uint32 max_brightness { get; private set; }

  public Device(string path) throws Error {
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

      var file = File.new_for_path(this.brightness_path);
      brightness_monitor = file.monitor_file(FileMonitorFlags.NONE);

      brightness_monitor.changed.connect((_src, _dest, _event) => {
        update_brightness();
      });

      brightness_monitor.ref();
      brightness_monitor.notify["cancelled"].connect(() => {
        brightness_monitor.unref();
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

  public void set_device_brightness(uint32 value) {
    try {
      uint32 new_brightness = value;
      if (value > this.max_brightness) {
        new_brightness = this.max_brightness;
      }

      proxy.set_brightness(this.class, this.name, new_brightness);
    } catch (Error e) {
      message(e.message);
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
        if (new_brightness != this.brightness) {
          this.brightness = new_brightness;
        }
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
