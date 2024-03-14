import 'package:convert/convert.dart';

import 'package:json_annotation/json_annotation.dart';

// part 'dough_fermentation.g.dart';

@JsonSerializable()
class StatusMessage {
  int status = 0;
  String message = "N/A";

  StatusMessage(this.status, this.message);

  StatusMessage.EmptyConstructor()
      : this.status = 0,
        this.message = "N/A";

  StatusMessage.fromJson(Map<String, dynamic> json) {
    this.status = json['Status'] as int;
    if (json['Message'] != null) {
     this.message = json['Message'] as String;
    }
  }

  Map<String, dynamic> toJson() =>
      {
        'Status': status,
        'Message': message,
      };
}