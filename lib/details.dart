import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stock_watch/main.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class DetailsPage extends StatefulWidget{
  const DetailsPage({Key? key, required this.title, required this.stockSymbol}) : super(key: key);

  final String title;
  final String stockSymbol;


   @override
   State<DetailsPage> createState() => _DetailsState(stockSymbol);
}

class _DetailsState extends State<DetailsPage>{

  String stockSymbol='';
  late Future<StockDetails> futureStockDetails;
  late Future<StockPrice> futureStockPrice;
  bool isSaved=false;
  bool canFetch= true;
  String stockName ='';


  _DetailsState(symbol){
    stockSymbol = symbol;
  }

  @override
  void initState(){
    super.initState();
    debugPrint('initState');
    futureStockDetails = fetchDetails();
    futureStockPrice = fetchPrice();
    ifSaved();
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      checkResponse();
    });
  }



  ifSaved() async{
    await fetchDetails();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    debugPrint('isSaved: +'+(prefs.containsKey('stocks') && prefs.getStringList('stocks')!.contains(stockSymbol+','+stockName)).toString());
    debugPrint('StockName: '+stockName);
    setState(() {
      isSaved = prefs.containsKey('stocks') && prefs.getStringList('stocks')!.contains(stockSymbol+','+stockName);
    });
  }

  addToSharedPref(symbol) async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if(prefs.containsKey('stocks')){
      List<String>? stocks = prefs.getStringList('stocks');
      stocks!.add(symbol);
      prefs.setStringList('stocks', stocks);
    }
    else{
      List<String> stocks = [];
      stocks.add(symbol);
      prefs.setStringList('stocks', stocks);
    }
  }

  deleteFromSharedPref(symbol) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    //prefs = await SharedPreferences.getInstance();
    List<String>? stocks = prefs.getStringList('stocks');
    stocks!.remove(symbol);
    prefs.setStringList('stocks', stocks);
  }

  checkResponse() async{
    String token = 'c9kfv22ad3i81ufrufb0';
    final response = await http.get(Uri.parse('https://finnhub.io/api/v1/stock/profile2?symbol='+stockSymbol+'&token='+token));
    debugPrint('Length of response: '+response.body.length.toString());
    debugPrint(response.body);
    if(response.statusCode ==200){
      setState(() {
        canFetch = response.body.length>2;
      });
    }
  }

  Future<StockDetails> fetchDetails() async{
    String token = 'c9kfv22ad3i81ufrufb0';
    final response = await http.get(Uri.parse('https://finnhub.io/api/v1/stock/profile2?symbol='+stockSymbol+'&token='+token));
    debugPrint('Status code: '+response.statusCode.toString());
    debugPrint(response.body);
    if(response.statusCode == 200) {
      StockDetails sd = StockDetails.fromJson(jsonDecode(response.body));
      setState(() {
        stockName = sd.name;
      });
      return sd;
    }
    else{
      throw Exception ('Failed to load details');
    }

  }

  Future<StockPrice> fetchPrice() async{
    String token = 'c9kfv22ad3i81ufrufb0';
    final response = await http.get(Uri.parse('https://finnhub.io/api/v1/quote?symbol='+stockSymbol+'&token='+token));

    if(response.statusCode == 200) {
      return StockPrice.fromJson(jsonDecode(response.body));
    }
    else{
      throw Exception ('Failed to load prices');
    }

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Details'),
        centerTitle: true,
         leading: IconButton(
           icon: const Icon(Icons.arrow_back),
           onPressed: () {
             int count =0;
             Navigator.push(context, MaterialPageRoute(builder: (context) => const MyHomePage(title: "Stock")));
           },
         ),
        actions: [
          IconButton(onPressed: (){
                  if(isSaved){
                    deleteFromSharedPref(stockSymbol+','+stockName);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(stockSymbol+' was removed from watchlist')));
                    setState(() {
                      isSaved = false;
                    });
                  }
                  else{
                    addToSharedPref(stockSymbol+','+stockName);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(stockSymbol+' was added to watchlist')));
                    setState(() {
                      isSaved = true;
                    });
                  }
          }, icon: isSaved?const Icon(Icons.star):const Icon(Icons.star_border_outlined)),
        ],
      ),
      body: canFetch?Column(
          children: <Widget>[FutureBuilder<StockDetails>(
            future: futureStockDetails,
            builder: (context,snapshot) {

              if(snapshot.hasData){
                return Row(
                  children: <Widget>[
                    const SizedBox(width: 5),
                    Text(stockSymbol,
                    textAlign: TextAlign.left,
                    style: const TextStyle(
                      fontSize: 20
                    ),),
                    const SizedBox(width: 40),
                    Text(snapshot.data!.name,
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.grey,
                    )),
                  ],
                );
              }
              else if(snapshot.hasError){
                return const Text('Failed to fetch stock data');

              }
              return const Center();
            }
          ),

            const SizedBox(height: 20),

            FutureBuilder<StockPrice>(
              future: futureStockPrice,
              builder : (context, snapshot) {
                if(snapshot.hasData){
                  return Column(
                  children: <Widget>[

                    //Current, delta
                    Row(

                      children: <Widget>[
                        const SizedBox(width: 5),
                    Text(snapshot.data!.current.toString(),
                      style: const TextStyle(
                        fontSize: 20,
                      ),

                    ),
                      const SizedBox(width: 40),
                      Text(snapshot.data!.delta>0?'+'+snapshot.data!.delta.toString():snapshot.data!.delta.toString(),
                        style: TextStyle(
                          fontSize: 20,
                          color: (snapshot.data!.delta)>0?Colors.green:Colors.red,
                        ),
                      )]),
                    const SizedBox(height: 20),

                    //Stats
                    Row(
                    children: const <Widget>[
                      SizedBox(width: 5),
                      Text('Stats',
                    style: TextStyle(
                      fontSize: 25,
                    )),
                    ]),
                    const SizedBox(height: 10),

                    //Open, high
                    Row(
                     children: <Widget>[
                       const SizedBox(width: 5),
                   const Text('Open',
                     style: TextStyle(
                       fontSize: 17,
                     ),
                    ),
                       const SizedBox(width: 30),
                       Text(snapshot.data!.open.toStringAsFixed(2),
                       style: const TextStyle(
                         fontSize: 17,
                         color: Colors.grey,
                       ),),
                       const SizedBox(width: 40),

                       const Text('High',
                       style: TextStyle(
                         fontSize: 17,
                       ),),
                       const SizedBox(width: 30),
                       Text(snapshot.data!.high.toStringAsFixed(2),
                       style: const TextStyle(
                         fontSize: 17,
                         color: Colors.grey,
                       ),),
                     ]),

                    //Low, prev
                    Row(
                        children: <Widget>[
                          const SizedBox(width: 5),
                          const Text(' Low ',
                            style: TextStyle(
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(width: 30),
                          Text(snapshot.data!.low.toStringAsFixed(2),
                            style: const TextStyle(
                              fontSize: 17,
                              color: Colors.grey,
                            ),),
                          const SizedBox(width: 40),

                          const Text('Prev',
                            style: TextStyle(
                              fontSize: 17,
                            ),),
                          const SizedBox(width: 30),
                          Text(snapshot.data!.previous.toStringAsFixed(2),
                            style: const TextStyle(
                              fontSize: 17,
                              color: Colors.grey,
                            ),),
                        ]),


                  ],
                  );
                }
                else if(snapshot.hasError){
                  return Text('${snapshot.error}');

                }
                return const Center();
          }

            ),

            const SizedBox(height: 20),
            
            FutureBuilder<StockDetails>(
              future: futureStockDetails,
                builder: (context, snapshot){
                  if(snapshot.hasData){
                    return Column(
                      children: <Widget>[
                        //About
                        Row(
                        children: const <Widget>[
                          SizedBox(width: 5),
                          Text('About',
                          style: TextStyle(fontSize: 25),
                        )]
                        ),

                        const SizedBox(height: 10),

                        //Start date
                        Row(

                        children: <Widget>[
                          const SizedBox(width: 5),
                          const Text('Start date   ',
                          style: TextStyle(
                            fontSize: 15,
                          ),),
                          const SizedBox(width: 40),
                          Text(snapshot.data!.startDate,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.grey,
                          ),)
                        ]
                        ),

                        //Industry
                        Row(

                            children: <Widget>[
                              const SizedBox(width: 5),
                              const Text('Industry      ',
                                style: TextStyle(
                                  fontSize: 15,
                                ),),
                              const SizedBox(width: 40),
                              Text(snapshot.data!.industry,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey,
                                ),)
                            ]
                        ),

                        //Website
                        Row(
                       children: <Widget> [
                         const SizedBox(width: 5),
                         const Text('Website      ',
                         style: TextStyle(
                           fontSize: 15,
                         ),),
                         const SizedBox(width: 40),
                         InkWell(
                        child: Text(snapshot.data!.website,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.blue,

                        ),),
                        onTap: ()=> launchUrl(Uri.parse(snapshot.data!.website)))]
                        ),


                      //Exchange
                        Row(

                            children: <Widget>[
                              const SizedBox(width: 5),
                              const Text('Exchange   ',
                                style: TextStyle(
                                  fontSize: 15,
                                ),),
                              const SizedBox(width: 40),
                              Text(snapshot.data!.exchange,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey,
                                ),)
                            ]
                        ),

                        //Market Cap
                        Row(

                            children: <Widget>[
                              const SizedBox(width: 5),
                              const Text('Market Cap',
                                style: TextStyle(
                                  fontSize: 15,
                                ),),
                              const SizedBox(width: 40),
                              Text(snapshot.data!.marketCap.toString(),
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey,
                                ),)
                            ]
                        ),
                      ],
                    );
                  }
                  else if(snapshot.hasError){
                    return const Text('Could not fetch stock data!');

                  }
                  return const Center(child: CircularProgressIndicator());
                })

          ]
      ):const Center(child:Text('Failed to fetch stock data',
        style: TextStyle(
          fontSize: 20,
        ),
      )),
    );
  }

}