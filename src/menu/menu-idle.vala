[GtkTemplate(ui = "/com/github/hyperparabolic/vanity/ui/menu-idle.ui")]
class Vanity.MenuIdle : Gtk.Box {
  public VanityIdle.Inhibitor vii { get; private set; }

  [GtkChild]
  private unowned Gtk.Box inhibit_status;

  [GtkChild]
  private unowned Gtk.Box inhibit_controls;

  [GtkChild]
  private unowned Gtk.Label disable_status;

  [GtkCallback]
  public void inhibit() {
    this.vii.enable(-1);
  }

  [GtkCallback]
  public void inhibit_10_min() {
    this.vii.enable(10 * 60);
  }

  [GtkCallback]
  public void inhibit_20_min() {
    this.vii.enable(20 * 60);
  }

  [GtkCallback]
  public void inhibit_30_min() {
    this.vii.enable(30 * 60);
  }

  [GtkCallback]
  public void inhibit_1_hr() {
    this.vii.enable(1 * 60 * 60);
  }

  [GtkCallback]
  public void inhibit_2_hr() {
    this.vii.enable(2 * 60 * 60);
  }

  [GtkCallback]
  public void inhibit_4_hr() {
    this.vii.enable(4 * 60 * 60);
  }

  [GtkCallback]
  public void disable_inhibit() {
    this.vii.disable();
  }

  construct {
    this.vii = VanityIdle.Inhibitor.get_default();

    this.vii.notify["inhibit"].connect(() => { sync(); });
    sync();
  }

  private void sync() {
    disable_status.label = @"Inhibited $(this.vii.disable_status())";
    inhibit_status.visible = this.vii.inhibit;
    inhibit_controls.visible = !this.vii.inhibit;
  }
}
