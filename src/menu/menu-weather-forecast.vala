[GtkTemplate(ui = "/com/github/hyperparabolic/vanity/ui/menu-weather-forecast.ui")]
class Vanity.MenuWeatherForecast : Gtk.Box {
  static string[] iso_day_names = {"NUL", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"};

  [GtkChild]
  private unowned Gtk.Label day_label;

  [GtkChild]
  private unowned Gtk.Image icon_night;

  [GtkChild]
  private unowned Gtk.Image icon_day;

  [GtkChild]
  private unowned Gtk.Label temp_min;

  [GtkChild]
  private unowned Gtk.Label temp_max;

  public MenuWeatherForecast(VanityWeather.DaySummary ds) {
    day_label.label = iso_day_names[ds.iso_day_of_week];
    temp_min.label = ds.temp_min;
    temp_max.label = ds.temp_max;

    if (ds.icon_day != null) {
      icon_day.icon_name = ds.icon_day;
    } else {
      icon_day.visible = false;
    }

    if (ds.icon_night != null) {
      icon_night.icon_name = ds.icon_night;
    } else {
      icon_night.visible = false;
    }
  }
}
