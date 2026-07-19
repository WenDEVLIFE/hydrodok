class UserSession {
   final String uid;
   final String email;
   final String fullName;
   final String phoneNumber;
   final String role;
   final String profileImageUrl;
   final String farmName;
   final String farmAddress;
   final List<String> farmProduceTypes;

   UserSession({
         required this.uid,
         required this.email,
         required this.fullName,
         required this.phoneNumber,
         required this.role,
         required this.profileImageUrl,
         required this.farmName,
         required this.farmAddress,
         required this.farmProduceTypes,
       });


}