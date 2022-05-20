import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:stock_watch/details.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stock Watch',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        brightness: Brightness.light,
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.purple,
      ),

      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.purple,
        primarySwatch: Colors.purple,
        appBarTheme: const AppBarTheme(
          color: Colors.purple,
        )

      ),

      themeMode: ThemeMode.dark,

      home: const MyHomePage(title: 'Stock'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<String> stockList =[];
  String today='';
  late Future<List<Stock>> futureStock;
  List<String> savedStocks=[];


  @override
  void initState(){
    super.initState();
    debugPrint('Inside init state');
    DateTime now = DateTime.now();
    today = DateFormat.yMMMMd('en_US').format(now).split(",")[0];

  }



  addToSharedPref(symbol) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    //prefs = await SharedPreferences.getInstance();
    prefs.setStringList('stocks', symbol);
  }

  getSaved() async{
    //debugPrint('Inside getSaved');
    SharedPreferences prefs = await SharedPreferences.getInstance();
   // debugPrint('containsKey :'+prefs.containsKey('stocks').toString());
    setState(() {
      savedStocks = prefs.getStringList('stocks')!;
    });
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      getSaved();
    });

    debugPrint('Arraysize: '+savedStocks.length.toString());
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
        centerTitle: true,
        actions: [
          IconButton(
            icon : const Icon(Icons.search),
              onPressed: (){
              showSearch(context: context, delegate: MySearchDelegate(stockList));
              }, )
        ],
      ),
      body:  Column(
        children:<Widget> [Align(
          alignment: Alignment.topRight,
          child: Row(
              children: <Widget>[
              const SizedBox(width: 175),Text(
            'STOCK WATCH\n'+today,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 25,
                fontWeight: FontWeight.bold)

          )]),
        ),
          const SizedBox(height: 30),

          Column(
            children:  <Widget>[
              Align(
                alignment: Alignment.centerLeft,

              child :Row(children:const  <Widget>[SizedBox(width: 10),Text('Favorites',
                style: TextStyle(fontSize: 20),)])),
              const SizedBox(height: 20),
             const  Divider(
                color: Colors.white,
                thickness: 2,
              ),



            ],
          ),

       if(savedStocks.isNotEmpty)  Expanded(
            child: SizedBox(
              height: 200.0,
          child: ListView.separated(
            separatorBuilder: (context,index) => const Divider(

              color: Colors.white,
              thickness: 2,
            ),

            itemCount: savedStocks.length,

              itemBuilder: (context,index){


                final item = savedStocks[index];


                return Dismissible(key: Key(item),

                confirmDismiss: (direction) async{
                  Widget deleteButton  = TextButton(
                    child: const  Text('Delete'),
                    onPressed: (){
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(savedStocks[index].split(',')[0]+' was removed from watchlist')));
                      setState(() {
                        savedStocks.removeAt(index);
                      });
                      addToSharedPref(savedStocks);
                      Navigator.pop(context);


                    },
                  );

                  Widget cancelButton = TextButton(onPressed: (){
                    Navigator.pop(context);

                  }, child: const Text('Cancel'));

                  AlertDialog alert  = AlertDialog(
                    title: const Text('Delete Confirmation'),
                    content: const Text('Are you sure you want to delete this item?'),
                    actions: [deleteButton,cancelButton],
                  );

                 return showDialog(context: context, builder: (context){
                    return alert;
                  },
                  );


                },

                  background: Container(
                    child: const Icon(Icons.delete
                    ),
                      alignment: AlignmentDirectional.centerEnd,
                      color: Colors.red),

                child: ListTile(
                  title:Align(
                    alignment: Alignment.centerLeft,
                    child:  Column(

                      children: <Widget>[

                        Row(
                           children:<Widget> [Text(item.split(',')[0])]),
                      Row(
                     children: <Widget> [
                       Text(item.split(',')[1])
                     ],
                      )])
                  ),
                  onTap: (){
                    debugPrint(item.split(',')[0]);
                    Navigator.push(context, MaterialPageRoute(builder: (context) =>
                        DetailsPage(title: "Details",
                            stockSymbol: item.split(',')[0])));
                  },
                ),
                );
              })
            )
          ),

          if(savedStocks.isEmpty)Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: const <Widget>[

              Text('Empty',
                style: TextStyle(fontSize: 20,
                fontWeight: FontWeight.bold),)
            ],
          )


        ]
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class MySearchDelegate extends SearchDelegate{

  List<String> searchResults = [];
  MySearchDelegate (List<String> results){
  searchResults = results;
}




  Future<List<Stock>> fetchStocks(query) async{
    String token = 'c9kfv22ad3i81ufrufb0';
    List<Stock> stocks = [];
    debugPrint('https://finnhub.io/api/v1/search?q='+query+'&token='+token);
    final response = await http.get(Uri.parse('https://finnhub.io/api/v1/search?q='+query+'&token='+token));

    if(response.statusCode == 200) {
      final data = jsonDecode(response.body);
      for(Map<String,dynamic> i in data['result']){
        stocks.add(Stock.fromJson(i));
      }
      return stocks;
    }
    else{
      throw Exception ('Failed to load album');
    }

  }


  @override
  List<Widget>? buildActions(BuildContext context) => [
    IconButton(
        onPressed: (){
          if(query.isEmpty){
            close(context,null);  //close search bar
          }
          else{
            query = '';
          }
        },
        icon: const Icon(Icons.clear)
    )
   // throw UnimplementedError();
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    // TODO: implement buildLeading
    icon: const Icon(Icons.arrow_back),
    onPressed : ()  => close(context,null), //close search bar
   // throw UnimplementedError();
  );



  @override
  Widget buildSuggestions(BuildContext context) {
    // List<String> suggestions = searchResults.where((searchResult) {
    //   final result = searchResult.toLowerCase();
    //   final input = query.toLowerCase();
    //
    //   return result.contains(input);
    // }).toList();
    debugPrint(query);

    if (query.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const <Widget>[
          Center(
            child: Text(
              "No suggestions found!",
              style: TextStyle(
                fontSize: 25,

              ),

            ),
          )
        ],
      );
    }

    else {

      return FutureBuilder<List<Stock>>(
        future: fetchStocks(query),
        builder: (context, snapshot){
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          else{
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final suggestion = snapshot.data![index];

                return ListTile(
                  title: Text(suggestion.displaySymbol+' | '+suggestion.description),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) =>
                        DetailsPage(title: "Details",
                            stockSymbol: suggestion.displaySymbol)));
                    query = suggestion.displaySymbol+' | '+suggestion.description;

                    showResults(context);

                  },
                );
              },
            );
          }
        }
      );
    }
  }



  @override
  Widget buildResults(BuildContext context) {
    return const Center();
  }

}


class Stock{
  final String displaySymbol;
  final String description;

  const Stock({
    required this.displaySymbol,
    required this.description,
});

  factory Stock.fromJson(Map<String, dynamic> json){
    return Stock(
      displaySymbol: json['symbol'],
      description: json['description'],
    );
  }
}

class StockDetails{
  final String name;
  final String startDate;
  final String industry;
  final String website;
  final String exchange;
  final num marketCap;

  const StockDetails({
    required this.name,
    required this.startDate,
    required this.industry,
    required this.website,
    required this.exchange,
    required this.marketCap,
});

  factory StockDetails.fromJson(Map<String, dynamic> json){
    return StockDetails(
        name: json['name'],
        startDate: json['ipo'],
        industry: json['finnhubIndustry'],
        website: json['weburl'],
        exchange: json['exchange'],
        marketCap: json['marketCapitalization']
    );
  }

}

class StockPrice{
  final num current;
  final num delta;
  final num high;
  final num low;
  final num open;
  final num previous;

  const StockPrice({
    required this.current,
    required this.delta,
    required this.high,
    required this.low,
    required this.open,
    required this.previous,
});


  factory StockPrice.fromJson(Map<String, dynamic> json){
    return StockPrice(current: json['c'],
        delta: json['d'],
        high: json['h'],
        low: json['l'],
        open: json['o'],
        previous: json['pc']);
  }
}


