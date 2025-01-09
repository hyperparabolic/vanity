namespace Vanity{
}

class Vanity.Application : Astal.Application {
  public static Application instance;

  public override void activate() {
    base.activate();

    Gtk.CssProvider provider = new Gtk.CssProvider();
    provider.load_from_resource("com/github/hyperparabolic/vanity/vanity.css");
    Gtk.StyleContext.add_provider_for_display(Gdk.Display.get_default(), provider,
                                              Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

    add_window(new Vanity.Bar());
    this.hold();
  }
}
