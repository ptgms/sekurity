import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sekurity/main.dart';
import 'package:sekurity/tools/keymanagement.dart';
import 'package:sekurity/tools/platformtools.dart';

class AuthenticationFailed extends StatefulWidget {
  const AuthenticationFailed({super.key});

  @override
  State<AuthenticationFailed> createState() => _AuthenticationFailedState();
}

class _AuthenticationFailedState extends State<AuthenticationFailed> {
  var emergencyCorrect = false;
  @override
  Widget build(BuildContext context) {
    TextEditingController textfield = TextEditingController();
    const storage = FlutterSecureStorage();
    return Scaffold(body: emergencyCorrect? Center(
      child: TextButton(onPressed: () {
            exitApp();
          }, child: Text(context.loc.use_emergency_password_success))) : Center(
      child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    context.loc.use_emergency_password,
                    style: const TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    context.loc.use_emergency_password_description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16.0,
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  TextField(
                    controller: textfield,
                    obscureText: true,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: context.loc.settings_emergency_password,
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  Row(mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                    TextButton(
                    onPressed: () async {
                      if (textfield.text.isNotEmpty) {
                        if (await KeyManagement().verifyRestorePassword(textfield.text)) {
                          authentication = 0;
                          await storage.write(key: 'authentication',value: 0.toString());
                          await storage.write(key: 'attemptsLeft', value: "3");
                          
                          setState(() {
                            emergencyCorrect = true;
                          });

                        } else {
                          var attemptsLeft = int.parse((await storage.read(key: "attemptsLeft")??"3"));
                          attemptsLeft--;
                          if (attemptsLeft < 0) {
                            // resetting app
                            await storage.deleteAll();
                            exitApp();
                          }
                          await storage.write(key: "attemptsLeft", value: attemptsLeft.toString());
                          if (context.mounted) {
                            showDialog(context: context, builder: (context) {
                            return AlertDialog(
                              title: Text(context.loc.use_emergency_password_error),
                              content: Text(context.loc.use_emergency_password_error_description(attemptsLeft+1)),
                              actions: [
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: Text(context.loc.ok),
                                )
                              ],
                            );
                          });
                          }
                        }
                      }
                    },
                    child: Text(context.loc.ok),
                  ),
                  TextButton(
                    onPressed: () {
                      exitApp();
                    },
                    child: Text(context.loc.exit),
                  ),
                  ],)
                ],
              ),
            ),
    ));
  }
}