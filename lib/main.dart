import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      // ignore: unnecessary_const
      home: HomePage(),
    );
  }
}

// ignore: must_be_immutable
class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  // ignore: prefer_final_fields

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _toDoController = TextEditingController();

  List _toDoList = [];

  late Map<String, dynamic> _lastRemoved;
  late int _lastRemovedPos;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _readData().then((data) {
      setState(() {
        _toDoList = json.decode(data!);
      });
    });
  }

  void _addToDo() {
    setState(() {
      Map<String, dynamic> newToDo = Map();
      newToDo["title"] = _toDoController.text;
      _toDoController.text = "";
      newToDo["ok"] = false;
      _toDoList.add(newToDo);
      _saveData();
    });
  }

  Future<Null> _refresh() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _toDoList.sort((a, b) {
        if (a["ok"] && !b["ok"]) {
          return 1;
        } else if (!a["ok"] && b["ok"]) {
          return -1;
        } else {
          return 0;
        }
      });
      _saveData();
    });
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lista de Tarefas"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
            child: Row(
              children: [
                // ignore: prefer_const_constructors
                Expanded(
                  // ignore: prefer_const_constructors
                  child: TextField(
                    controller: _toDoController,
                    // ignore: prefer_const_constructors
                    decoration: InputDecoration(
                      labelText: "Nova Tarefa",
                      labelStyle: const TextStyle(color: Colors.blueAccent),
                    ),
                  ),
                ),
                ElevatedButton(onPressed: _addToDo, child: const Text("Add")),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                  padding: const EdgeInsets.only(top: 10.0),
                  itemCount: _toDoList.length,
                  itemBuilder: buildItem),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildItem(BuildContext context, int index) {
    return Dismissible(
      key: Key(DateTime.now().microsecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: const Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(_toDoList[index]["title"]),
        onChanged: (c) {
          setState(() {
            _toDoList[index]["ok"] = c;
            _saveData();
          });
        },
        value: _toDoList[index]["ok"],
        secondary: CircleAvatar(
          child: Icon(_toDoList[index]["ok"] ? Icons.check : Icons.error),
        ),
      ),
      onDismissed: (direction) {
        setState(() {
          _lastRemoved = Map.from(_toDoList[index]);
          _lastRemovedPos = index;
          _toDoList.removeAt(index);
          _saveData();
          final snack = SnackBar(
            content: Text("Tarefa \"${_lastRemoved["title"]}\" removida!"),
            action: SnackBarAction(
              label: "Desfazer",
              onPressed: () {
                setState(() {
                  _toDoList.insert(_lastRemovedPos, _lastRemoved);
                  _saveData();
                });
              },
            ),
            duration: Duration(seconds: 2),
          );
          ScaffoldMessenger.of(context).showSnackBar(snack);
        });
      },
    );
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(_toDoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String?> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }
}
