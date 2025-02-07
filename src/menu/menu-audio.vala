const string[] IGNORE_ENDPOINTS = { "Easy Effects Sink", "Easy Effects Source" };

[GtkTemplate(ui = "/com/github/hyperparabolic/vanity/ui/menu-audio.ui")]
class Vanity.MenuAudio : Gtk.Box {
  public AstalWp.Wp wp { get; private set; }

  private HashTable<uint, Vanity.MenuAudioRow> row_map;
  private GenericSet<string> ignore_set;

  [GtkChild]
  private unowned Adw.ExpanderRow sinks_expander;

  [GtkChild]
  private unowned Adw.ExpanderRow sources_expander;

  [GtkChild]
  private unowned Adw.ExpanderRow streams_expander;

  private void on_added(AstalWp.Endpoint ep, Adw.ExpanderRow exp) {
    if (this.ignore_set.contains(ep.description)) {
      return;
    }

    var row = new Vanity.MenuAudioRow(ep);
    row_map.insert(ep.id, row);
    exp.add_row(row);
  }

  private void on_removed(AstalWp.Endpoint ep, Adw.ExpanderRow exp) {
    if (this.ignore_set.contains(ep.description)) {
      return;
    }

    var row = row_map.take(ep.id);
    exp.remove(row);
  }

  construct {
    this.row_map = new HashTable<uint, Vanity.MenuAudioRow>(
      (a) => { return a; },
      (a, b) => { return a == b; });
    this.ignore_set = new GenericSet<string>(
      (a) => { return a.hash(); },
      (a, b) => { return a == b; });
    foreach (var ignore in IGNORE_ENDPOINTS) {
      this.ignore_set.add(ignore);
    }

    this.wp = AstalWp.get_default();

    this.wp.audio.speakers.foreach(ep => this.on_added(ep, this.sinks_expander));
    this.wp.audio.speaker_added.connect((a, ep) => this.on_added(ep, this.sinks_expander));
    this.wp.audio.speaker_removed.connect((a, ep) => this.on_removed(ep, this.sinks_expander));

    this.wp.audio.microphones.foreach(ep => this.on_added(ep, this.sources_expander));
    this.wp.audio.microphone_added.connect((a, ep) => this.on_added(ep, this.sources_expander));
    this.wp.audio.microphone_removed.connect((a, ep) => this.on_removed(ep, this.sources_expander));

    this.wp.audio.streams.foreach(ep => this.on_added(ep, this.streams_expander));
    this.wp.audio.stream_added.connect((a, ep) => this.on_added(ep, this.streams_expander));
    this.wp.audio.stream_removed.connect((a, ep) => this.on_removed(ep, this.streams_expander));
  }
}
