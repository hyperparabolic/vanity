public static void main(string[] args) {
  Adw.init();
  Environment.set_prgname("vanity");

  var app = new Vanity.Application();

  typeof (Vanity.Bar).ensure();
  typeof (Vanity.ConfirmationButton).ensure();
  typeof (Vanity.HyprlandWorkspaces).ensure();
  typeof (Vanity.Menu).ensure();
  typeof (Vanity.MenuAudio).ensure();
  typeof (Vanity.MenuAudioRow).ensure();
  typeof (Vanity.MenuHud).ensure();
  typeof (Vanity.MenuIdle).ensure();
  typeof (Vanity.MenuSelector).ensure();
  typeof (Vanity.MenuSystemControls).ensure();
  typeof (Vanity.MenuWeather).ensure();
  typeof (Vanity.MenuWeatherForecast).ensure();
  typeof (Vanity.OSD).ensure();
  typeof (Vanity.Player).ensure();
  typeof (Vanity.SyncMarquee).ensure();
  typeof (Vanity.Tray).ensure();
  app.run(args);
}
