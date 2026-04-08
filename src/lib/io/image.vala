public class VanityIO.Image {

  public static Gdk.Texture load_image_texture(string path) throws Error {
    var file = File.new_for_path(path);
    var loader = new Gly.Loader(file);
    var image = loader.load();
    var frame = image.next_frame();
    var texture = GlyGtk4.frame_get_texture(frame);
    return texture;
  }
}
