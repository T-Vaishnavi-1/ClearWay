import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseUploadScreen extends StatelessWidget
{
  FirebaseUploadScreen({super.key});
  final List<Map<String,dynamic>> indiaStatesData=[

  ];

  void writeStates() async{
    final db=FirebaseFirestore.instance;
    for(var state in indiaStatesData)
    {
      try{
      await db.collection('migrant_data').doc('India').collection('States').
      doc(state['name']).set(state);
      print('${state['name']} written to database');
      }catch(e)
      {
        print('Error uploading ${state['name']}:$e}');
      }
    }
  }
  

@override

Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload India States")),
      body: Center(
        child: ElevatedButton(
          onPressed: writeStates,
          child: const Text("Upload States Data"),
        ),
      ),
    );
  }
}
