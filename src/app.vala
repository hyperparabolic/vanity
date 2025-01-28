namespace Vanity {}

class Vanity.Application : Astal.Application {
  public static Application instance;
  public AstalHyprland.Hyprland hyprland { get; set; }

  private static Vanity.Menu menu;

  public override void request(string msg, GLib.SocketConnection conn) {
    AstalIO.write_sock.begin(conn, @"missing response implementation on $instance_name");
  }

  construct {
    instance_name = "vanity";
    try {
      acquire_socket();
    } catch (Error e) {
      printerr("%s", e.message);
    }
    hyprland = AstalHyprland.Hyprland.get_default();
    instance = this;
  }

  public override void activate() {
    base.activate();

    Gtk.IconTheme icon_theme = Gtk.IconTheme.get_for_display(Gdk.Display.get_default());
    icon_theme.add_resource_path("/com/github/hyperparabolic/vanity/icons/");

    Gtk.CssProvider provider = new Gtk.CssProvider();
    provider.load_from_resource("com/github/hyperparabolic/vanity/vanity.css");
    Gtk.StyleContext.add_provider_for_display(Gdk.Display.get_default(), provider,
                                              Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

    var monitors = Gdk.Display.get_default().get_monitors();
    for (var i = 0; i <= monitors.get_n_items(); ++i) {
      var monitor = (Gdk.Monitor)monitors.get_item(i);

      if (monitor != null) {
        add_window(new Vanity.Bar(monitor, is_sidecar_monitor(monitor)));
      }
    }

    menu = new Vanity.Menu();
    add_window(menu);

    this.hold();
  }

  public void toggle_menu() {
    if (menu.visible == true) {
      menu.close_menu();
    } else {
      menu.open_menu();
    }
  }

  public Gdk.Monitor get_active_monitor() {
    var monitors = Gdk.Display.get_default().get_monitors();
    Gdk.Monitor? active_monitor = null;
    var focus = hyprland.focused_monitor;
    for (var i = 0; i <= monitors.get_n_items(); ++i) {
      var monitor = (Gdk.Monitor)monitors.get_item(i);

      if (monitor != null && monitor.connector == focus.name) {
        active_monitor = monitor;
      }
    }
    return active_monitor;
  }

  public static bool is_sidecar_monitor(Gdk.Monitor mon) {
    var r = (Cairo.RectangleInt)mon.get_geometry();
    return r.height > r.width;
  }
}
