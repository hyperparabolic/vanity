[GtkTemplate(ui = "/com/github/hyperparabolic/vanity/ui/confirmation-button.ui")]
public class Vanity.ConfirmationButton : Gtk.Button {
  public int timeout { get; set; default = 2000; }

  public string icon { get; set; }

  public string resting_icon { get; set; }

  public string confirmation_icon { get; set; }

  public signal void activated();

  private int click_count = 0;

  private uint? confirmation_timeout;

  private void ask_confirmation() {
    click_count++;
    this.icon_name = this.confirmation_icon;
    this.add_css_class("confirm");

    confirmation_timeout = GLib.Timeout.add_once(timeout, () => {
      cancel_ask_confirmation();
    });
  }

  private void cancel_ask_confirmation() {
    click_count = 0;
    if (confirmation_timeout != null) {
      GLib.Source.remove(confirmation_timeout);
    }
    this.icon_name = this.icon;
    this.remove_css_class("confirm");
  }

  [GtkCallback]
  public void on_clicked() {
    if (click_count == 0) {
      ask_confirmation();
      return;
    }

    cancel_ask_confirmation();
    activated();
  }

  private void init() {
    this.icon_name = this.icon;
  }

  construct {
    // let initialization settle
    GLib.Timeout.add_once(1, () => { this.init(); });
  }
}
