import 'dart:convert'; // Importing dart:convert for JSON encoding/decoding

List<Users> usersFromJson(String str) =>
    List<Users>.from(json.decode(str).map((x) => Users.fromJson(x)));

Users userFromJson(String str) => Users.fromJson(json.decode(str));

String usersToJson(List<Users> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Users {
  int? id;
  String? fullname;
  String? email;
  String? password;
  String? gender;

  Users({
    this.id,
    this.fullname,
    this.email,
    this.password,
    this.gender,
  });

  factory Users.fromJson(Map<String, dynamic> json) => Users(
      id: json["id"],
      fullname: json["fullname"],
      email: json["email"],
      password: json["password"],
      gender: json["gender"]);

  Map<String, dynamic> toJson() => {
        "id": id,
        "fullname": fullname,
        "email": email,
        "password": password,
        "gender": gender,
      };
}
