// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_result.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MatchResultAdapter extends TypeAdapter<MatchResult> {
  @override
  final int typeId = 1;

  @override
  MatchResult read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MatchResult(
      matchDate: fields[0] as DateTime,
      homeTeam: fields[1] as String,
      awayTeam: fields[2] as String,
      score: fields[3] as String,
      outcomeIndex: fields[4] as int,
      goalScorers: (fields[5] as List?)?.cast<GoalScorer>(),
      memo: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, MatchResult obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.matchDate)
      ..writeByte(1)
      ..write(obj.homeTeam)
      ..writeByte(2)
      ..write(obj.awayTeam)
      ..writeByte(3)
      ..write(obj.score)
      ..writeByte(4)
      ..write(obj.outcomeIndex)
      ..writeByte(5)
      ..write(obj.goalScorers)
      ..writeByte(6)
      ..write(obj.memo);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MatchResultAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
