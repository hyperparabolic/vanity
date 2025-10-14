namespace Vanity {
  const string APP_ID = "com.github.hyperparabolic.vanity";
}

class Vanity.Application : Gtk.Application {
  public static Application instance;
  public AstalHyprland.Hyprland hyprland { get; set; }

  public static Vanity.Menu menu;
  private static VanityWeather.Weather weather;

  private static bool toggle_menu = false;

  private const OptionEntry[] options = {
    { "toggle-menu", 0, OptionFlags.NONE, OptionArg.NONE, ref toggle_menu, "Remote only, toggle menu on primary monitor", null },

    // terminator
    { null }
  };

  public override int command_line(ApplicationCommandLine command_line) {
    var args = command_line.get_arguments();

    try {
      var context = new OptionContext();
      context.set_help_enabled(true);
      context.add_main_entries(options, null);

      // parse removes strings from args without freeing, make a weak copy
      string *[] _args = new string[args.length];
      for (int i = 0; i < args.length; i++) {
        _args[i] = args[i];
      }
      unowned string[] tmp = _args;
      context.parse(ref tmp);
    } catch (OptionError e) {
      command_line.print("error: %s\n", e.message);
      command_line.print("Run '%s --help' to see a full list of available command line options.\n", args[0]);
      return 0;
    }

    if (command_line.is_remote) {
      if (toggle_menu) {
        menu.toggle_menu();
      }
    } else {
      init();
    }

    return 0;
  }

  private void init() {
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
        add_window(new Vanity.Bar(monitor));
        add_window(new Vanity.OSD(monitor));
      }
    }

    menu = new Vanity.Menu();
    add_window(menu);
  }

  public Application() {
    application_id = Vanity.APP_ID;
    flags =
      ApplicationFlags.HANDLES_COMMAND_LINE |
      // allow replacement with --gapplication-replace
      ApplicationFlags.ALLOW_REPLACEMENT;
  }

  construct {
    instance = this;
    hyprland = AstalHyprland.Hyprland.get_default();
    // weather singleton has async init that takes a while, start initialization now so other
    // consumers are more likely to have a forecast ready when they request it
    weather = VanityWeather.Weather.get_default();
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
}
