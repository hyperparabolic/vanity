public static void main(string[] args) {
    var app = new Vanity.Application();

    typeof(Vanity.Bar).ensure();
    app.run(args);
}
