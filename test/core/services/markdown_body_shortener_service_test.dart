import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/services/markdown_body_shortener_service.dart';

void main() {
  group("MarkdownBodyShortenerService.call", () {
    group('when markdown is more than 200 character', () {
      String markdown =
          "Lorem Ipsum is simply dummy text of the printing and typesetting industry Lorem Ipsum has been the industry's standard dummy text ever since the 1500s. when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries";

      test('trim only first 200 character with ...', () {
        String result = MarkdownBodyShortenerService.call(markdown);

        expect(markdown.length > 200, true);
        expect(result,
            "Lorem Ipsum is simply dummy text of the printing and typesetting industry Lorem Ipsum has been the industry's standard dummy text ever since the 1500s. when an unknown printer took a galley of type an...");
      });
    });

    group('when markdown is less than 200 character', () {
      String markdown =
          "Lorem Ipsum is simply dummy text of the printing and typesetting industry Lorem Ipsum has been the industry's standard dummy text ever since the 1500s.";

      test('return extract same markdown without ...', () {
        String result = MarkdownBodyShortenerService.call(markdown);

        expect(markdown.length < 200, true);
        expect(result,
            "Lorem Ipsum is simply dummy text of the printing and typesetting industry Lorem Ipsum has been the industry's standard dummy text ever since the 1500s.");
      });
    });

    group('when markdown is extactly 200 character', () {
      String markdown =
          "Lorem Ipsum is simply dummy text of the printing and typesetting industry Lorem Ipsum has been the industry's standard dummy text ever since the 1500s. when an unknown printer took a galley of type A.";

      test('return extract same markdown without ...', () {
        String result = MarkdownBodyShortenerService.call(markdown);
        expect(markdown.length, 200);
        expect(result,
            "Lorem Ipsum is simply dummy text of the printing and typesetting industry Lorem Ipsum has been the industry's standard dummy text ever since the 1500s. when an unknown printer took a galley of type A.");
      });
    });

    group('when markdown has less than 200 but has more than 10 line break', () {
      String markdown = "1\n2\n3\n4\n5\n6\n7\n8\n9\n10\n11\n12\n13\n";

      test('return first 10 line with ...', () {
        String result = MarkdownBodyShortenerService.call(markdown);
        expect(result, "1\n2\n3\n4\n5\n6\n7\n8\n9\n10...");
      });
    });
  });

  group("MarkdownBodyShortenerService.trimBody", () {
    group('when end with checkedbox', () {
      var markdownsToTest = {
        "checked": {
          "input": "This is my content\n- [x]",
          "expectation": "This is my content...",
        },
        "checked with space": {
          "input": "This is my content\n- [x] ",
          "expectation": "This is my content...",
        },
        "unfinished checked": {
          "input": "This is my content\n- [x",
          "expectation": "This is my content...",
        },
      };

      test('trim only first 200 character with ...', () {
        markdownsToTest.forEach((key, markdown) {
          final result = MarkdownBodyShortenerService.trimBody(markdown["input"]!);
          expect(result, markdown["expectation"]);
        });
      });
    });

    group('when end with unchecked-box', () {
      var markdownsToTest = {
        "checked": {
          "input": "This is my content\n- [ ]",
          "expectation": "This is my content...",
        },
        "checked with space": {
          "input": "This is my content\n- [ ] ",
          "expectation": "This is my content...",
        },
        "unfinished checked": {
          "input": "This is my content\n- [",
          "expectation": "This is my content...",
        },
        "unfinished checked woth space": {
          "input": "This is my content\n- [ ",
          "expectation": "This is my content...",
        },
      };

      test('trim only first 200 character with ...', () {
        markdownsToTest.forEach((key, markdown) {
          final result = MarkdownBodyShortenerService.trimBody(markdown["input"]!);
          expect(result, markdown["expectation"]);
        });
      });
    });

    group('when end with orderlist', () {
      var markdownsToTest = {
        "checked": {
          "input": "This is my content\n1.",
          "expectation": "This is my content...",
        },
        "checked with space": {
          "input": "This is my content\n1. ",
          "expectation": "This is my content...",
        },
      };

      test('trim only first 200 character with ...', () {
        markdownsToTest.forEach((key, markdown) {
          final result = MarkdownBodyShortenerService.trimBody(markdown["input"]!);
          expect(result, markdown["expectation"]);
        });
      });
    });
  });
}
