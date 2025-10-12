using Org.Freedesktop.Login1;

[GtkTemplate(ui = "/com/github/hyperparabolic/vanity/ui/menu-system-controls.ui")]
public class Vanity.MenuSystemControls : Gtk.Box {

  private ManagerSync proxy;

  [GtkChild]
  private unowned Vanity.ConfirmationButton sleep_button;

  [GtkChild]
  private unowned Vanity.ConfirmationButton hibernate_button;

  [GtkChild]
  private unowned Vanity.ConfirmationButton reboot_button;

  [GtkChild]
  private unowned Vanity.ConfirmationButton poweroff_button;

  [GtkCallback]
  public void activate_lock() {
    Vanity.Menu.instance.close_menu();
    VanityIO.Process.exec_asyncv.begin({ "bash", "-c", "loginctl lock-session" });
  }

  [GtkCallback]
  public void activate_logout() {
    Vanity.Menu.instance.close_menu();
    VanityIO.Process.exec_asyncv.begin({ "bash", "-c", "loginctl terminate-session $XDG_SESSION_ID" });
  }

  [GtkCallback]
  public void activate_sleep() {
    Vanity.Menu.instance.close_menu();
    VanityIO.Process.exec_asyncv.begin({ "bash", "-c", "systemctl suspend" });
  }

  [GtkCallback]
  public void activate_hibernate() {
    Vanity.Menu.instance.close_menu();
    VanityIO.Process.exec_asyncv.begin({ "bash", "-c", "systemctl hibernate" });
  }

  [GtkCallback]
  public void activate_reboot() {
    Vanity.Menu.instance.close_menu();
    VanityIO.Process.exec_asyncv.begin({ "bash", "-c", "systemctl reboot" });
  }

  [GtkCallback]
  public void activate_poweroff() {
    Vanity.Menu.instance.close_menu();
    VanityIO.Process.exec_asyncv.begin({ "bash", "-c", "systemctl poweroff" });
  }

  construct {
    try {
      proxy = Bus.get_proxy_sync(BusType.SYSTEM, "org.freedesktop.login1", "/org/freedesktop/login1");

      if (proxy.can_sleep() != "yes") {
        sleep_button.visible = false;
      }
      if (proxy.can_hibernate() != "yes") {
        hibernate_button.visible = false;
      }
      if (proxy.can_reboot() != "yes") {
        reboot_button.visible = false;
      }
      if (proxy.can_power_off() != "yes") {
        poweroff_button.visible = false;
      }
    } catch (Error e) {
      critical("menu system controls setup failed:");
      critical(e.message);
    }
  }
}
