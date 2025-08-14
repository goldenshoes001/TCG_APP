  import 'package:flutter/material.dart';

class UserProfileSide extends StatelessWidget {
  const UserProfileSide({super.key, this.username=""});
  final String username;


  @override
  Widget build(BuildContext context) {
    return Text("${username} willkommen auf deiner eigenen Seite ");
  }
}
  
 
        