class ImgPathName {
  // Der Name der Karte, synchron aus den Rohdaten
  final String name;

  // Der aufgelöste Bildpfad/die URL, der/die aus getImgPath() stammt
  final String imgUrl;

  ImgPathName({required this.name, required this.imgUrl});
}
