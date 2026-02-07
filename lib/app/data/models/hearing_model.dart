import 'package:hive/hive.dart';

part 'hearing_model.g.dart';

@HiveType(typeId: 11)
class hearingModel extends HiveObject{
  
  @HiveField(0) String id;
  @HiveField(1) String caseId;

  @HiveField(2) DateTime hearingDate;

  // what happened today
  @HiveField(3) String summary;

  // orders passed
  @HiveField(4) String? orderNotes;

  // next hearing plan
  @HiveField(5) DateTime? nextHearingDate;
  @HiveField(6) String? nextHearingPurpose;
  @HiveField(7) String? nextHearingNotes;

  // files specific to this hearing
  @HiveField(8) List<String>? attachedFiles;

  // dynamic court facts
  @HiveField(9) Map<String, dynamic>? extraFields;

  @HiveField(10) DateTime createdAt;

  hearingModel({
    required this.id,
    required this.caseId,
    required this.hearingDate,
    required this.summary,
    this.orderNotes,
    this.nextHearingDate,
    this.nextHearingPurpose,
    this.nextHearingNotes,
    this.attachedFiles,
    this.extraFields,
    required this.createdAt,
  });

}