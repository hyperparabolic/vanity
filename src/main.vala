public static void main(string[] args) {
  Adw.init();

  var app = new Vanity.Application();

  typeof (Vanity.Bar).ensure();
  typeof (Vanity.ConfirmationButton).ensure();
  typeof (Vanity.HyprlandWorkspaces).ensure();
  typeof (Vanity.Menu).ensure();
  typeof (Vanity.MenuIdle).ensure();
  typeof (Vanity.MenuSelector).ensure();
  typeof (Vanity.MenuSystemControls).ensure();
  app.run(args);
}
