[GtkTemplate(ui = "/com/github/hyperparabolic/vanity/ui/menu-audio-row.ui")]
public class Vanity.MenuAudioRow : Gtk.ListBoxRow {
  public AstalWp.Endpoint endpoint { get; construct; }

  [GtkChild]
  private unowned Gtk.Adjustment volume_adjust;

  [GtkCallback]
  public void on_clicked() {
    this.endpoint.is_default = true;
  }

  public void update_style() {
    if (this.endpoint.is_default) {
      this.add_css_class("audio_default");
    } else {
      this.remove_css_class("audio_default");
    }
  }

  public MenuAudioRow(AstalWp.Endpoint endpoint) {
    Object(endpoint: endpoint);
    this.endpoint.bind_property("volume", volume_adjust, "value",
                                GLib.BindingFlags.BIDIRECTIONAL | GLib.BindingFlags.SYNC_CREATE);
    this.endpoint.notify["is-default"].connect(() => update_style());
    update_style();
  }
}
