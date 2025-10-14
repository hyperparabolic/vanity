using GtkLayerShell;

[GtkTemplate(ui = "/com/github/hyperparabolic/vanity/ui/bar.ui")]
public class Vanity.Bar : Astal.Window {
  public static Bar instance { get; private set; }

  public string monitor_connector { get; private set; }

  public AstalBattery.Device battery { get; set; }

  [GtkChild]
  public unowned Gtk.Label clock;

  [GtkCallback]
  public void toggle_menu() {
    Vanity.Menu.instance.toggle_menu();
  }

  public Bar(Gdk.Monitor monitor) {
    Object(
      application: Vanity.Application.instance,
      // uncrustify bug, being interpreted as a namespace and applying an
      // incorrect rule, disable here.
      // *INDENT-OFF*
      namespace: @"bar-$(monitor.get_connector())",
      // *INDENT-ON*
      name: @"bar-$(monitor.get_connector())",
      gdkmonitor: monitor,
      anchor: Astal.WindowAnchor.LEFT | Astal.WindowAnchor.TOP | Astal.WindowAnchor.RIGHT
    );
    this.monitor_connector = monitor.get_connector();
    present();
  }

  construct {
    // Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION is lower priority than the theme styles,
    // and generally I think this is correct. Ignore window.background from that here though.
    this.remove_css_class("background");
    battery = AstalBattery.Device.get_default();
    init_clock();
    instance = this;
  }

  private void update_clock() {
    var clock_time = new DateTime.now_local();
    clock.label = clock_time.format("%I:%M %p %b %e");
  }

  private void init_clock() {
    update_clock();
    GLib.Timeout.add(60000, () => {
      update_clock();
      return true;
    });
  }
}
