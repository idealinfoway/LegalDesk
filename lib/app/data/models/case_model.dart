import 'package:hive/hive.dart';

part 'case_model.g.dart'; 

@HiveType(typeId: 0)
class CaseModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String clientName;

  @HiveField(3)
  String court;

  @HiveField(4)
  String caseNo;

  @HiveField(5)
  String status;

  @HiveField(6)
  DateTime? nextHearing;

  @HiveField(7)
  String notes;

  @HiveField(8)
  String? clientId;

  @HiveField(9)
  String? petitioner;

  @HiveField(10)
  String? petitionerAdv;

  @HiveField(11)
  String? respondent;

  @HiveField(12)
  String? respondentAdv;

  @HiveField(13)
  List<String>? attachedFiles;

  @HiveField(14)
  List<String>? vakalatMembers;


  @HiveField(15)
  String? srNo;

  @HiveField(16)
  DateTime? registrationDate;

  @HiveField(17)
  DateTime? filingDate;

  @HiveField(18)
  DateTime? vakalatDate;

  @HiveField(19)
  String? registrationNo;

  @HiveField(20)
  List<DateTime>? hearingDates;

  CaseModel({
    required this.id,
    required this.title,
    required this.clientName,
    required this.court,
    required this.caseNo,
    required this.status,
    this.nextHearing,
    required this.notes, 
    this.clientId,
    this.petitioner,
    this.petitionerAdv,
    this.respondent,
    this.respondentAdv,
    this.attachedFiles,
    this.vakalatMembers,
    this.srNo,
    this.registrationDate,
    this.filingDate,
    this.vakalatDate,
    this.registrationNo,
    this.hearingDates,
  });
}
