[GtkTemplate(ui = "/com/github/hyperparabolic/vanity/ui/menu-hud.ui")]
class Vanity.MenuHud : Gtk.Box {
  public AstalMpris.Mpris mpris { get; private set; }
  public VanityWeather.ILocation location { get; private set; }
  public VanityWeather.Weather weather { get; private set; }

  private HashTable<string, Gtk.Widget> player_map;

  [GtkChild]
  private unowned Adw.Carousel players;

  [GtkChild]
  private unowned Gtk.Label latitude;

  [GtkChild]
  private unowned Gtk.Label longitude;

  [GtkCallback]
  public void refresh() {
    this.location.refresh();
  }

  private void on_player_added(AstalMpris.Player player) {
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
  }

  construct {
    this.player_map = new HashTable<string, Gtk.Widget>(str_hash, str_equal);
    this.mpris = AstalMpris.get_default();

    this.mpris.players.foreach((p) => this.on_player_added(p));
    this.mpris.player_added.connect((p) => this.on_player_added(p));
    this.mpris.player_closed.connect((p) => this.on_player_removed(p));

    this.location = VanityWeather.GeoclueLocation.get_default();
    this.location.notify["latitude"].connect(() => latitude.label = this.location.latitude.to_string());
    this.location.notify["longitude"].connect(() => longitude.label = this.location.longitude.to_string());
    this.location.init.begin();
    this.location.updated.connect(() => {
      this.weather = new VanityWeather.Weather(this.location);
    });
  }
}
