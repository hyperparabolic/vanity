using Org.Freedesktop.Login1;

[GtkTemplate(ui = "/com/github/hyperparabolic/vanity/ui/menu-system-controls.ui")]
public class Vanity.MenuSystemControls : Gtk.Box {

  // TODO: hide children that cannot be executed (determined by
  // org.freedesktop.login1.Manager Can* methods), prevent methods
  // that cannot be executed, and add hibernate buttons for systems
  // that can support it.

  [GtkCallback]
  public void activate_lock() {
    Vanity.Menu.instance.close_menu();
    AstalIO.Process.exec_asyncv.begin({ "bash", "-c", "loginctl lock-session" });
  }

  [GtkCallback]
  public void activate_logout() {
    Vanity.Menu.instance.close_menu();
    AstalIO.Process.exec_asyncv.begin({ "bash", "-c", "loginctl terminate-session $XDG_SESSION_ID" });
  }

  [GtkCallback]
  public void activate_sleep() {
    Vanity.Menu.instance.close_menu();
    AstalIO.Process.exec_asyncv.begin({ "bash", "-c", "systemctl suspend" });
  }

  [GtkCallback]
  public void activate_reboot() {
    Vanity.Menu.instance.close_menu();
    AstalIO.Process.exec_asyncv.begin({ "bash", "-c", "systemctl reboot" });
  }

  [GtkCallback]
  public void activate_poweroff() {
    Vanity.Menu.instance.close_menu();
    AstalIO.Process.exec_asyncv.begin({ "bash", "-c", "systemctl poweroff" });
  }

  construct {
  }
}
