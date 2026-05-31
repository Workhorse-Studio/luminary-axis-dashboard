part of axis_dashboard;

Future<JSON?> loadUser() async {
  if (auth.currentUser == null) return null;
  final userData =
      (await firestore.collection('users').doc(auth.currentUser!.uid).get())
          .data();
  if (userData != null) {
    role = userData['role'];
    isAdmin = role == 'admin';
  }
  return userData;
}
