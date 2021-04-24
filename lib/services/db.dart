import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';



class Collection<T> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String path;
  CollectionReference ref;

  Collection({this.path}) {
    ref = _db.collection(path);
  }

  Future<List<T>> getData() async {
    var snapshots = await ref.getDocuments();
    return snapshots.documents.map((doc) => Global.models[T](doc.data) as T).toList();
  }

  Stream<List<T>> streamData() {
    return ref.snapshots().map((list) => list.documents.map((doc) => Global.models[T](doc.data) as T));
  }
}