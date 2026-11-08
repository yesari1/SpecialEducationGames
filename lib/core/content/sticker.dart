/// A sticker of a theme (assets/content/stickers.json). Its name and voice are
/// those of the [item] it shows.
class Sticker {
  final String id, theme, item, image;
  const Sticker({
    required this.id,
    required this.theme,
    required this.item,
    required this.image,
  });
  factory Sticker.fromJson(Map<String, dynamic> j) => Sticker(
    id: j['id'] as String,
    theme: j['theme'] as String,
    item: j['item'] as String,
    image: j['image'] as String,
  );
}
