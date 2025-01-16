using AstalHyprland;

/**
 * Multi-monitor workspace tracker.
 *
 * This behaves best with "persistent" workspaces that have already been initialized as empty,
 * otherwise only workspaces with clients will be shown.
 */
public class Vanity.HyprlandWorkspaces : Gtk.Box {
  private string monitor_connector;
  private HashTable<int, Gtk.Button> ws_map;
  public AstalHyprland.Hyprland hyprland { get; set; }

  construct {
    hyprland = AstalHyprland.Hyprland.get_default();
    ws_map = new HashTable<int, Gtk.Button>(
      (a) => { return a;},
      (a,b) => { return  a == b;}
    );
    init_workspaces();
  }

  private void init_workspaces() {
    // There is a small timing window during construction when parents are not yet initialized.
    // Small wait to work around this, consistently resolves after 1 timeout.
    GLib.Timeout.add(1, () => {
      var c = get_root_monitor_connector();
      if (c == null) {
        return true;
      }
      this.monitor_connector = c;
      handle_add_workspaces();
      setup_handlers();
      return false;
    });
  }

  private void setup_handlers() {
    hyprland.client_added.connect(update_css);
    hyprland.client_moved.connect(update_css);
    hyprland.client_removed.connect(update_css);
    hyprland.workspace_added.connect(handle_add_workspaces);
    hyprland.workspace_removed.connect(handle_remove_workspaces);
  }

  private string? get_root_monitor_connector() {
    var root = this.get_root();
    if (root != null) {
      return ((Vanity.Bar)root).monitor_connector;
    }
    return null;
  }

  /**
   * Gets a sorted list of workspaces.  These are **weak** references and may be cleaned up
   * at any time by Hyprland and AstalHyprland.
   */
  private List<weak Workspace> get_sorted_workspaces() {
    var workspaces = hyprland.workspaces.copy();

    workspaces.sort((a, b) => {
      return (int) (a.id > b.id) - (int) (a.id < b.id);
    });

    return workspaces;
  }

  private void update_css() {
    var workspaces = get_sorted_workspaces();

    foreach(var ws in workspaces) {
      if (ws == null || ws.monitor == null || ws.monitor.name != monitor_connector) {
        continue;
      }

      var button = ws_map.get(ws.id);
      update_button_styles(button, ws);
    }
  }

  private void handle_add_workspaces() {
    var workspaces = get_sorted_workspaces();

    foreach(var ws in workspaces) {
      if (ws == null || ws.monitor == null || ws.monitor.name != monitor_connector) {
        continue;
      }
      if (ws == null || ws_map.get(ws.id) != null) {
        continue;
      }

      debug("ws %s creating button", ws.id.to_string());
      var button = ws_button(ws);
      ws_map.set(ws.id, button);
      this.append(button);
    }
  }

  private void handle_remove_workspaces() {
    var workspaces = get_sorted_workspaces();
    GenericSet<int> ws_id_set = new GenericSet<int>(
      (a) => {return a;},
      (a,b) => { return a == b; }
    );
    foreach (var ws in workspaces) {
      if (ws == null || ws.monitor == null || ws.monitor.name != monitor_connector) {
        continue;
      }
      ws_id_set.add(ws.id);
    }

    List<int> remove_list = new List<int>();
    ws_map.for_each((id, btn) => {
      if (ws_id_set.contains(id) == false) {
        debug("ws %s removing button", id.to_string());
        this.remove(btn);
        remove_list.append(id);
      }
    });
    foreach(var id in remove_list) {
      ws_map.remove(id);
    }
  }

  private Gtk.Button ws_button(Workspace ws) {
    var button = new Gtk.Button();
    button.visible = true;
    button.add_css_class("ws_button");


    // set up callbacks
    var focused = hyprland.focused_workspace == ws;
    hyprland.notify["focused-workspace"].connect(() => {
      focused = hyprland.focused_workspace == ws;
      if (focused) {
        button.add_css_class("focused");
      } else {
        button.remove_css_class("focused");
      }
    });

    button.clicked.connect(() => {
      if (hyprland.focused_workspace != ws) {
        ws.focus();
      }
    });
    update_button_styles(button, ws);

    return button;
  }

  private void update_button_styles(Gtk.Button btn, Workspace ws) {
    if (ws.clients.length() > 0) {
      btn.add_css_class("occupied");
    } else {
      btn.remove_css_class("occupied");
    }

    var focused = hyprland.focused_workspace == ws;
    if (focused) {
      btn.add_css_class("focused");
    } else {
      btn.remove_css_class("focused");
    }
  }
}
