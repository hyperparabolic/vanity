public static void main(string[] args) {
  Adw.init();

  var app = new Vanity.Application();

  typeof (Vanity.Bar).ensure();
  typeof (Vanity.HyprlandWorkspaces).ensure();
  typeof (Vanity.Menu).ensure();
  typeof (Vanity.MenuSelector).ensure();
  app.run(args);
}
