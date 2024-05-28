class UserModel {
  late String uid;
  late String fullName;
  late String email;
  late String profileImage;
  late int dt;
  late String userTypeId; // Change userTypeId type to String

  UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.profileImage,
    required this.dt,
    required this.userTypeId, // Update userTypeId type
  });

  static UserModel fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'],
      fullName: map['fullName'],
      email: map['email'],
      profileImage: map['profileImage'],
      dt: map['dt'],
      userTypeId: map['userTypeId'] ?? '0', // Assign userTypeId from map, default to '0'
    );
  }
}
