// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_highlight.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MatchHighlightAdapter extends TypeAdapter<MatchHighlight> {
  @override
  final int typeId = 3;

  @override
  MatchHighlight read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MatchHighlight(
      url: fields[0] as String,
      title: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, MatchHighlight obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.url)
      ..writeByte(1)
      ..write(obj.title);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MatchHighlightAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
