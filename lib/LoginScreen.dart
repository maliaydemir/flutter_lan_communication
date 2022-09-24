import 'package:flutter/material.dart';
import 'package:flutter_lan_communication/HomeScreen.dart';

class LoginScreen extends StatelessWidget {
  var textC = TextEditingController();

  LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Column(
                children: [
                  Text(''),
                  Text(''),
                  Text(''),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextFormField(
                onFieldSubmitted: (val) {
                  _login(context);
                },
                decoration: InputDecoration(
                  hintText: 'Enter Name',
                  suffixIcon: IconButton(
                      onPressed: () {
                        _login(context);
                      },
                      icon: const Icon(Icons.login)),
                ),
                controller: textC,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _login(context) {
    if(textC.text.length>2) {
      Navigator.push(context,
        MaterialPageRoute(builder: (_) => HomeScreen(name: textC.text)));
    }
  }
}
