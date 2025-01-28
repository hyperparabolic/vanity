[GtkTemplate(ui = "/com/github/hyperparabolic/vanity/ui/menu-selector.ui")]
public class Vanity.MenuSelector : Gtk.Box {
  public string icon { get; set; }

  public bool active {
    get {
      return this.has_css_class("active");
    }
    set {
      if (value) {
        this.add_css_class("active");
      } else {
        this.remove_css_class("active");
      }
    }
  }

  public bool inactive {
    get {
      return !this.has_css_class("active");
    }
    set {
      if (value) {
        this.remove_css_class("active");
      } else {
        this.add_css_class("active");
      }
    }
  }

  public signal void toggle_clicked();
  public signal void navigate_clicked();

  [GtkCallback]
  public void on_toggle_clicked() {
    toggle_clicked();
  }

  [GtkCallback]
  public void on_navigate_clicked() {
    navigate_clicked();
  }

  construct {}
}
