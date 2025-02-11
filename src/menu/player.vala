[GtkTemplate(ui = "/com/github/hyperparabolic/vanity/ui/player.ui")]
class Vanity.Player : Gtk.Box {
  public AstalMpris.Player player { get; set; }

  [GtkCallback]
  public string art_path(string? path) {
    // TODO: better fallback for null? I'll have to see how common it is for my media.
    return path == null ? "" : path;
  }

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

  public Player(AstalMpris.Player player) {
    Object(player: player);
  }
}
