[GtkTemplate(ui = "/com/github/hyperparabolic/vanity/ui/menu-hud.ui")]
class Vanity.MenuHud : Gtk.Box {
  public AstalMpris.Mpris mpris { get; private set; }

  private Gtk.Box player_stub = new Vanity.PlayerStub();

  private HashTable<string, Gtk.Widget> player_map;

  [GtkChild]
  private unowned Adw.Carousel players;

  private void on_player_added(AstalMpris.Player player) {
    if (player_map.length == 0) {
      this.players.remove(this.player_stub);
    }
    var vplayer = new Vanity.Player(player);
    player_map.insert(player.bus_name, vplayer);
    this.players.append(vplayer);
  }

  private void on_player_removed(AstalMpris.Player player) {
    if (!player_map.contains(player.bus_name)) {
      return;
    }
    var vplayer = player_map.take(player.bus_name);
    this.players.remove(vplayer);
    if (player_map.length == 0) {
      this.players.append(this.player_stub);
    }
  }

  construct {
    this.player_map = new HashTable<string, Gtk.Widget>(str_hash, str_equal);
    this.mpris = AstalMpris.get_default();

    this.mpris.players.foreach((p) => this.on_player_added(p));
    this.mpris.player_added.connect((p) => this.on_player_added(p));
    this.mpris.player_closed.connect((p) => this.on_player_removed(p));

    this.players.append(this.player_stub);
  }
}
