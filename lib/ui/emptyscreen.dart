import 'package:flutter/material.dart';


class EmptyApp extends StatefulWidget {

  final bool showBackarrow;

  EmptyApp(this.showBackarrow);
  @override
  _EmptyAppState createState() => _EmptyAppState();
}

class _EmptyAppState extends State<EmptyApp> {
  @override
  Widget build(BuildContext context) {
    const PrimaryColor = const Color(0xFFffffff);
    return Scaffold(
      appBar: AppBar(
        elevation: 0.5,
        centerTitle: true,
        title: const Text('Repeat Click', style: TextStyle(color: Colors.black)),
        backgroundColor: PrimaryColor,
        leading: widget.showBackarrow == true ? new Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context, false);
              },
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.arrow_back),
              ),
            )) : SizedBox(width: 1,),
      ),
      body: Center(
        child: Text(
          'Coming soon..',
          style: TextStyle(fontSize: 17, color: Colors.black),
        ),
      ),
    );
  }
}
