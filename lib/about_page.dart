import 'package:flutter/material.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({Key? key}) : super(key: key);

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  int itemCount = 20;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Color(0xFFCFFF60),
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Image.asset('images/AS1_3633.jpg')
              CircleAvatar(
                  radius: 70, backgroundImage: AssetImage('images/AS1_3633.jpg')),
              Text(
                'Asi Ben-Shach',
                style: TextStyle(
                    fontFamily: 'Pacifico',
                    color: Colors.black,
                    fontSize: 30,
                    fontWeight: FontWeight.bold),
              ),
              Text(
                'Developer',
                style: TextStyle(
                    fontFamily: 'SourceSansPro',
                    letterSpacing: 2.5,
                    color: Colors.black54,
                    fontSize: 20,
                    fontWeight: FontWeight.bold
                ),
              ),
              SizedBox(
                height: 20,
                width: 150,
                child: Divider(
                  color: Colors.black45,
                ),
              ),
              Card(
                shape: BeveledRectangleBorder(
                  borderRadius: BorderRadius.circular(7.0),
                ),
                margin: EdgeInsets.symmetric(vertical: 10,horizontal: 25),
                child: ListTile(
                  leading: Icon(
                    Icons.phone,
                    color: Colors.black45,
                  ),
                  title: Text(
                    '+972 (54) 5666717',
                    style: TextStyle(
                      fontFamily: 'SourceSansPro',
                      color: Colors.black45,
                      fontSize: 20,
                    ),
                  ),
                ),

              ),
              Card(
                shape: BeveledRectangleBorder(
                  borderRadius: BorderRadius.circular(7.0),
                ),
                margin: EdgeInsets.symmetric(vertical: 2,horizontal: 25),
                child: ListTile(
                  leading: Icon(
                    Icons.email,
                    color: Colors.black45,
                  ),
                  title: Text(
                    'asi.benshach@gmail.com',
                    style: TextStyle(
                      fontFamily: 'SourceSansPro',
                      color: Colors.black45,
                      fontSize: 20,
                    ),
                  ),
                ),

              ),
            ],
          ),
        ),
      ),
    );
  }
}
