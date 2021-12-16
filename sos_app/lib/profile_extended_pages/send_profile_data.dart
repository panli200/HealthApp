import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_info.dart';
import 'package:shared_preferences/shared_preferences.dart';

void sendUserDate() async {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  late SharedPreferences prefs;
  SOSUser user = SOSUser();
  CollectionReference users = FirebaseFirestore.instance.collection('SoSUsers');

  prefs = await _prefs;
  user.generalPermission = (prefs.containsKey("GeneralPermission")
      ? prefs.getBool("GeneralPermission")
      : false)!;

  user.contactNum =
      (prefs.containsKey("Contact") ? prefs.getString("Contact") : '')!;
  user.medicalPermission = (prefs.containsKey("MedicalPermission")
      ? prefs.getBool("MedicalPermission")
      : false)!;
  user.personalHealthNum =
      (prefs.containsKey("HealthNum") ? prefs.getString("HealthNum") : '')!;
  user.personalMedicalFile = (prefs.containsKey("PersonalFile")
      ? prefs.getString("PersonalFile")
      : '')!;
  user.contactMedicalPermission = (prefs.containsKey("contactMedicalPermission")
      ? prefs.getBool("contactMedicalPermission")
      : false)!;
  user.contactHealthNum = (prefs.containsKey("ContactHealthNum")
      ? prefs.getString("ContactHealthNum")
      : '')!;
  user.contactMedicalFile =
      (prefs.containsKey("ContactFile") ? prefs.getString("ContactFile") : '')!;

  if (user.generalPermission == true) {
    await users
        .doc(user.uid)
        .collection('Profile Information')
        .doc('General Info')
        .set({
          'general permission': user.generalPermission,
          'emergency number': user.contactNum,
          // 'medical permission': user.medicalPermission,
          // 'personal health card': user.personalHealthNum,
          // 'personal medical file': user.personalMedicalFile,
          // 'contact medical permission': user.contactMedicalPermission,
          // 'contact health card': user.contactHealthNum,
          // 'contact medical file': user.contactMedicalFile,
        })
        .then((value) => print("User Updated"))
        .catchError((error) => print("Failed to add user: $error"));
  } else {
    await users
        .doc(user.uid)
        .collection('Profile Information')
        .doc('General Info')
        .set({
          'general permission': user.generalPermission,
          'emergency number': '',
        })
        .then((value) => print("User Updated"))
        .catchError((error) => print("Failed to add user: $error"));
  }

  if (user.medicalPermission == true) {
    await users
        .doc(user.uid)
        .collection('Profile Information')
        .doc('Medical Info')
        .set({
          'medical permission': user.medicalPermission,
          'personal health card': user.personalHealthNum,
          'personal medical file': user.personalMedicalFile,
        })
        .then((value) => print("User Updated"))
        .catchError((error) => print("Failed to add user: $error"));
  } else {
    await users
        .doc(user.uid)
        .collection('Profile Information')
        .doc('Medical Info')
        .set({
          'medical permission': user.medicalPermission,
          'personal health card': '',
          'personal medical file': '',
        })
        .then((value) => print("User Updated"))
        .catchError((error) => print("Failed to add user: $error"));
  }

  if (user.contactMedicalPermission == true) {
    await users
        .doc(user.uid)
        .collection('Profile Information')
        .doc('Contact Medical Info')
        .set({
          'contact medical permission': user.contactMedicalPermission,
          'contact health card': user.contactHealthNum,
          'contact medical file': user.contactMedicalFile,
        })
        .then((value) => print("User Updated"))
        .catchError((error) => print("Failed to add user: $error"));
  } else {
    await users
        .doc(user.uid)
        .collection('Profile Information')
        .doc('Contact Medical Info')
        .set({
          'contact medical permission': user.contactMedicalPermission,
          'contact health card': '',
          'contact medical file': '',
        })
        .then((value) => print("User Updated"))
        .catchError((error) => print("Failed to add user: $error"));
  }
}
