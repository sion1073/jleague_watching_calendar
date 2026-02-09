// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goal_scorer.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GoalScorerAdapter extends TypeAdapter<GoalScorer> {
  @override
  final int typeId = 2;

  @override
  GoalScorer read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GoalScorer(
      name: fields[0] as String,
      team: fields[1] as String,
      minuteScored: fields[2] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, GoalScorer obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.team)
      ..writeByte(2)
      ..write(obj.minuteScored);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalScorerAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
