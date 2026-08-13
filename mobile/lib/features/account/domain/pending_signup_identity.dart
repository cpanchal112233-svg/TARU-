/// In-memory signup identity for an explicit retry of account-root creation.
class PendingSignupIdentity {
  String? name;
  String? email;

  void remember({required String name, required String email}) {
    this.name = name.trim();
    this.email = email.trim();
  }

  void clear() {
    name = null;
    email = null;
  }
}
