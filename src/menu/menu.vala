using GtkLayerShell;

[GtkTemplate(ui = "/com/github/hyperparabolic/vanity/ui/menu.ui")]
public class Vanity.Menu : Astal.Window {

  public string monitor_connector { get; private set; }

  public Menu(Gdk.Monitor monitor, bool is_sidecar) {
    Object(
      application: Vanity.Application.instance,
      namespace: @"menu-$(monitor.get_connector())",
      name: @"menu-$(monitor.get_connector())",
      gdkmonitor: monitor,
      anchor: Astal.WindowAnchor.TOP | Astal.WindowAnchor.RIGHT | Astal.WindowAnchor.BOTTOM
    );

    this.monitor_connector = monitor.get_connector();
    if (is_sidecar) {
      this.add_css_class ("sidecar");
    }

    present();
  }

  construct {
    init_watch_active();
  }

  private void init_watch_active() {
    GLib.Timeout.add(100, () => {
      if (this.is_active == false) {
        Vanity.Application.instance.toggle_menu();
        return false;
      }
      return true;
    });
  }
}
