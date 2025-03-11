class MarkdownBodyShortenerService {
  static String call(String markdown) {
    String body = markdown.trim();

    if (body.split("\n").length > 10) body = "${body.split("\n").getRange(0, 10).join("\n")}...";
    if (body.length <= 200) return body;

    String extract = body.substring(0, 200);
    var result = trimBody(extract);

    return result;
  }

  static String trimBody(String body) {
    body = body.trim();

    int bodyLength = body.length;
    int santitizedBodyLength = body.length;

    List<String> endWiths = [
      '-',
      "- [",
      "- [x",
      "- [ ]",
      "- [x]",
      ...List.generate(9, (index) => "$index."),
    ];

    for (String ew in endWiths) {
      if (body.endsWith(ew)) {
        santitizedBodyLength = bodyLength - ew.length;
      }
    }

    return bodyLength >= santitizedBodyLength ? "${body.substring(0, santitizedBodyLength).trim()}..." : body;
  }
}
