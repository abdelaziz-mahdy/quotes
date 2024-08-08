class Quote {
  String quote = "";
  String author = "";
  String topic = "";
  int selected = 0;
  int favorite = 0;

  Quote(this.quote, this.author, this.topic, this.favorite);
  void toggleSelected() {
    selected++;
    selected = selected % 2;
    print(selected);
  }

  void toggleFavorite() {
    favorite++;
    favorite = favorite % 2;
    print(favorite);
  }

  Map<String, dynamic> toMap() {
    return {
      'quote': quote,
      'author': author,
      'topic': topic,
      'favorite': favorite,
    };
  }
}
