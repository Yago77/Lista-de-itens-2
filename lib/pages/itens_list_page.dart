import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class ListPage extends StatefulWidget {
  const ListPage({Key? key}) : super(key: key);

  @override
  State<ListPage> createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  List itensList = [];
  final itensController = TextEditingController();
  late Map<String, dynamic> lastRemoved;
  late int lastRemovedPos;
  String? errorText;

  @override
  void initState() {
    super.initState();
    readData().then((data) {
      setState(() {
        itensList = json.decode(data);
      });
    });
  }

  void addIten() {
    setState(() {
      Map<String, dynamic> newIten = Map();
      newIten["title"] = itensController.text;
      newIten["ok"] = false;
      itensList.add(newIten);
      itensController.clear();
      saveData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Lista de Itens"),
          backgroundColor: Colors.blueAccent,
          centerTitle: true,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(17, 1, 7, 1),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      textInputAction: TextInputAction.done,
                      textCapitalization: TextCapitalization.sentences,
                      controller: itensController,
                      decoration: InputDecoration(
                        errorText: errorText,
                        labelText: "Novo Item",
                        labelStyle: TextStyle(color: Colors.blueAccent),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      String text = itensController.text;
                      if (text.isEmpty) {
                        setState(() {
                          errorText = "Você precisa adicionar um item!";
                        });
                        return;
                      } else {
                        setState(() {
                          addIten();
                          errorText = null;
                        });
                      }
                      itensController.clear();
                      saveData();
                    },
                    style: ElevatedButton.styleFrom(
                      primary: Colors.blueAccent,
                    ),
                    child: const Text(
                      "Enviar",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: refresh,
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 10),
                  itemCount: itensList.length,
                  itemBuilder: buildItem,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                        "Você possui ${itensList.length} item(s) no carrinho"),
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(primary: Colors.blueAccent),
                    onPressed: showDeletedItensConfirmationDialog,
                    child: const Text("Remover tudo"),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget buildItem(context, index) {
    return Dismissible(
      background: Container(
        color: Colors.red,
        child: const Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
            child: Icon(
              Icons.delete,
              color: Colors.white,
              size: 35,
            ),
          ),
        ),
      ),
      direction: DismissDirection.endToStart,
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      child: CheckboxListTile(
        title: Text(
          itensList[index]["title"],
          style: TextStyle(
              decoration: itensList[index]["ok"]
                  ? TextDecoration.lineThrough
                  : TextDecoration.none),
        ),
        value: itensList[index]["ok"],
        secondary: CircleAvatar(
          child: Icon(itensList[index]["ok"] ? Icons.check : Icons.error),
        ),
        onChanged: (c) {
          setState(() {
            itensList[index]["ok"] = c;
            saveData();
          });
        },
      ),
      onDismissed: (direction) {
        setState(
          () {
            lastRemoved = Map.from(itensList[index]);
            lastRemovedPos = index;
            itensList.removeAt(index);
            saveData();

            final snack = SnackBar(
              content: Text("Item ${lastRemoved["title"]} removido"),
              action: SnackBarAction(
                label: "Desfazer",
                onPressed: () {
                  setState(() {
                    itensList.insert(lastRemovedPos, lastRemoved);
                    saveData();
                  });
                },
              ),
              duration: const Duration(seconds: 5),
            );
            ScaffoldMessenger.of(context).removeCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(snack);
          },
        );
      },
    );
  }

  Future<File> getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> saveData() async {
    String data = json.encode(itensList);
    final file = await getFile();
    return file.writeAsString(data);
  }

  Future<String> readData() async {
    try {
      final file = await getFile();
      return file.readAsString();
    } catch (e) {
      return "Erro";
    }
  }

  void deleteAll() {
    setState(() {
      itensList.clear();
      saveData();
    });
  }

  void showDeletedItensConfirmationDialog() {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text("Limpar tudo?"),
              content: const Text(
                  "Você tem certeza que deseja apagar todos os itens?"),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(primary: Colors.blueAccent),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    "Cancelar",
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    primary: Colors.red,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    deleteAll();
                  },
                  child: const Text("Limpar tudo"),
                )
              ],
            ));
  }

  Future refresh() async {
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      itensList.sort((a, b) {
        if (a["ok"] && !b["ok"])
          return 1;
        else if (!a["ok"] && b["ok"])
          return -1;
        else
          return 0;
      });

      saveData();
    });
  }
}
