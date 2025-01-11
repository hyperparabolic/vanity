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

    // debugging: icons theme is the expected theme, icons are definitely present,
    // but "missing image" icon is showing for all images. needs more digging.
    print(icon_theme.get_theme_name());
    if (icon_theme.has_icon("battery-level-100-charged-symbolic")) {
      print("\ntheme has \"battery-level-100-charged-symbolic\" icon\n");
    }
    if (icon_theme.has_icon("nixos-symbolic")) {
      print("\nnixos icon successfully loaded\n");
    }

    Gtk.CssProvider provider = new Gtk.CssProvider();
    provider.load_from_resource("com/github/hyperparabolic/vanity/vanity.css");
    Gtk.StyleContext.add_provider_for_display(Gdk.Display.get_default(), provider,
                                              Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

    add_window(new Vanity.Bar());
    this.hold();
  }
}
