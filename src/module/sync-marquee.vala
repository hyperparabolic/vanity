/**
 * Text marquees that move on a global cycle.
 *
 * All of these share animation keyframes and durations.
 *
 * Probably overengineered, but it helps with animations. I
 * wanted them to be syncrhonized across the application,
 * and to be in a natural "start" position if there isn't
 * a pre-existing marquee to sync with.
 *
 * Start / end easing with a sigmoid function might be cool,
 * but it just sits still at the start and end with linear
 * movement in between for now.
 */

// timing constants in seconds
const double LINGER_START = 2.0;
const double LINGER_END = 2.0;
const double MOVEMENT = 5.0;
// keep this in sync
const uint CYCLE_MS = 9000;
// approx
const uint SIXTY_FPS_MS = 16;

[GtkTemplate(ui = "/com/github/hyperparabolic/vanity/ui/sync-marquee.ui")]
class Vanity.SyncMarquee : Gtk.Box {

  public string label { get; set; }

  [GtkChild]
  private unowned Gtk.Adjustment scroll_adjust;

  [GtkChild]
  private unowned Gtk.ScrolledWindow viewport;

  [GtkChild]
  private unowned Gtk.Label scroll_label;


  // animation book keeping
  public bool root_visible { get; set; }
  private bool needs_scroll = false;
  private uint? tick_callback_id = null;

  private static uint? cycle_callback_id = null;
  private static uint? update_callback_id = null;
  private static Timer timer;
  private static double adjustment_multiplier = 0.0;

  private void try_add_global_timers() {
    if (cycle_callback_id != null) {
      // already in a cycle
      return;
    }

    cycle_callback_id = GLib.Timeout.add_once(CYCLE_MS, () => {
      // cleanup at the end of the cycle
      adjustment_multiplier = 0.0;
      GLib.Source.remove(update_callback_id);
      update_callback_id = null;
      cycle_callback_id = null;
      timer.stop();
    });

    // might be albe to bind this to a bar's frameclock? I'm not sure if this is actually better?
    // would have to be bar though, since it's the only surface that's always rendering.
    // needs bar cleanup first. the static instance only stores one, and it doesn't exist yet during
    // SyncMarquee's static constructor.
    update_callback_id = GLib.Timeout.add(SIXTY_FPS_MS, () => {
      var e_sec = timer.elapsed();

      if (e_sec < LINGER_START) {
        adjustment_multiplier = 0.0;
        return true;
      }

      if (e_sec > LINGER_START + MOVEMENT) {
        adjustment_multiplier = 1.0;
        return true;
      }

      var movement_elapsed = e_sec - LINGER_START;
      adjustment_multiplier = movement_elapsed / MOVEMENT;
      return true;
    });

    timer.start();
  }

  static construct {
    timer = new Timer();
  }


  private bool tick_callback() {
    try_add_global_timers();
    this.scroll_adjust.value = (this.scroll_adjust.upper - this.scroll_adjust.page_size) * adjustment_multiplier;
    return true;
  }

  private void try_add_tick_callback() {
    if (this.tick_callback_id != null) {
      return;
    }
    this.tick_callback_id = this.add_tick_callback(tick_callback);
  }

  private void try_remove_tick_callback() {
    if (this.tick_callback_id == null) {
      return;
    }
    this.remove_tick_callback(tick_callback_id);
    this.tick_callback_id = null;
  }

  construct {
    this.scroll_adjust.notify["upper"].connect(() => {
      var last = this.needs_scroll;
      this.needs_scroll = this.scroll_label.get_width() > this.viewport.get_width();
      if (this.needs_scroll != last) {
        // state changed, register or remove tick callback
        if (this.needs_scroll && this.visible) {
          try_add_tick_callback();
        } else {
          try_remove_tick_callback();
        }
      }
    });

    this.realize.connect(() => {
      var root = this.get_root();

      root.show.connect(() => {
        this.visible = true;
        if (this.needs_scroll) {
          this.try_add_tick_callback();
        }
      });
      root.hide.connect(() => {
        this.visible = false;
        this.try_remove_tick_callback();
      });
    });
  }
}
