[GtkTemplate(ui = "/com/github/hyperparabolic/vanity/ui/player.ui")]
class Vanity.Player : Gtk.Box {
  public AstalMpris.Player player { get; set; }

  // unix timestamp indicating last full art update, used for debounce
  private int64 last_update_unix = 0;

  [GtkChild]
  private unowned Gtk.Image player_album_art;

  [GtkCallback]
  public string play_pause_icon(AstalMpris.PlaybackStatus status) {
    return status == AstalMpris.PlaybackStatus.PLAYING
      ? "media-playback-pause-symbolic"
      : "media-playback-start-symbolic";
  }

  [GtkCallback]
  public void player_next() {
    this.player.next();
  }

  [GtkCallback]
  public void player_previous() {
    this.player.previous();
  }

  [GtkCallback]
  public void player_play_pause() {
    this.player.play_pause();
  }

  private void update_cover_art() {
    // firefox is doing something screwy here, and all cover art changes
    // are immediately being followed by another change blanking out the
    // changes. Debounce change for a bit after last full image
    var now_unix = new DateTime.now_utc().to_unix();
    if (now_unix - last_update_unix <= 6) {
      return;
    }

    if (player.cover_art == null || player.cover_art == "") {
      player_album_art.clear();
      player_album_art.set_from_icon_name("emblem-music-symbolic");
      return;
    }

    try {
      var texture = VanityIO.Image.load_image_texture(player.cover_art);
      player_album_art.clear();
      player_album_art.set_from_paintable(texture);
      last_update_unix = new DateTime.now_utc().to_unix();
    } catch (Error e) {
      player_album_art.set_from_icon_name("emblem-music-symbolic");
      critical(e.message);
    }
  }

  public Player(AstalMpris.Player player) {
    Object(player: player);

    player.notify["cover-art"].connect(() => this.update_cover_art());
  }
}
