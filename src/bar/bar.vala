using GtkLayerShell;

[GtkTemplate(ui = "/com/github/hyperparabolic/vanity/ui/bar.ui")]
public class Vanity.Bar : Astal.Window {
  public static Bar instance { get; private set; }

  [GtkChild]
  public unowned Gtk.Label clock;

  public Bar() {
    Object(
      namespace: "Bar",
      anchor: Astal.WindowAnchor.LEFT | Astal.WindowAnchor.TOP | Astal.WindowAnchor.RIGHT
    );
    present();
  }

  construct {
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
