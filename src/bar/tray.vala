
public class Vanity.Tray : Gtk.Box {
  public AstalTray.Tray tray { get; private set; }
  private HashTable<string, Gtk.Widget> item_map;

  private void on_added(string item_id) {
    if (this.item_map.contains(item_id)) {
      return;
    }
    var item = tray_button(tray.get_item(item_id));
    this.item_map.insert(item_id, item);
    this.append(item);
    this.visible = true;
  }

  private void on_removed(string item_id) {
    if (!this.item_map.contains(item_id)) {
      return;
    }
    var item = this.item_map.take(item_id);
    this.remove(item);
    this.visible = item_map.size() > 0;
  }

  construct {
    this.visible = false;
    this.tray = AstalTray.get_default();
    this.item_map = new HashTable<string, Gtk.Widget>(str_hash, str_equal);

    this.tray.item_added.connect((t, item_id) => this.on_added(item_id));
    this.tray.item_removed.connect((t, item_id) => this.on_removed(item_id));
  }

  private Gtk.Widget tray_button(AstalTray.TrayItem item) {
    var btn = new Gtk.MenuButton();

    btn.direction = Gtk.ArrowType.DOWN;
    btn.add_css_class("tray_item");

    var icon = new Gtk.Image();
    item.bind_property("gicon", icon, "gicon", BindingFlags.SYNC_CREATE);
    btn.set_child(icon);

    item.notify["action-group"].connect(() => {
      btn.insert_action_group("dbusmenu", item.action_group);
    });
    btn.insert_action_group("dbusmenu", item.action_group);
    item.bind_property("menu-model", btn, "menu-model", BindingFlags.SYNC_CREATE);

    var lc = new Gtk.GestureClick();
    lc.set_button(Gdk.BUTTON_PRIMARY);
    lc.pressed.connect(() => {
      item.activate(0, 0);
    });
    btn.add_controller(lc);

    var rc = new Gtk.GestureClick();
    rc.set_button(Gdk.BUTTON_SECONDARY);
    rc.pressed.connect(() => {
      item.about_to_show();
      btn.popup();
    });
    btn.add_controller(rc);

    return btn;
  }
}
