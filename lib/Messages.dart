
import 'package:json_annotation/json_annotation.dart';

// part 'dough_fermentation.g.dart';

@JsonSerializable()
class StatusMessage {
  int status = 0;
  String message = "N/A";

  StatusMessage(this.status, this.message);

  StatusMessage.EmptyConstructor()
      : status = 0,
        message = "N/A";

  StatusMessage.fromJson(Map<String, dynamic> json) {
    status = json['Status'] as int;
    if (json['Message'] != null) {
     message = json['Message'] as String;
    }
  }

  Map<String, dynamic> toJson() =>
      {
        'Status': status,
        'Message': message,
      };
}