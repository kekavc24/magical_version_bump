import 'package:magical_version_bump/src/core/parsers/parser.dart';
import 'package:magical_version_bump/src/utils/enums/enums.dart';
import 'package:magical_version_bump/src/utils/extensions/extensions.dart';
import 'package:mason_logger/mason_logger.dart';

part 'dictionary_tokenizer.dart';
part 'token_definition.dart';

enum DictParserStatus { none, parsingKeys, parsingValues }

typedef DictBuilder = ({dynamic data, List<String> rootKeys});

typedef DictBuilderError = (int currentPosition, String error);

final class DictionaryParser extends Parser<DictBuilder> {
  final _tokenizer = DictionaryTokenizer.empty();
  DictParserStatus _parseStatus = DictParserStatus.none;

  DictionaryTokenType _lastToken = DictionaryTokenType.none;
  DictionaryTokenType _lastDelimiterToken = DictionaryTokenType.none;

  final _keys = <String>[];
  final _values = <dynamic>[];
  final _tempMapBuilder = <String>[];

  @override
  DictBuilder parse(String input, int inputIndex, {bool reset = true}) {
    if (input.isEmpty) {
      throw _getParseException(
        'Input cannot be empty!',
        currentInput: inputIndex,
        currentInputPosition: 0,
        input: input,
      );
    }
    _tokenizer.input = input;
    if (reset) _reset(); // Refresh parser incase parseAll was called

    final (builder, error) = _consumeBuilderTokens();

    if (error != null) {
      final (inputPosition, exception) = error;

      throw _getParseException(
        exception,
        currentInput: inputIndex,
        currentInputPosition: inputPosition,
        input: input,
      );
    }

    return builder!;
  }

  (DictBuilder?, DictBuilderError?) _consumeBuilderTokens() {
    DictBuilder? builder;
    DictBuilderError? builderError;

    // Consume tokens from generator
    for (final (currentPosition, DictionaryToken(:token, :tokenType))
        in _tokenizer.tokenize()) {
      final (value, error) = _buildDictionary(tokenType, token);

      if (value == null) {
        if (error != null) {
          builderError = (currentPosition, error);
          break;
        }
        continue;
      }

      builder = value;
    }

    return (builder, builderError);
  }

  (DictBuilder?, String?) _buildDictionary(
    DictionaryTokenType tokenType,
    String? token,
  ) {
    // Terminate if tokenizer generates error
    if (tokenType == DictionaryTokenType.error) {
      const error = r'Expected an escaped character after "\"';
      return (null, error);
    }

    // Terminate once no more tokens are present
    if (tokenType == DictionaryTokenType.end) {
      final canBuildMap = _tempMapBuilder.isNotEmpty;

      // Incase we never parsed any values
      if (_parseStatus == DictParserStatus.parsingKeys ||
          (_values.isEmpty && !canBuildMap)) {
        return (null, 'Expected at least one value but got nothing');
      }

      if (canBuildMap) {
        _buildMap();
      }
      final builder = (
        rootKeys: [..._keys],
        data: _values.length == 1 ? _values.first : [..._values]
      );

      return (builder, null);
    }

    // No delimiter should be the first token unless escaped
    if (tokenType.isDelimiter && _parseStatus == DictParserStatus.none) {
      return (null, 'Expected a key but found the delimiter, "$token"');
    }

    if (_parseStatus == DictParserStatus.none) {
      _parseStatus = DictParserStatus.parsingKeys;
    } else if (_parseStatus == DictParserStatus.parsingKeys &&
        tokenType == DictionaryTokenType.kvDelimiter) {
      _lastToken = tokenType;
      _lastDelimiterToken = tokenType;
      _parseStatus = DictParserStatus.parsingValues;
      return (null, null);
    }

    if (_parseStatus == DictParserStatus.parsingKeys) {
      return (null, _addKey(token, tokenType));
    }

    return (null, _addValue(token, tokenType));
  }

  String? _addKey(String? token, DictionaryTokenType tokenType) {
    // No success key delimiters
    if (tokenType.isDelimiter) {
      var message = 'Expected a key but found the delimiter, "$token". ';

      if (_lastToken.isDelimiter) {
        return message += 'Consider escaping any key delimiter(s) used.';
      } else if (tokenType == DictionaryTokenType.mapDelimiter) {
        return message += 'Value delimiters not allowed!';
      }

      _lastDelimiterToken = tokenType;
    } else {
      _keys.add(token!);
    }

    _lastToken = tokenType;
    return null;
  }

  String? _addValue(String? token, DictionaryTokenType tokenType) {
    // When current token is a delimiter
    if (tokenType.isDelimiter) {
      // A delimiter cannot be the first value
      if (_lastToken == DictionaryTokenType.kvDelimiter) {
        return 'Expected first value but found, "$token". Consider escaping it';
      }

      /// Consecutive delimiter tokens not allowed. Also a map delimiter cannot
      /// be after list delimiter unless escaped.
      ///
      /// Explicit as list delimiter can occur after a map delimiter when
      /// setting the value to null.
      if (_lastToken == tokenType ||
          (_lastToken == DictionaryTokenType.listDelimiter &&
              tokenType == DictionaryTokenType.mapDelimiter)) {
        return 'Expected a value but found, "$token". Consider escaping it';
      }

      // If by chance the last delimiter token was a map delimiter, build map
      if (_lastDelimiterToken == DictionaryTokenType.mapDelimiter &&
          tokenType == DictionaryTokenType.listDelimiter) {
        _buildMap();
      }

      _lastDelimiterToken = tokenType;
    } else {
      // If last token was a map delimiter, move to map builder
      if (_lastToken == DictionaryTokenType.mapDelimiter) {
        // If not empty, no need to pop last value in tracker
        if (_tempMapBuilder.isNotEmpty) {
          _tempMapBuilder.add(token!);
        } else {
          final lastEntry = _values.removeLast() as String;

          _tempMapBuilder.addAll([lastEntry, token!]);
        }
      } else {
        _values.add(token);
      }
    }

    _lastToken = tokenType;
    return null;
  }

  void _buildMap() {
    /// The last value in [tempMapBuilder] will be the terminal value,
    /// unless the last token type itself was the map delimiter, making it
    /// null
    final terminalValue = _lastToken == DictionaryTokenType.mapDelimiter
        ? 'null'
        : _tempMapBuilder.removeLast();

    // Next last value will be the direct key to value
    final targetKey = _tempMapBuilder.removeLast();

    final map = <dynamic, dynamic>{}.recursivelyUpdate(
      terminalValue,
      target: targetKey,
      path: _tempMapBuilder,
      updateMode: UpdateMode.overwrite,
    );

    final lastValue = _values.lastOrNull;

    // Merge last map present rather having multiple
    if (lastValue is Map) {
      lastValue.addAll(map);
    } else {
      _values.add(map);
    }

    _tempMapBuilder.clear(); // Reset map builder
  }

  ParseException _getParseException(
    String exception, {
    required int currentInput,
    required int currentInputPosition,
    required String input,
  }) {
    final message =
        '''[$currentInput: $currentInputPosition]: $input. \n${lightRed.wrap(exception)}''';
    return ParseException(message: message);
  }

  void _reset() {
    _parseStatus = DictParserStatus.none;
    _lastToken = DictionaryTokenType.none;
    _lastDelimiterToken = DictionaryTokenType.none;
    _keys.clear();
    _values.clear();
    _tempMapBuilder.clear();
  }
}
