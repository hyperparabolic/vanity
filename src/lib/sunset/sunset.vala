namespace VanitySunset {
  public Sunset? get_default() {
      return Sunset.get_default();
  }
}

public class VanitySunset.Sunset : Object {
  private static Sunset instance;
  private VanitySystem.ISystemdUnitBus proxy;

  public static Sunset? get_default() {
    if (instance != null) {
      return instance;
    }
    try {
      instance = new Sunset();
      return instance;
    } catch (Error e) {
      critical(e.message);
    }
    return null;
  }

  private Sunset() throws Error {
    this.proxy = Bus.get_proxy_sync(BusType.SESSION, "org.freedesktop.systemd1", "/org/freedesktop/systemd1/unit/wlsunset_2eservice");
    proxy.g_properties_changed.connect(sync);
    sync();
  }

  public string active_state { owned get; private set; }

  public bool can_start { get; private set; }

  public bool can_stop { get; private set; }

  public string id { owned get; private set; }

  private void sync() {
    this.active_state = proxy.active_state;
    this.can_start = proxy.can_start;
    this.can_stop = proxy.can_stop;
    this.id = proxy.id;
  }

  public void restart() {
    if (this.can_start && this.can_stop) {
      try {
        proxy.restart("replace");
      } catch (Error e) {
        critical(e.message);
      }
    }
  }

  public void start() {
    if (this.can_start) {
      try {
        proxy.start("replace");
      } catch (Error e) {
        critical(e.message);
      }
    }
  }

  public void stop() {
    if (this.can_stop) {
      try {
        proxy.stop("replace");
      } catch (Error e) {
        critical(e.message);
      }
    }
  }
}
