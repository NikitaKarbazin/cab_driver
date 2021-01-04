
import 'package:cab_driver/brand_colors.dart';
import 'package:cab_driver/screens/loginpage.dart';
import 'package:cab_driver/screens/vehicleinfo.dart';
import 'package:cab_driver/widgets/ProgressDialog.dart';
import 'package:cab_driver/widgets/TaxiButton.dart';
import 'package:connectivity/connectivity.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../globalvariables.dart';

class RegistrationPage  extends StatefulWidget {

  static const String id = 'register';

  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();

  void showSnackBar(String title){
    final snackBar = SnackBar(
      content: Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 15),),
    );
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;

  var fullNameController = TextEditingController();

  var phoneController = TextEditingController();

  var emailController = TextEditingController();

  var passwordController = TextEditingController();

  void registerUser() async {

    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) => ProgressDialog(status: 'Регистрация....',)

    );

    final User user = (await _auth.createUserWithEmailAndPassword(
      email: emailController.text,
      password: passwordController.text,
    ).catchError((ex){

      //check error
      Navigator.pop(context);
      PlatformException thisEx = ex;
      showSnackBar(thisEx.message);}
    )).user ;

    Navigator.pop(context);


    if (user != null) {
      DatabaseReference newUserRef = FirebaseDatabase.instance.reference().child('drivers/${user.uid}');

      //Prepare data to saved in users*
      Map userMap = {
        'fullname': fullNameController.text,
        'email': emailController.text,
        'phone':phoneController.text,
      };
      newUserRef.set(userMap);

      currentFirebaseUser = user;

      Navigator.pushNamed(context, VehicleInfoPage.id);

    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children:<Widget> [
                SizedBox(height: 70,),
                Image(
                  alignment: Alignment.center,
                  height: 100.0,
                  width: 100.0,
                  image: AssetImage('images/logo.png'),
                ),
                SizedBox(height: 40,),

                Text('Создадите аккаунт водителя',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 25, fontFamily: 'Brand-Bold'),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children:<Widget> [

                      //Fullname
                      TextField(
                        controller: fullNameController,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                            labelText: 'Фамилие Имя',
                            labelStyle: TextStyle(
                              fontSize: 14.0,
                            ),
                            hintStyle: TextStyle(
                                color: Colors.grey,
                                fontSize: 10.0
                            )
                        ),
                        style: TextStyle(fontSize: 14),
                      ),

                      SizedBox(height: 10,),
                      //Email
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                            labelText: 'Email',
                            labelStyle: TextStyle(
                              fontSize: 14.0,
                            ),
                            hintStyle: TextStyle(
                                color: Colors.grey,
                                fontSize: 10.0
                            )
                        ),
                        style: TextStyle(fontSize: 14),
                      ),

                      SizedBox(height: 10,),
                      //Phone
                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                            labelText: 'Номер телефона',
                            labelStyle: TextStyle(
                              fontSize: 14.0,
                            ),
                            hintStyle: TextStyle(
                                color: Colors.grey,
                                fontSize: 10.0
                            )
                        ),
                        style: TextStyle(fontSize: 14),
                      ),

                      SizedBox(height: 10,),
                      //Password
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                            labelText: 'Пароль',
                            labelStyle: TextStyle(
                              fontSize: 14.0,
                            ),
                            hintStyle: TextStyle(
                                color: Colors.grey,
                                fontSize: 10.0
                            )
                        ),
                        style: TextStyle(fontSize: 14),
                      ),

                      SizedBox(height: 40,),

                      TaxiButton(
                        title: 'Зарегестрироваться',
                        color: BrandColors.colorBlue,
                        onPressed:() async {

                          //check network connect

                          var connectivityResult = await Connectivity().checkConnectivity();
                          if(connectivityResult != ConnectivityResult.mobile && connectivityResult != ConnectivityResult.wifi ){
                            showSnackBar('Нет интернет соеденения');
                            return;
                          }

                          if(fullNameController.text.length < 3){
                            showSnackBar('Пожалуйста, введите корректные данные');
                            return;
                          }

                          if(phoneController.text.length < 10){
                            showSnackBar('Пожалуйста, введите корректные данные');
                            return;
                          }

                          if(!emailController.text.contains('@')){
                            showSnackBar('Пожалуйста, введите корректные данные');
                            return;
                          }

                          if(passwordController.text.length < 8){
                            showSnackBar('Пароль должен быть минимум 8 символов');
                            return;
                          }

                          registerUser();

                        },

                      )
                    ],
                  ),
                ),


                FlatButton(
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(context, LoginPage.id, (route) => false);
                    },
                    child: Text('Уже есть аккаунт ВОДИТЕЛЯ? Войдите')
                ),


              ],
            ),
          ),
        ),
      ),
    );

  }
}
