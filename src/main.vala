public static void main(string[] args) {
    var app = new Vanity.Application();

    typeof(Vanity.Bar).ensure();
    typeof(Vanity.HyprlandWorkspaces).ensure();
    app.run(args);
}
