import 'dart:convert';
import 'dart:io';

Future<Map<String, List<String>>> loadEnStringReverseLookup(
  String path,
) async {
  final file = File(path);
  if (!await file.exists()) {
    throw FileSystemException(
      'intl reverse-lookup file not found',
      path,
    );
  }

  final enString = await file.readAsString();
  final enStringScrubbed = _removeNonJsonCharacters(enString);
  final dynamic parsedJson = jsonDecode(enStringScrubbed);
  if (parsedJson is! Map<String, dynamic>) {
    throw FormatException(
      'intl reverse-lookup file must decode to a JSON object',
      path,
    );
  }

  final enReverseLookup = <String, List<String>>{};
  parsedJson.forEach(
    (key, value) {
      if (value is String) {
        addToReverseLookup(
          reverseLookupMap: enReverseLookup,
          stringId: key,
          stringContent: value,
        );
      }
    },
  );

  return enReverseLookup;
}

void addToReverseLookup({
  required Map<String, List<String>> reverseLookupMap,
  required String stringId,
  required String stringContent,
}) {
  // Swap key/value so that text keys its original ID
  if (!reverseLookupMap.containsKey(stringContent)) {
    reverseLookupMap[stringContent] = <String>[];
  }
  reverseLookupMap[stringContent]?.add(stringId);

  // Add an all-caps text for the special case when code further modifies text with .toUpperCase()
  final valueUpperCase = stringContent.toUpperCase();
  if (stringContent != valueUpperCase) {
    if (!reverseLookupMap.containsKey(valueUpperCase)) {
      reverseLookupMap[valueUpperCase] = <String>[];
    }
    reverseLookupMap[valueUpperCase]?.add('$stringId.toUpperCase()');
  }
}

String _removeNonJsonCharacters(String text) {
  final trimmedText = text.trim();
  final startIndex = trimmedText.indexOf('{');
  final endIndex = trimmedText.lastIndexOf('}');
  if (startIndex == -1 || endIndex == -1 || endIndex < startIndex) {
    return trimmedText;
  }
  return trimmedText.substring(startIndex, endIndex + 1);
}
