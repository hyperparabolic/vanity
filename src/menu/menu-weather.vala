[GtkTemplate(ui = "/com/github/hyperparabolic/vanity/ui/menu-weather.ui")]
class Vanity.MenuWeather : Gtk.Box {
  private static VanityWeather.Weather weather;

  [GtkChild]
  private unowned Gtk.Label location;

  [GtkChild]
  private unowned Gtk.Image now_icon;

  [GtkChild]
  private unowned Gtk.Label now_temp;

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
  }

  construct {
    weather = VanityWeather.Weather.get_default();

    weather.updated.connect(render_forecast);
    render_forecast();
  }
}
