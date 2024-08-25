import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_fullstack/model/users.dart';
import 'package:flutter_application_fullstack/model/config.dart';

class UserForm extends StatefulWidget {
  @override
  _UserFormState createState() => _UserFormState();
}

class _UserFormState extends State<UserForm> {
  final _formkey = GlobalKey<FormState>();
  //Users user = Users();
  late Users user;

  Future<void> updateData(user) async {
    var url = Uri.http(Configure.server, "users/${user.id}");
    var resp = await http.put(url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(user.toJson()));

    if (resp.statusCode == 200) {
      Navigator.pop(context, "refresh");
    } else {
      print('Failed to update user. Status code: ${resp.statusCode}');
    }
  }

  Future<void> addNewUser(Users user) async {
    var url = Uri.http(Configure.server, "users");
    try {
      var resp = await http.post(
        url,
        headers: <String, String>{
          'Content-type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(user.toJson()),
      );
      if (resp.statusCode == 201) {
        Navigator.pop(context, "refresh");
      } else {
        print('Failed to add user: ${resp.statusCode}');
      }
    } catch (e) {
      print('Error adding user: $e');
    }
  }

  Widget fnameInputField() {
    return TextFormField(
      initialValue: user.fullname,
      decoration:
          InputDecoration(labelText: "Fullname", icon: Icon(Icons.person)),
      validator: (value) {
        if (value!.isEmpty) {
          return "This field is required";
        }
        return null;
      },
      onSaved: (newValue) => user.fullname = newValue,
    );
  }

  Widget emailInputField() {
    return TextFormField(
      initialValue: user.email,
      decoration: const InputDecoration(
        labelText: "Email:",
        icon: Icon(Icons.email),
      ),
      validator: (value) {
        if (value!.isEmpty) {
          return "This field is required";
        }
        if (!EmailValidator.validate(value)) {
          return "It is not email format";
        }
        return null;
      },
      onSaved: (newValue) => user.email = newValue,
    );
  }

  // Password Input Field
  Widget passwordInputField() {
    return TextFormField(
      initialValue: user.password,
      obscureText: true,
      decoration: const InputDecoration(
        labelText: "Password:",
        icon: Icon(Icons.lock),
      ),
      validator: (value) {
        if (value!.isEmpty) {
          return "This field is required";
        }
        return null;
      },
      onSaved: (newValue) => user.password = newValue,
    );
  }

  // Gender Input Field
  Widget genderFormInput() {
    var initGen = "None";
    try {
      if (!user.gender!.isEmpty) {
        initGen = user.gender!;
      }
    } catch (e) {
      initGen = "None";
    }

    return DropdownButtonFormField<String>(
      value: initGen,
      decoration: const InputDecoration(
        labelText: "Gender:",
        icon: Icon(Icons.person),
      ),
      items: Configure.gender.map((String val) {
        return DropdownMenuItem<String>(
          value: val,
          child: Text(val),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          user.gender = value;
        });
      },
      onSaved: (newValue) => user.gender = newValue,
    );
  }

  // Submit Button
  Widget submitButton() {
    return ElevatedButton(
      onPressed: () {
        if (_formkey.currentState!.validate()) {
          _formkey.currentState!.save();
          print(user.toJson().toString());
          addNewUser(user);
        } else {
          updateData(user);
        }
      },
      child: const Text("Submit"),
    );
  }

  @override
  Widget build(BuildContext context) {
    try {
      user = ModalRoute.of(context)!.settings.arguments as Users;
      print(user.fullname);
    } catch (e) {
      user = Users();
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Form"),
      ),
      body: Container(
        margin: EdgeInsets.all(10),
        child: Form(
          key: _formkey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              fnameInputField(),
              emailInputField(),
              passwordInputField(),
              genderFormInput(),
              SizedBox(
                height: 10,
              ),
              submitButton(),
            ],
          ),
        ),
      ),
    );
  }
}

class UserInfo extends StatelessWidget {
  const UserInfo({super.key});

  @override
  Widget build(BuildContext context) {
    final user = ModalRoute.of(context)!.settings.arguments as Users;

    return Scaffold(
      appBar: AppBar(
        title: const Text("User Info"),
      ),
      body: Container(
        margin: const EdgeInsets.all(10),
        child: ListView(
          children: [
            ListTile(
              title: const Text("Full Name"),
              subtitle: Text(user.fullname ?? ""),
            ),
            ListTile(
              title: const Text("Email"),
              subtitle: Text(user.email ?? ""),
            ),
            ListTile(
              title: const Text("Gender"),
              subtitle: Text("${user.gender}"),
            ),
          ],
        ),
      ),
    );
  }
}

class Home extends StatefulWidget {
  static const routeName = "/";
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<Users> _userList = [];
  Widget mainBody = Container();

  @override
  void initState() {
    super.initState();
    Users user = Configure.login;
    if (user.id != null) {
      getUser();
    }
  }

  Future<void> getUser() async {
    var url = Uri.http(Configure.server, "users");
    var resp = await http.get(url);
    setState(() {
      _userList = usersFromJson(resp.body);
      mainBody = showUsers();
    });
  }

  Future<void> removeUsers(user) async {
    var url = Uri.http(Configure.server, "users/${user.id}");
    var resp = await http.delete(url);
    print(resp.body);
    return;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Home",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
      ),
      drawer: const SideMenu(),
      body: mainBody,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          String result = await Navigator.push(
              context, MaterialPageRoute(builder: (context) => UserForm()));
          if (result == "refresh") {
            getUser();
          }
        },
        child: const Icon(Icons.person_add_alt_1),
      ),
    );
  }

  Widget showUsers() {
    return ListView.builder(
      itemCount: _userList.length,
      itemBuilder: (context, index) {
        Users user = _userList[index];
        return Dismissible(
          key: UniqueKey(),
          direction: DismissDirection.endToStart,
          child: Card(
            child: ListTile(
              title: Text(user.fullname ?? ""),
              subtitle: Text(user.email ?? ""),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const UserInfo(),
                        settings: RouteSettings(arguments: user)));
              },
              trailing: IconButton(
                onPressed: () async {
                  String result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => UserForm(),
                          settings: RouteSettings(arguments: user)));
                  if (result == "refresh") {
                    getUser();
                  }
                },
                icon: const Icon(Icons.edit),
              ),
            ),
          ),
          onDismissed: (direction) {
            removeUsers(user);
          },
          background: Container(
            color: Colors.red,
            margin: const EdgeInsets.symmetric(horizontal: 15),
            alignment: Alignment.centerRight,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
        );
      },
    );
  }
}

class SideMenu extends StatelessWidget {
  const SideMenu({super.key});

  @override
  Widget build(BuildContext context) {
    String accountName = "N/A";
    String accountEmail = "N/A";
    String accountUrl =
        "https://scontent.furt3-1.fna.fbcdn.net/v/t39.30808-6/241201068_1260604774458683_4673830339750907777_n.jpg?_nc_cat=107&ccb=1-7&_nc_sid=6ee11a&_nc_ohc=gMktqi0qPsYQ7kNvgGA5pFz&_nc_ht=scontent.furt3-1.fna&oh=00_AYDHWsCTQRsGUuh0o38O-iZWaGjulLbhLReI1WLu_v9uXg&oe=66CFD564";

    Users user = Configure.login;
    if (user.id != null) {
      accountName = user.fullname ?? "N/A";
      accountEmail = user.email ?? "N/A";
    }
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(accountName),
            accountEmail: Text(accountEmail),
            currentAccountPicture:
                CircleAvatar(backgroundImage: NetworkImage(accountUrl)),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text("Home"),
            onTap: () {
              Navigator.pushNamed(context, Home.routeName);
            },
          ),
          ListTile(
            leading: const Icon(Icons.login),
            title: const Text("Login"),
            onTap: () {
              Navigator.pushNamed(context, Login.routeName);
            },
          ),
        ],
      ),
    );
  }
}

class Login extends StatefulWidget {
  static const routeName = "/login";

  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formkey = GlobalKey<FormState>();
  Users user = Users();

  Future<void> login(Users user) async {
    var params = {"email": user.email, "password": user.password};

    var url = Uri.http(Configure.server, "users", params);
    var resp = await http.get(url);
    print(resp.body);
    List<Users> loginResult = usersFromJson(resp.body);
    print(loginResult.length);
    if (loginResult.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("username or password invalid")));
    } else {
      Configure.login = loginResult[0];
      Navigator.pushNamed(context, Home.routeName);
    }
    return;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        margin: const EdgeInsets.all(10.0),
        child: Form(
          key: _formkey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              textHeader(),
              emailInputField(),
              passwordInputField(),
              const SizedBox(
                height: 10.0,
              ),
              Row(
                children: [
                  submitButton(context),
                  const SizedBox(
                    width: 10.0,
                  ),
                  backButton(),
                  const SizedBox(width: 10.0),
                  registerLink()
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget submitButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        if (_formkey.currentState!.validate()) {
          _formkey.currentState!.save();
          print(user.toJson().toString());
          login(user);
        }
      },
      child: const Text("Login"),
    );
  }

  Widget emailInputField() {
    return TextFormField(
      initialValue: "a@test.com",
      decoration:
          const InputDecoration(labelText: "Email:", icon: Icon(Icons.email)),
      validator: (value) {
        if (value!.isEmpty) {
          return "This field is required";
        }
        if (!EmailValidator.validate(value)) {
          return "It is not email format";
        }
        return null;
      },
      onSaved: (newValue) => user.email = newValue,
    );
  }

  Widget passwordInputField() {
    return TextFormField(
      initialValue: "qwerty",
      obscureText: true,
      decoration:
          const InputDecoration(labelText: "Password:", icon: Icon(Icons.lock)),
      validator: (value) {
        if (value!.isEmpty) {
          return "This field is required";
        }
        return null;
      },
      onSaved: (newValue) => user.password = newValue,
    );
  }

  Widget backButton() {
    return ElevatedButton(onPressed: () {}, child: const Text("Back"));
  }

  Widget registerLink() {
    return InkWell(
      child: const Text("Sign Up"),
      onTap: () {},
    );
  }

  Widget textHeader() {
    return const Center(
      child: Text(
        "Login",
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }
}
