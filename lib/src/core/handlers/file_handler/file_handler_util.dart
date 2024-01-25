part of 'file_handler.dart';

/// Obtains the file type for each file name
Map<String, FileType> getFileTypes(List<String> paths) {
  return paths.fold({}, (previousValue, path) {
    previousValue.addAll(
      {path: path.split('.').last.toLowerCase().fileType},
    );
    return previousValue;
  });
}
