[GtkTemplate(ui = "/com/github/hyperparabolic/vanity/ui/menu-weather.ui")]
class Vanity.MenuWeather : Gtk.Box {
  private static VanityWeather.Weather weather;

  [GtkChild]
  private unowned Gtk.Label location;

  [GtkChild]
  private unowned Gtk.Image now_icon;

  [GtkChild]
  private unowned Gtk.Label now_temp;

  [GtkChild]
  private unowned Gtk.ScrolledWindow scroll_window;

  [GtkChild]
  private unowned Gtk.Box forecast;

  [GtkCallback]
  public void refresh_location() {
    weather.v_loc.refresh();
  }

  [GtkCallback]
  public void refresh_weather() {
    weather.refresh();
  }

  public void render_forecast() {
    if (weather.forecast == null) {
      // forecast isn't available, wait for next updated signal
      return;
    }

    location.label = weather.forecast.location;
    now_icon.icon_name = weather.forecast.now_icon;
    now_temp.label = weather.forecast.now_temp;

    Gtk.Widget child = forecast.get_first_child();
    while (child != null) {
      forecast.remove(child);
      child = forecast.get_first_child();
    }

    for (var i = 0; i <= weather.forecast.days_length(); ++i) {
      var ds = weather.forecast.get_day(i);
      if (ds != null) {
        forecast.append(new Gtk.Separator(0));
        forecast.append(new Vanity.MenuWeatherForecast(ds));
      }
    }
  }

  construct {
    var ec = new Gtk.EventControllerScroll(Gtk.EventControllerScrollFlags.VERTICAL);
    // scroll horizonally with vertical scrolling
    ec.scroll.connect((dx, dy) => {
      if (ec.get_unit() == Gdk.ScrollUnit.SURFACE) {
        // surface scrolling always has horizontal scroll, ignore
        return false;
      }

      this.scroll_window.hadjustment.value += (dy * 30.0);
      return true;
    });
    this.scroll_window.add_controller(ec);

    weather = VanityWeather.Weather.get_default();

    weather.updated.connect(render_forecast);
    render_forecast();
  }
}
