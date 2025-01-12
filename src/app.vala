namespace Vanity{
}

class Vanity.Application : Astal.Application {
  public static Application instance;

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
        var r = (Cairo.RectangleInt)monitor.get_geometry();
        var is_sidecar = r.height > r.width;
        add_window(new Vanity.Bar(monitor, is_sidecar));
      }
    }


    this.hold();
  }
}
