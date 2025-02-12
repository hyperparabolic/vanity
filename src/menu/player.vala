[GtkTemplate(ui = "/com/github/hyperparabolic/vanity/ui/player.ui")]
class Vanity.Player : Gtk.Box {
  public AstalMpris.Player player { get; set; }

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
    player_album_art.clear();
    if (player.cover_art == null) {
      player_album_art.set_from_icon_name("emblem-music-symbolic");
      return;
    }

    try {
      var f = File.new_for_path(player.cover_art);
      var loader = new Gly.Loader(f);
      var image = loader.load();
      var frame = image.next_frame();
      var texture = GlyGtk4.frame_get_texture(frame);
      player_album_art.set_from_paintable(texture);
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
